import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:media_kit/media_kit.dart';
import 'package:tikgood/core/utils/thumbnail_cache_service.dart';
import 'package:tikgood/core/widgets/tiktok_loading_widget.dart';
import '../../../courses/data/models/video.dart';
import '../../data/models/note.dart';
import '../../../courses/data/models/course.dart';
import '../../../../../core/database/storage_service.dart';
import '../../../home/presentation/bloc/app_cubit.dart';
import '../../../home/presentation/bloc/app_state.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _accent = Color(0xFFFE2C55);
const _accentSecondary = Color(0xFF25F4EE); // TikTok cyan
const _surface = Color(0xFF111111);
const _card = Color(0xFF161616);
const _cardElevated = Color(0xFF1E1E1E);
const _divider = Color(0xFF2A2A2A);
const _textPrimary = Colors.white;
const _textSecondary = Color(0xFF888888);
const _textTertiary = Color(0xFF444444);

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String _currentFilter = 'all';

  // ── Shared voice player (ONE player for all voice notes) ──────────────────
  Player? _sharedVoicePlayer;
  String? _currentlyPlayingNoteId;

  @override
  void initState() {
    super.initState();
    _sharedVoicePlayer = Player();
    _sharedVoicePlayer!.stream.completed.listen((done) {
      if (done && mounted) {
        setState(() => _currentlyPlayingNoteId = null);
      }
    });
  }

  @override
  void dispose() {
    _sharedVoicePlayer?.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice(String noteId, String path) async {
    if (_sharedVoicePlayer == null) return;

    // same note → pause
    if (_currentlyPlayingNoteId == noteId) {
      await _sharedVoicePlayer!.pause();
      setState(() => _currentlyPlayingNoteId = null);
      return;
    }

    // check file exists (local only)
    if (!await File(path).exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Voice file not found on device'),
            backgroundColor: _accent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    setState(() => _currentlyPlayingNoteId = noteId);
    await _sharedVoicePlayer!.open(Media('file://$path'));
    await _sharedVoicePlayer!.play();
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Notes',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: _textPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined,
              color: _textPrimary, size: 22),
          onPressed: _exportToPdf,
          tooltip: 'Export to PDF',
        ),
        _FilterButton(
          current: _currentFilter,
          onSelected: (v) => setState(() => _currentFilter = v),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(color: _divider, height: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final storage = context.read<StorageService>();
          final courses = state.courses;

          if (courses.isEmpty) {
            return _emptyState(Icons.note_add_outlined, 'No courses added yet');
          }

          final courseData = courses
              .whereType<Course>()
              .map((course) {
                final videos = storage.getVideosForCourse(course.id);
                final videosWithNotes = videos
                    .map((v) {
                      var notes = storage.getNotesForVideo(v.id);
                      if (_currentFilter != 'all') {
                        notes = notes
                            .where((n) => n.type == _currentFilter)
                            .toList();
                      }
                      return (video: v, notes: notes);
                    })
                    .where((vn) => vn.notes.isNotEmpty)
                    .toList();
                return (course: course, videoNotes: videosWithNotes);
              })
              .where((cd) => cd.videoNotes.isNotEmpty)
              .toList();

          if (courseData.isEmpty) {
            return _emptyState(
              Icons.edit_note_outlined,
              'No notes yet.\nBookmark moments while watching a video.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            itemCount: courseData.length,
            itemBuilder: (context, ci) {
              final cd = courseData[ci];
              final totalNotes =
                  cd.videoNotes.fold<int>(0, (s, vn) => s + vn.notes.length);
              return _CourseSection(
                courseName: cd.course.name,
                totalNotes: totalNotes,
                videoNotes: cd.videoNotes,
                onPlayNote: _playNoteAtTimestamp,
                currentlyPlayingNoteId: _currentlyPlayingNoteId,
                onToggleVoice: _toggleVoice,
              );
            },
          );
        },
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _playNoteAtTimestamp(Note note, Video video) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Playing "${video.name}" at ${_fmt(note.timestamp)}',
          style: const TextStyle(fontSize: 13),
        ),
        backgroundColor: _accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
    context.go('/');
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted)
        context.read<AppCubit>().jumpToNote(video.id, note.timestamp);
    });
  }

  Future<void> _exportToPdf() async {
    final storage = context.read<StorageService>();
    final courses = context.read<AppCubit>().state.courses;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: TikTokLoadingAnimation()),
    );
    try {
      final pdf =
          await _generatePdf(courses.whereType<Course>().toList(), storage);
      if (mounted) {
        context.pop();
        await Printing.layoutPdf(
          onLayout: (_) => pdf,
          name: 'TikGood_Notes_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<Uint8List> _generatePdf(
      List<Course> courses, StorageService storage) async {
    final pdf = pw.Document();
    for (final course in courses) {
      final videos = storage.getVideosForCourse(course.id);
      final vwn = videos
          .map((v) => (video: v, notes: storage.getNotesForVideo(v.id)))
          .where((vn) => vn.notes.isNotEmpty)
          .toList();
      if (vwn.isEmpty) continue;

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) {
          final content = <pw.Widget>[
            pw.Text('Course: ${course.name}',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
          ];
          for (final vn in vwn) {
            content
              ..add(pw.Text('Video: ${vn.video.name}',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)))
              ..add(pw.SizedBox(height: 10));

            for (final note in vn.notes) {
              String text = note.content;
              pw.Widget? img;
              if (note.type == 'image_text') {
                final i = note.content.indexOf('\x1F');
                final path =
                    i != -1 ? note.content.substring(0, i) : note.content;
                text = i != -1
                    ? 'Image Note: ${note.content.substring(i + 1)}'
                    : 'Image Note:';
                try {
                  img = pw.Image(pw.MemoryImage(File(path).readAsBytesSync()),
                      height: 150, fit: pw.BoxFit.contain);
                } catch (_) {}
              } else if (note.type == 'image') {
                text = 'Image Note:';
                try {
                  img = pw.Image(
                      pw.MemoryImage(File(note.content).readAsBytesSync()),
                      height: 150,
                      fit: pw.BoxFit.contain);
                } catch (_) {}
              } else if (note.type == 'voice') {
                text = 'Voice Note (Recording)';
              } else if (note.type == 'bookmark') {
                text = 'Bookmark';
              }

              content.add(pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8, left: 16),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('[${_fmt(note.timestamp)}]',
                        style: const pw.TextStyle(color: PdfColors.grey700)),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(text),
                          if (img != null) ...[pw.SizedBox(height: 8), img],
                        ],
                      ),
                    ),
                  ],
                ),
              ));
            }
            content.add(pw.SizedBox(height: 20));
          }
          return content;
        },
      ));
    }
    return pdf.save();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _emptyState(IconData icon, String message) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TikTok-style glitch icon effect
            Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(-2, 0),
                  child: Icon(icon,
                      size: 64, color: _accentSecondary.withOpacity(0.5)),
                ),
                Transform.translate(
                  offset: const Offset(2, 0),
                  child: Icon(icon, size: 64, color: _accent.withOpacity(0.5)),
                ),
                Icon(icon, size: 64, color: _textTertiary),
              ],
            ),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(color: _textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      );

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

