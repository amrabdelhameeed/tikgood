import 'dart:io';
import 'package:flutter/material.dart';
import '../../features/notes/data/models/note.dart';
import 'package:avatar_plus/avatar_plus.dart';

const _kSep = '\x1F';

(String imagePath, String text) _decodeImageText(String content) {
  final idx = content.indexOf(_kSep);
  if (idx == -1) return (content, '');
  return (content.substring(0, idx), content.substring(idx + 1));
}

/// Redesigned NoteItem that matches TikTok's comments UI exactly:
/// - White background pill-less style
/// - Circular avatar left
/// - Username bold, timestamp pill (red), sync badge (green/grey)
/// - Content below
/// - Footer: relative time | Reply | ♡ | 👎
/// - Swipe-to-delete with red background
class NoteItem extends StatelessWidget {
  final Note note;
  final bool isVoicePlaying;
  final bool isSyncing;
  final VoidCallback onPlayVoice;
  final VoidCallback onDelete;
  final Function(String path) onShowImage;
  final VoidCallback? onTapNote;

  const NoteItem({
    required this.note,
    this.isVoicePlaying = false,
    this.isSyncing = false,
    required this.onPlayVoice,
    required this.onDelete,
    required this.onShowImage,
    this.onTapNote,
    super.key,
  });

  String _formatTimestamp(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _relativeDate(Note note) {
    final dt = note.createdAt;
    if (dt == null) return '@ ${_formatTimestamp(note.timestamp)}';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFFF3B30),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                title: const Text('Delete note?',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                content: const Text('This note will be permanently deleted.',
                    style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white54)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete',
                        style: TextStyle(color: Color(0xFFFF3B30))),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTapNote,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ──────────────────────────────────────────────────
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF3A3A3A),
                child: ClipOval(
                  child: AvatarPlus(
                    note.id,
                    height: 40,
                    width: 40,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Content column ──────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: username + badges
                    Row(
                      children: [
                        const Text(
                          'You',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TimestampBadge(
                            timestamp: _formatTimestamp(note.timestamp)),
                        const SizedBox(width: 6),
                        _SyncBadge(isSynced: note.isSyncedWithNotion),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Note content
                    NoteContent(
                      note: note,
                      isVoicePlaying: isVoicePlaying,
                      onPlayVoice: onPlayVoice,
                      onShowImage: onShowImage,
                    ),
                    const SizedBox(height: 8),

                    // Footer: date | Reply | ♡ | 👎
                    Row(
                      children: [
                        Text(
                          _relativeDate(note),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                        const SizedBox(width: 14),
                        // const Text(
                        //   'Reply',
                        //   style: TextStyle(
                        //     color: Colors.white54,
                        //     fontSize: 11,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                        const Spacer(),
                        // const Icon(Icons.favorite_border_rounded,
                        //     color: Colors.white38, size: 17),
                        // const SizedBox(width: 14),
                        // const Icon(Icons.thumb_down_alt_outlined,
                        //     color: Colors.white38, size: 17),
                      ],
                    ),

                    // Syncing indicator
                    if (isSyncing)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white38,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Syncing to Notion...',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge Widgets ─────────────────────────────────────────────────────────────

class _TimestampBadge extends StatelessWidget {
  final String timestamp;
  const _TimestampBadge({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFE2C55).withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow_rounded,
              size: 11, color: Color(0xFFFE2C55)),
          const SizedBox(width: 2),
          Text(
            timestamp,
            style: const TextStyle(
              color: Color(0xFFFE2C55),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  final bool isSynced;
  const _SyncBadge({required this.isSynced});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isSynced
            ? const Color(0xFF27AE60).withOpacity(0.18)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: 11,
            color: isSynced ? const Color(0xFF27AE60) : Colors.white38,
          ),
          const SizedBox(width: 2),
          Text(
            isSynced ? 'Synced' : 'Local',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSynced ? const Color(0xFF27AE60) : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

// ── NoteContent ───────────────────────────────────────────────────────────────

class NoteContent extends StatelessWidget {
  final Note note;
  final bool isVoicePlaying;
  final VoidCallback onPlayVoice;
  final Function(String path) onShowImage;

  const NoteContent({
    required this.note,
    this.isVoicePlaying = false,
    required this.onPlayVoice,
    required this.onShowImage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    switch (note.type) {
      case 'text':
        return Text(
          note.content,
          style:
              const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
        );

      case 'voice':
        return _VoiceNoteWidget(isPlaying: isVoicePlaying, onTap: onPlayVoice);

      case 'image':
        return _ImageWidget(
          path: note.content,
          heroTag: note.id,
          onTap: () => onShowImage(note.content),
        );

      case 'image_text':
        final (imgPath, caption) = _decodeImageText(note.content);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                caption,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.4),
              ),
            ],
            _ImageWidget(
              path: imgPath,
              heroTag: note.id,
              onTap: () => onShowImage(imgPath),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────
class _ImageWidget extends StatelessWidget {
  final String path;
  final String heroTag;
  final VoidCallback onTap;

  const _ImageWidget(
      {required this.path, required this.heroTag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(path),
            width: double.infinity,
            alignment: Alignment.centerLeft,
            height: 220, // fixed height box
            fit: BoxFit.contain, // full image visible, letterboxed if needed
            errorBuilder: (_, __, ___) => Container(
              height: 60,
              color: const Color(0xFF2A2A2A),
              child: const Center(
                child: Icon(Icons.broken_image_rounded,
                    color: Colors.white24, size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceNoteWidget extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _VoiceNoteWidget({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isPlaying
              ? const Color(0xFFFE2C55).withOpacity(0.12)
              : const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying
                  ? Icons.stop_circle_rounded
                  : Icons.play_circle_filled_rounded,
              color: const Color(0xFFFE2C55),
              size: 30,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPlaying ? 'Playing...' : 'Voice note',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Tap to ${isPlaying ? "stop" : "play"}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Static waveform
            Row(
              children: List.generate(12, (i) {
                const heights = [
                  6.0,
                  10.0,
                  14.0,
                  8.0,
                  16.0,
                  10.0,
                  12.0,
                  6.0,
                  14.0,
                  10.0,
                  8.0,
                  12.0
                ];
                return Container(
                  width: 3,
                  height: heights[i],
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? const Color(0xFFFE2C55).withOpacity(0.7)
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
