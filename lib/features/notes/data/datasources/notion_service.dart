import 'dart:convert';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:tikgood/features/notes/data/models/note.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';
import '../../../../core/database/storage_service.dart';

// ── Separator shared with notes_sheet.dart ────────────────────────────────────
// \x1F (ASCII Unit Separator) encodes 'image_text' content as 'imagePath\x1Ftext'
const _kSep = '\x1F';

(String imagePath, String text) _decodeImageText(String content) {
  final idx = content.indexOf(_kSep);
  if (idx == -1) return (content, '');
  return (content.substring(0, idx), content.substring(idx + 1));
}

class NotionService {
  final StorageService _storage;
  NotionService(this._storage);

  bool get isConfigured {
    final key = _storage.getNotionApiKey();
    final pageId = _storage.getNotionParentPageId();
    return key != null && key.isNotEmpty && pageId != null && pageId.isNotEmpty;
  }

  Map<String, String> _headers(String apiKey) => {
        'Authorization': 'Bearer $apiKey',
        'Notion-Version': '2022-06-28',
        'Content-Type': 'application/json',
      };

  // ── Fetch pages for setup picker ──────────────────────────────────────────

  Future<List<Map<String, String>>> fetchPages(String apiKey) async {
    final res = await http.post(
      Uri.parse('https://api.notion.com/v1/search'),
      headers: _headers(apiKey),
      body: jsonEncode({
        'filter': {'value': 'page', 'property': 'object'},
        'page_size': 50,
      }),
    );
    if (res.statusCode == 200) {
      final results = (jsonDecode(res.body)['results'] as List?) ?? [];
      return results.map<Map<String, String>>((p) {
        final props = p['properties'] as Map? ?? {};
        final titleArr = (props['title']?['title'] as List?) ?? [];
        final title = titleArr.isNotEmpty
            ? titleArr[0]['plain_text'] ?? 'Untitled'
            : 'Untitled';
        return {'id': p['id'] as String, 'title': title as String};
      }).toList();
    }
    throw Exception(jsonDecode(res.body)['message']);
  }

  // ── Get or create a child page ────────────────────────────────────────────

  Future<String> _getOrCreateChildPage({
    required String apiKey,
    required String parentPageId,
    required String title,
    String emoji = '📄',
    String? cachedId,
  }) async {
    if (cachedId != null && cachedId.isNotEmpty) {
      debugPrint('NotionService: cache hit for "$title" = $cachedId');
      return cachedId;
    }

    final res = await http.post(
      Uri.parse('https://api.notion.com/v1/search'),
      headers: _headers(apiKey),
      body: jsonEncode({'query': title}),
    );

    if (res.statusCode == 200) {
      final results = (jsonDecode(res.body)['results'] as List?) ?? [];
      for (final r in results) {
        if (r['object'] != 'page') continue;
        final parent = r['parent'] as Map? ?? {};
        if (parent['page_id'] != parentPageId) continue;
        final props = r['properties'] as Map? ?? {};
        final titleArr = (props['title']?['title'] as List?) ?? [];
        final pageTitle =
            titleArr.isNotEmpty ? titleArr[0]['plain_text'] ?? '' : '';
        if (pageTitle == title) {
          debugPrint('NotionService: reusing page "$title" = ${r['id']}');
          return r['id'] as String;
        }
      }
    }

    final create = await http.post(
      Uri.parse('https://api.notion.com/v1/pages'),
      headers: _headers(apiKey),
      body: jsonEncode({
        'parent': {'page_id': parentPageId},
        'icon': {'type': 'emoji', 'emoji': emoji},
        'properties': {
          'title': {
            'title': [
              {
                'text': {'content': title}
              }
            ]
          }
        },
      }),
    );

    if (create.statusCode == 200 || create.statusCode == 201) {
      final id = jsonDecode(create.body)['id'] as String;
      debugPrint('NotionService: created page "$title" = $id');
      return id;
    }
    throw Exception(
        'Failed to create page "$title": ${jsonDecode(create.body)['message']}');
  }