// ── Filter button ──────────────────────────────────────────────────────────────
class _FilterButton extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelected;

  const _FilterButton({required this.current, required this.onSelected});

  static const _items = {
    'all': ('All', Icons.notes_outlined),
    'text': ('Text', Icons.text_fields_outlined),
    'voice': ('Voice', Icons.mic_none_outlined),
    'image': ('Images', Icons.image_outlined),
    'bookmark': ('Bookmarks', Icons.bookmark_border),
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.tune_outlined, color: _textPrimary, size: 22),
          if (current != 'all')
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 7,
                height: 7,
                decoration:
                    const BoxDecoration(color: _accent, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
      color: _cardElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelected,
      itemBuilder: (_) => _items.entries.map((e) {
        final selected = e.key == current;
        return PopupMenuItem<String>(
          value: e.key,
          child: Row(
            children: [
              Icon(e.value.$2,
                  size: 17, color: selected ? _accent : _textSecondary),
              const SizedBox(width: 10),
              Text(e.value.$1,
                  style: TextStyle(
                    color: selected ? _accent : _textPrimary,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  )),
              const Spacer(),
              if (selected) const Icon(Icons.check, size: 15, color: _accent),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Course section ─────────────────────────────────────────────────────────────
class _CourseSection extends StatelessWidget {
  final String courseName;
  final int totalNotes;
  final List<({Video video, List<Note> notes})> videoNotes;
  final Function(Note, Video) onPlayNote;
  final String? currentlyPlayingNoteId;
  final Future<void> Function(String noteId, String path) onToggleVoice;

  const _CourseSection({
    required this.courseName,
    required this.totalNotes,
    required this.videoNotes,
    required this.onPlayNote,
    required this.currentlyPlayingNoteId,
    required this.onToggleVoice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              // TikTok-style dual-color icon
              Stack(
                children: [
                  Transform.translate(
                    offset: const Offset(-1, 0),
                    child: const Icon(Icons.school_outlined,
                        color: _accentSecondary, size: 15),
                  ),
                  Transform.translate(
                    offset: const Offset(1, 0),
                    child: const Icon(Icons.school_outlined,
                        color: _accent, size: 15),
                  ),
                  const Icon(Icons.school_outlined,
                      color: Colors.white, size: 15),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  courseName,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              // TikTok-style pill counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFE2C55), Color(0xFFFF6B6B)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalNotes',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        ...videoNotes.map((vn) => _VideoNotesCard(
              video: vn.video,
              notes: vn.notes,
              onPlayNote: onPlayNote,
              currentlyPlayingNoteId: currentlyPlayingNoteId,
              onToggleVoice: onToggleVoice,
            )),
        const SizedBox(height: 8),
        Container(color: _divider, height: 0.5),
      ],
    );
  }
}

// ── Video notes card ───────────────────────────────────────────────────────────
class _VideoNotesCard extends StatelessWidget {
  final Video video;
  final List<Note> notes;
  final Function(Note, Video) onPlayNote;
  final String? currentlyPlayingNoteId;
  final Future<void> Function(String noteId, String path) onToggleVoice;

  const _VideoNotesCard({
    required this.video,
    required this.notes,
    required this.onPlayNote,
    required this.currentlyPlayingNoteId,
    required this.onToggleVoice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video header
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () {
              if (notes.isNotEmpty) onPlayNote(notes.first, video);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // TikTok-style video thumbnail placeholder
                  Container(
                    width: 52,
                    height: 52,
                    // decoration: BoxDecoration(
                    //   color: Colors.black,
                    //   borderRadius: BorderRadius.circular(8),
                    //   border:
                    //       Border.all(color: _accent.withOpacity(0.3), width: 1),
                    // ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glitch layers
                        Transform.translate(
                          offset: const Offset(-1.5, 0),
                          child: const Icon(Icons.play_circle_fill,
                              color: _accentSecondary, size: 24),
                        ),
                        Transform.translate(
                          offset: const Offset(1.5, 0),
                          child: const Icon(Icons.play_circle_fill,
                              color: _accent, size: 24),
                        ),
                        const Icon(Icons.play_circle_fill,
                            color: Colors.white, size: 24),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.name,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: _accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${notes.length} note${notes.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: _textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: _textTertiary, size: 18),
                ],
              ),
            ),
          ),
          Container(color: _divider, height: 0.5),
          // Note items
          ...notes.asMap().entries.map((e) {
            final isLast = e.key == notes.length - 1;
            return Column(
              children: [
                _NoteCardItem(
                  note: e.value,
                  video: video,
                  onPlay: () => onPlayNote(e.value, video),
                  isPlayingVoice: currentlyPlayingNoteId == e.value.id,
                  onToggleVoice: () =>
                      onToggleVoice(e.value.id, e.value.content),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(color: _divider, height: 0.5),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Note card item ─────────────────────────────────────────────────────────────
class _NoteCardItem extends StatefulWidget {
  final Note note;
  final Video video;
  final VoidCallback onPlay;
  final bool isPlayingVoice;
  final VoidCallback onToggleVoice;

  const _NoteCardItem({
    required this.note,
    required this.video,
    required this.onPlay,
    required this.isPlayingVoice,
    required this.onToggleVoice,
  });

  @override
  State<_NoteCardItem> createState() => _NoteCardItemState();
}

class _NoteCardItemState extends State<_NoteCardItem> {
  String? _thumbPath;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final path = await ThumbnailCacheService.instance
        .getThumbnail(widget.video.filePath);
    if (mounted) setState(() => _thumbPath = path);
  }

  void _showFullImage(String path) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      pageBuilder: (_, __, ___) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onPlay,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ──────────────────────────────────────────────
            _Thumbnail(
              thumbPath: _thumbPath,
              timestamp: widget.note.timestamp,
            ),
            const SizedBox(width: 12),

            // ── Content ────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TypeBadge(type: widget.note.type),
                      const SizedBox(width: 8),
                      Expanded(child: _buildContent(context)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _relativeDate(widget.note),
                        style: const TextStyle(
                            color: _textSecondary, fontSize: 11),
                      ),
                      const Spacer(),
                      // Notion sync badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.note.isSyncedWithNotion
                                ? Icons.cloud_done_outlined
                                : Icons.cloud_off_outlined,
                            size: 13,
                            color: widget.note.isSyncedWithNotion
                                ? const Color(0xFF22C55E)
                                : _textTertiary,
                          ),
                          if (widget.note.isSyncedWithNotion) ...[
                            const SizedBox(width: 3),
                            const Text(
                              'Synced',
                              style: TextStyle(
                                  color: Color(0xFF22C55E), fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Play CTA ───────────────────────────────────────────────
            const SizedBox(width: 10),
            GestureDetector(
              onTap: widget.onPlay,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(-1, 0),
                    child: Icon(Icons.play_circle_fill,
                        color: _accentSecondary.withOpacity(0.4), size: 26),
                  ),
                  Transform.translate(
                    offset: const Offset(1, 0),
                    child: Icon(Icons.play_circle_fill,
                        color: _accent.withOpacity(0.4), size: 26),
                  ),
                  const Icon(Icons.play_circle_fill, color: _accent, size: 26),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (widget.note.type) {
      case 'text':
        return Text(
          widget.note.content,
          style:
              const TextStyle(color: _textPrimary, fontSize: 13, height: 1.4),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        );

      case 'bookmark':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_accent, _accentSecondary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              'Bookmarked moment',
              style: TextStyle(
                  color: _accent, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        );

      case 'voice':
        return GestureDetector(
          onTap: widget.onToggleVoice,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isPlayingVoice
                    ? Colors.orange.withOpacity(0.6)
                    : Colors.orange.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Play/pause icon
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isPlayingVoice
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.orange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                // Waveform bars
                ...List.generate(14, (i) {
                  final heights = [
                    5.0,
                    9,
                    13,
                    7,
                    15,
                    9,
                    11,
                    5,
                    13,
                    9,
                    7,
                    11,
                    6,
                    10
                  ];
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 150 + i * 25),
                    margin: const EdgeInsets.symmetric(horizontal: 1.2),
                    width: 2.5,
                    height: widget.isPlayingVoice ? heights[i].toDouble() : 3.0,
                    decoration: BoxDecoration(
                      color: Colors.orange
                          .withOpacity(widget.isPlayingVoice ? 0.9 : 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  widget.isPlayingVoice ? 'Playing…' : 'Voice note',
                  style: TextStyle(
                    color: Colors.orange
                        .withOpacity(widget.isPlayingVoice ? 1.0 : 0.7),
                    fontSize: 12,
                    fontWeight: widget.isPlayingVoice
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );

      case 'image':
        return _imagePreview(context, widget.note.content, null);

      case 'image_text':
        final idx = widget.note.content.indexOf('\x1F');
        final path = idx != -1
            ? widget.note.content.substring(0, idx)
            : widget.note.content;
        final caption =
            idx != -1 ? widget.note.content.substring(idx + 1) : null;
        return _imagePreview(context, path, caption);

      default:
        return Text(widget.note.content,
            style: const TextStyle(color: _textPrimary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis);
    }
  }

  Widget _imagePreview(BuildContext context, String path, String? caption) {
    final file = File(path);
    final exists = file.existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: exists ? () => _showFullImage(path) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                exists
                    ? Image.file(file,
                        width: double.infinity, height: 130, fit: BoxFit.cover)
                    : Container(
                        width: double.infinity,
                        height: 70,
                        color: _surface,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: _textTertiary, size: 28),
                        ),
                      ),
                // TikTok-style gradient overlay on image
                if (exists)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Expand icon
                if (exists)
                  const Positioned(
                    bottom: 6,
                    right: 6,
                    child: Icon(Icons.fullscreen_rounded,
                        color: Colors.white70, size: 16),
                  ),
              ],
            ),
          ),
        ),
        if (caption != null && caption.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(caption,
              style: const TextStyle(color: _textSecondary, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }

  String _relativeDate(Note note) {
    final dt = note.createdAt;
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Thumbnail widget ───────────────────────────────────────────────────────────
class _Thumbnail extends StatelessWidget {
  final String? thumbPath;
  final int timestamp;

  const _Thumbnail({required this.thumbPath, required this.timestamp});

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 36,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: thumbPath != null
                ? Image.file(File(thumbPath!), fit: BoxFit.cover)
                : Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _divider, width: 0.5),
                    ),
                  ),
          ),
          // Gradient overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
          ),
          // Timestamp chip — TikTok style
          Positioned(
            bottom: 3,
            right: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _accent.withOpacity(0.4), width: 0.5),
              ),
              child: Text(
                _fmt(timestamp),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Type badge ─────────────────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  static const _config = {
    'text': (Icons.text_fields_outlined, Colors.blue),
    'voice': (Icons.mic_none_outlined, Colors.orange),
    'image': (Icons.image_outlined, Colors.purple),
    'image_text': (Icons.image_outlined, Colors.purple),
    'bookmark': (Icons.bookmark_outline, _accent),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config[type] ??
        (Icons.note_outlined, Colors.white38) as (IconData, Color);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: (cfg.$2 as Color).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (cfg.$2 as Color).withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Icon(cfg.$1 as IconData, color: cfg.$2 as Color, size: 13),
    );
  }
}