  // ── Append blocks to a page ───────────────────────────────────────────────

  Future<bool> _appendBlocks({
    required String apiKey,
    required String pageId,
    required List<Map<String, dynamic>> blocks,
  }) async {
    final res = await http.patch(
      Uri.parse('https://api.notion.com/v1/blocks/$pageId/children'),
      headers: _headers(apiKey),
      body: jsonEncode({'children': blocks}),
    );
    if (res.statusCode == 200) return true;
    final err = jsonDecode(res.body);
    debugPrint('appendBlocks failed [${res.statusCode}]: ${err['message']}');
    return false;
  }

  // ── Build Notion blocks for one note ──────────────────────────────────────
  //
  // 'image_text' content is encoded as 'imagePath\x1Ftext'.
  // By the time this is called, imagePath has already been resolved to an
  // HTTP URL by the sync loop below.

  List<Map<String, dynamic>> _buildNoteBlocks(
      String type, int timestamp, String content) {
    final ts = _fmt(timestamp);

    switch (type) {
      case 'bookmark':
        return [
          _callout(
              emoji: '🔖', text: '$ts — Bookmark', color: 'red_background'),
        ];
      case 'voice':
        return [
          {
            'type': 'audio',
            'audio': {
              'type': 'external',
              'external': {
                'url': content, // your Cloudinary audio URL
              },
            },
          },
          {
            'type': 'paragraph',
            'paragraph': {
              'rich_text': [
                {
                  'type': 'text',
                  'text': {
                    'content': '🎙️ Voice note @ ${_fmt(timestamp)}',
                  },
                }
              ],
            },
          },
        ];
      case 'text':
        return [
          _callout(
              emoji: '📝', text: '$ts — $content', color: 'blue_background'),
        ];

      case 'image':
        return [
          _callout(
              emoji: '🖼️',
              text: '$ts — Image note',
              color: 'purple_background'),
          if (content.isNotEmpty) _imageBlock(content),
        ];

      // ── NEW: combined image + text note ──────────────────────────────────
      case 'image_text':
        final (imgUrl, caption) = _decodeImageText(content);
        return [
          _callout(
            emoji: '🖼️',
            text: caption.isEmpty ? '$ts — Image note' : '$ts — $caption',
            color: 'purple_background',
          ),
          if (imgUrl.isNotEmpty) _imageBlock(imgUrl),
        ];

      default:
        return [
          _callout(
              emoji: '📌', text: '$ts — $content', color: 'gray_background'),
        ];
    }
  }

  // ── Get or create video toggle ────────────────────────────────────────────

  Future<String> _getOrCreateVideoToggle({
    required String apiKey,
    required String coursePageId,
    required String videoName,
    String? cachedId,
  }) async {
    if (cachedId != null && cachedId.isNotEmpty) {
      debugPrint(
          'NotionService: cache hit for toggle "$videoName" = $cachedId');
      return cachedId;
    }

    final res = await http.get(
      Uri.parse(
          'https://api.notion.com/v1/blocks/$coursePageId/children?page_size=100'),
      headers: _headers(apiKey),
    );

    if (res.statusCode == 200) {
      final results = (jsonDecode(res.body)['results'] as List?) ?? [];
      for (final block in results) {
        if (block['type'] != 'heading_2') continue;
        final richText = (block['heading_2']?['rich_text'] as List?) ?? [];
        if (richText.isEmpty) continue;
        final text = richText[0]['text']?['content'] ?? '';
        if (text == '📹 $videoName') {
          debugPrint(
              'NotionService: reusing toggle for "$videoName" = ${block['id']}');
          return block['id'] as String;
        }
      }
    }

    final createRes = await http.patch(
      Uri.parse('https://api.notion.com/v1/blocks/$coursePageId/children'),
      headers: _headers(apiKey),
      body: jsonEncode({
        'children': [
          {
            'object': 'block',
            'type': 'heading_2',
            'heading_2': {
              'rich_text': [
                {
                  'type': 'text',
                  'text': {'content': '📹 $videoName'},
                }
              ],
              'is_toggleable': true,
              'color': 'default',
            },
          }
        ]
      }),
    );

    if (createRes.statusCode == 200) {
      final id =
          (jsonDecode(createRes.body)['results'] as List)[0]['id'] as String;
      debugPrint('NotionService: created toggle for "$videoName" = $id');
      return id;
    }
    throw Exception(
        'Failed to create toggle: ${jsonDecode(createRes.body)['message']}');
  }

  // ── Notion block helpers ──────────────────────────────────────────────────

  Map<String, dynamic> _callout({
    required String emoji,
    required String text,
    required String color,
  }) =>
      {
        'object': 'block',
        'type': 'callout',
        'callout': {
          'icon': {'type': 'emoji', 'emoji': emoji},
          'color': color,
          'rich_text': [
            {
              'type': 'text',
              'text': {'content': text}
            }
          ],
        },
      };

  Map<String, dynamic> _imageBlock(String url) => {
        'object': 'block',
        'type': 'image',
        'image': {
          'type': 'external',
          'external': {'url': url},
        },
      };

  Map<String, dynamic> _divider() =>
      {'object': 'block', 'type': 'divider', 'divider': {}};

  // ── Main sync ─────────────────────────────────────────────────────────────

  Future<SyncResult> syncNotes() async {
    if (!isConfigured) {
      return SyncResult(success: 0, failed: 0, error: 'Notion not configured.');
    }

    final apiKey = _storage.getNotionApiKey()!;
    final parentPageId = _storage.getNotionParentPageId()!;

    final notes = _storage.getUnsyncedNotes();
    debugPrint('syncNotes: found ${notes.length} unsynced notes');
    if (notes.isEmpty) return SyncResult(success: 0, failed: 0);

    final grouped = <String, Map<String, List<Note>>>{};
    for (final note in notes) {
      final video = _storage.getVideo(note.videoId);
      if (video == null) continue;
      grouped
          .putIfAbsent(video.courseId, () => {})
          .putIfAbsent(note.videoId, () => [])
          .add(note);
    }

    int success = 0, failed = 0;

    for (final courseEntry in grouped.entries) {
      try {
        final course = _storage
            .getCourses()
            .where((c) => c.id == courseEntry.key)
            .firstOrNull;
        final courseName = course?.name ?? 'Unknown Course';

        final coursePageId = await _getOrCreateChildPage(
          apiKey: apiKey,
          parentPageId: parentPageId,
          title: courseName,
          emoji: '🎓',
          cachedId: course?.notionPageId,
        );
        if (course != null) {
          course.notionPageId = coursePageId;
          await course.save();
        }

        for (final videoEntry in courseEntry.value.entries) {
          try {
            final video = _storage.getVideo(videoEntry.key);
            final videoName = video?.name ?? 'Unknown Video';

            final noteBlocks = <Map<String, dynamic>>[];
            final notesToMark = <Note>[];

            for (final note in videoEntry.value) {
              if (note.isSyncedWithNotion) continue;
              try {
                String content = note.content;

                // ── Resolve local paths to remote URLs before building blocks ──

                if (note.type == 'image' && !content.startsWith('http')) {
                  final url = await _uploadImage(content);
                  if (url != null) content = url;
                }

                if (note.type == 'image_text') {
                  final (imgPath, caption) = _decodeImageText(content);
                  if (imgPath.isNotEmpty && !imgPath.startsWith('http')) {
                    final url = await _uploadImage(imgPath);
                    // Re-encode with the uploaded URL (caption unchanged)
                    content = '${url ?? imgPath}$_kSep$caption';
                  }
                }

                if (note.type == 'voice' && !content.startsWith('http')) {
                  final url = await _uploadVoice(content);
                  if (url != null) content = url;
                  // content is now a CDN URL → _buildNoteBlocks will render it as audio
                }

                noteBlocks.addAll(
                    _buildNoteBlocks(note.type, note.timestamp, content));
                noteBlocks.add(_divider());
                notesToMark.add(note);
              } catch (e) {
                debugPrint('Error building blocks for note ${note.id}: $e');
                failed++;
              }
            }

            if (noteBlocks.isNotEmpty) {
              String toggleId = await _getOrCreateVideoToggle(
                apiKey: apiKey,
                coursePageId: coursePageId,
                videoName: videoName,
                cachedId: video?.notionPageId,
              );

              bool appended = await _appendBlocks(
                apiKey: apiKey,
                pageId: toggleId,
                blocks: noteBlocks,
              );

              if (!appended) {
                debugPrint(
                    'NotionService: stale toggle, clearing cache and retrying...');
                if (video != null) {
                  video.notionPageId = null;
                  await video.save();
                }
                if (course != null) {
                  course.notionPageId = null;
                  await course.save();
                }

                final freshCoursePageId = await _getOrCreateChildPage(
                  apiKey: apiKey,
                  parentPageId: parentPageId,
                  title: courseName,
                  emoji: '🎓',
                );
                if (course != null) {
                  course.notionPageId = freshCoursePageId;
                  await course.save();
                }

                final freshToggleId = await _getOrCreateVideoToggle(
                  apiKey: apiKey,
                  coursePageId: freshCoursePageId,
                  videoName: videoName,
                );
                if (video != null) {
                  video.notionPageId = freshToggleId;
                  await video.save();
                }

                appended = await _appendBlocks(
                  apiKey: apiKey,
                  pageId: freshToggleId,
                  blocks: noteBlocks,
                );
              }

              if (appended) {
                for (final note in notesToMark) {
                  note.isSyncedWithNotion = true;
                  await note.save();
                  success++;
                }
              } else {
                failed += notesToMark.length;
              }
            }
          } catch (e) {
            debugPrint('Error syncing video ${videoEntry.key}: $e');
            failed += videoEntry.value.length;
          }
        }
      } catch (e) {
        debugPrint('Error syncing course ${courseEntry.key}: $e');
        for (final vNotes in courseEntry.value.values) {
          failed += vNotes.length;
        }
      }
    }

    return SyncResult(success: success, failed: failed);
  }

  // ── Audio helpers ─────────────────────────────────────────────────────────

  // Future<String?> _transcribeAudio(String localPath) async {
  //   try {
  //     final wavPath = await _convertToWav(localPath);
  //     if (wavPath == null) return null;

  //     final whisper = Whisper(
  //       model: WhisperModel.small,
  //       downloadHost:
  //           'https://huggingface.co/ggerganov/whisper.cpp/resolve/main',
  //     );

  //     final result = await whisper.transcribe(
  //       transcribeRequest: TranscribeRequest(
  //         audio: wavPath,
  //         isVerbose: false,
  //         isTranslate: false,
  //         isNoTimestamps: true,
  //         splitOnWord: false,
  //       ),
  //     );

  //     try {
  //       await File(wavPath).delete();
  //     } catch (_) {}

  //     debugPrint('NotionService: transcript = $result');
  //     return result.text.trim().isEmpty ? null : result.text.trim();
  //   } catch (e) {
  //     debugPrint('NotionService: transcribe error $e');
  //     return null;
  //   }
  // }

  // Future<String?> _convertToWav(String inputPath) async {
  //   try {
  //     final dir = await getTemporaryDirectory();
  //     final wavPath =
  //         '${dir.path}/whisper_${DateTime.now().millisecondsSinceEpoch}.wav';

  //     final session = await FFmpegKit.execute(
  //       '-i $inputPath -ar 16000 -ac 1 -c:a pcm_s16le $wavPath',
  //     );

  //     final returnCode = await session.getReturnCode();
  //     if (ReturnCode.isSuccess(returnCode)) {
  //       return wavPath;
  //     } else {
  //       final output = await session.getOutput();
  //       debugPrint('NotionService: ffmpeg failed = $output');
  //       return null;
  //     }
  //   } catch (e) {
  //     debugPrint('NotionService: conversion error $e');
  //     return null;
  //   }
  // }

  bool _isSyncing = false;

  Future<void> autoSync() async {
    if (!isConfigured) return;
    if (_isSyncing) {
      debugPrint('autoSync: skipped (busy)');
      return;
    }
    _isSyncing = true;
    try {
      final r = await syncNotes();
      debugPrint('autoSync: ${r.message}');
    } catch (e) {
      debugPrint('autoSync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // OLD: ── Imgbb image upload ────────────────────────────────────────────────────

  // ── Cloudinary upload — preserves original quality, no recompression ────────
  // Cloud Name  : visible on your Cloudinary dashboard
  // Upload Preset: Settings → Upload → Upload presets → the NAME column
  //   (NOT the UUID — use the short name like "ml_default" or whatever you set)
  //   Make sure Signing Mode = Unsigned.

  Future<String?> _uploadImage(String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final cloudName = _storage.getCloudinaryCloudName() ?? 'drsfitprd';
      final uploadPreset = _storage.getCloudinaryUploadPreset() ?? 'TikGood';

      if (cloudName.isEmpty || uploadPreset.isEmpty) {
        debugPrint('Cloudinary credentials missing.');
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );
      // upload_preset must be the preset NAME (e.g. "tikgood_notes"),
      // not the preset UUID shown in the URL bar.
      request.fields['upload_preset'] = uploadPreset;
      // Do NOT pass transformation on unsigned presets — it gets rejected.
      request.files.add(await http.MultipartFile.fromPath('file', localPath));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      debugPrint('Cloudinary response [${res.statusCode}]: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // secure_url → direct CDN link, embeds correctly in Notion image blocks.
        final url = data['secure_url'] as String?;
        debugPrint('Cloudinary upload OK: $url');
        return url;
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
    }
    return null;
  }

// ── Upload voice to Cloudinary ──────────────────────────────────────────────
  Future<String?> _uploadVoice(String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final cloudName = _storage.getCloudinaryCloudName() ?? 'drsfitprd';
      final uploadPreset = _storage.getCloudinaryUploadPreset() ?? 'TikGood';

      if (cloudName.isEmpty || uploadPreset.isEmpty) {
        debugPrint('Cloudinary credentials missing.');
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload'),
      );
      request.fields['upload_preset'] = uploadPreset;
      request.fields['resource_type'] = 'video'; // audio lives under 'video'
      request.files.add(await http.MultipartFile.fromPath('file', localPath));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      debugPrint('Cloudinary voice [${res.statusCode}]: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final url = data['secure_url'] as String?;
        debugPrint('Cloudinary voice OK: $url');
        return url;
      }
    } catch (e) {
      debugPrint('Voice upload error: $e');
    }
    return null;
  }

  String _fmt(int total) {
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Result type ───────────────────────────────────────────────────────────────

class DbIds {
  final String coursesDbId;
  final String videosDbId;
  final String notesDbId;
  const DbIds({
    required this.coursesDbId,
    required this.videosDbId,
    required this.notesDbId,
  });
}

class SyncResult {
  final int success;
  final int failed;
  final String? error;
  SyncResult({required this.success, required this.failed, this.error});
  bool get hasError => error != null;
  String get message {
    if (error != null) return '❌ $error';
    if (success == 0 && failed == 0) return '✅ All notes already synced';
    if (failed == 0) {
      return '✅ Synced $success note${success != 1 ? "s" : ""} to Notion';
    }
    return '⚠️ $success synced, $failed failed';
  }
}
