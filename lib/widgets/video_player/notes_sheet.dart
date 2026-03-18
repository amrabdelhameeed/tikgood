import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/courses/data/models/video.dart';
import '../../features/home/presentation/bloc/app_cubit.dart';
import '../../core/database/storage_service.dart';
import '../../features/notes/data/datasources/notion_service.dart';
import 'note_item.dart';

class TikTokNotesSheet extends StatefulWidget {
  final Video video;
  final int currentTimestamp;

  /// Called for every note the user submits.
  /// May be called twice in quick succession when sending image + text together.
  final Function(String type, String content) onAddNote;

  /// Parent [VideoItem] supplies this so the sheet can trigger a frame capture.
  /// Should call [mk.VideoController.screenshot()] and return the saved path,
  /// or null on failure.
  final Future<String?> Function()? onCaptureFrame;
  final Function(int timestamp)? onSeek;

  const TikTokNotesSheet({
    required this.video,
    required this.currentTimestamp,
    required this.onAddNote,
    this.onCaptureFrame,
    this.onSeek,
    super.key,
  });

  @override
  State<TikTokNotesSheet> createState() => _TikTokNotesSheetState();
}

class _TikTokNotesSheetState extends State<TikTokNotesSheet> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AudioRecorder _recorder = AudioRecorder();
  final Player _voicePlayer = Player();

  late Timer? _waveTimer;
  List<double> _staticWaveHeights = [
    6,
    10,
    14,
    8,
    16,
    10,
    12,
    6,
    14,
    10,
    8,
    12
  ];

  bool _isRecording = false;
  bool _isCapturing = false;
  String? _playingVoicePath;
  String? _pendingImagePath;
  bool _pendingImageIsFrame = false;

  List<double> _amplitudeHistory = [];
  static const int _maxAmplitudeHistory = 30;

  // Emojis matching the screenshot order
  static const _quickEmojis = [
    'Important',
    'Search',
    'Question',
    'Note',
    'Info',
    'Reminder',
    'Memorize'
  ];

  @override
  void initState() {
    super.initState();
    _voicePlayer.stream.completed.listen((completed) {
      if (completed && mounted) setState(() => _playingVoicePath = null);
    });
    _waveTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted && _playingVoicePath != null) {
        setState(() => _staticWaveHeights.shuffle());
      }
    });
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _recorder.dispose();
    _voicePlayer.dispose();
    _waveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes =
        context.watch<StorageService>().getNotesForVideo(widget.video.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212), // TikTok Dark Background
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Drag Handle
              Container(
                width: 35,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${notes.length} notes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.read<AppCubit>().toggleNotes(value: false);
                        },
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0.5, color: Colors.white10),

              // Notes List
              Expanded(
                child: notes.isEmpty
                    ? _buildEmptyNotes()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: notes.length,
                        itemBuilder: (context, i) => NoteItem(
                          note: notes[i],
                          isVoicePlaying: _playingVoicePath == notes[i].content,
                          onPlayVoice: () => _playVoiceNote(notes[i].content),
                          onDelete: () =>
                              context.read<AppCubit>().deleteNote(notes[i].id),
                          onShowImage: (path) =>
                              _showFullImage(context, path, notes[i].id),
                          onTapNote: () =>
                              widget.onSeek?.call(notes[i].timestamp),
                        ),
                      ),
              ),

              if (_pendingImagePath != null) _buildStagedImagePreview(),

              // Quick Emoji Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _quickEmojis // Renamed to reflect emojis + words
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    // Adds a space after the word/emoji for better UX
                                    _textController.text += "$item ";
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize:
                                          16, // Reduced slightly to fit text better
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),

              _buildInputBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    final bool hasContent =
        _textController.text.trim().isNotEmpty || _pendingImagePath != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        left: 12,
        right: 12,
        top: 8,
      ),
      color: const Color(0xFF121212),
      child: Row(
        // crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Gallery / Image Picker Icon
          IconButton(
            onPressed: _pickImage,
            icon:
                const Icon(Icons.image_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 8),

          GestureDetector(
            onTap: _captureFrame,
            child: Icon(
              Icons.screenshot_monitor_rounded,
              color: _isCapturing ? const Color(0xFFFE2C55) : Colors.white,
              size: 28,
            ),
          ),

          // Main Text Field
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2B2B2B),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Add a note...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  // Frame capture inside field (cleaner look)
                  // Mic
                  GestureDetector(
                    onTap: _handleVoice,
                    child: _isRecording
                        ? _buildRecordingWave()
                        : const Icon(Icons.mic_none_rounded,
                            color: Colors.white60, size: 22),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),

          // Send Button
          GestureDetector(
            onTap: _submitNote,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: hasContent
                    ? const Color(0xFFFE2C55)
                    : const Color(0xFF2B2B2B),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: hasContent ? Colors.white : Colors.white24,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... (Rest of logic: _captureFrame, _submitNote, _handleVoice remain largely same but check context/styling) ...

  Widget _buildStagedImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(File(_pendingImagePath!),
                width: 40, height: 40, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Text(
            _pendingImageIsFrame ? 'Frame captured' : 'Image selected',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _pendingImagePath = null),
            child: const Icon(Icons.close, color: Colors.white38, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotes() {
    return const Center(
      child: Text('No notes yet.', style: TextStyle(color: Colors.white38)),
    );
  }
  // ── actions ───────────────────────────────────────────────────────────────

  /// Captures the current video frame via the parent-supplied callback.
  Future<void> _captureFrame() async {
    if (_isCapturing || widget.onCaptureFrame == null) return;
    setState(() => _isCapturing = true);
    try {
      final path = await widget.onCaptureFrame!();
      if (path != null && mounted) {
        setState(() {
          _pendingImagePath = path;
          _pendingImageIsFrame = true;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  /// Sends the staged image and/or the typed text as separate notes
  /// but within the same UI action, so they always arrive at the same timestamp.
  // Separator used to pack imagePath + text into a single content string.
  // \x1F (ASCII Unit Separator) never appears in file paths or normal text.
  static const _sep = '\x1F';

  /// Decodes a combined 'image_text' content string into (imagePath, text).
  static (String imagePath, String text) decodeImageText(String content) {
    final idx = content.indexOf(_sep);
    if (idx == -1) return (content, ''); // plain image note fallback
    return (content.substring(0, idx), content.substring(idx + 1));
  }

  void _submitNote() {
    final text = _textController.text.trim();
    final hasImage = _pendingImagePath != null;
    final hasText = text.isNotEmpty;

    if (!hasImage && !hasText) return;

    if (hasImage && hasText) {
      // Single combined note: 'imagePath\x1Ftext'
      widget.onAddNote('image_text', '$_pendingImagePath$_sep$text');
    } else if (hasImage) {
      widget.onAddNote('image', _pendingImagePath!);
    } else {
      widget.onAddNote('text', text);
    }

    setState(() {
      _pendingImagePath = null;
      _pendingImageIsFrame = false;
    });
    _textController.clear();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() {
        _pendingImagePath = picked.path;
        _pendingImageIsFrame = false;
      });
    }
  }

  Future<void> _playVoiceNote(String path) async {
    if (_playingVoicePath == path) {
      await _voicePlayer.pause();
      setState(() => _playingVoicePath = null);
    } else {
      await _voicePlayer.stop();
      await _voicePlayer.open(Media(path));
      await _voicePlayer.play();
      setState(() => _playingVoicePath = path);
    }
  }

  Future<void> _handleVoice() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _amplitudeHistory.clear();
      });
      if (path != null) {
        widget.onAddNote('voice', path);
      }
    } else if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      await _recorder.start(
        const RecordConfig(),
        path: '${dir.path}/note_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      setState(() {
        _isRecording = true;
        _amplitudeHistory.clear();
      });
      _monitorAmplitude();
    }
  }

  Future<void> _monitorAmplitude() async {
    while (_isRecording && mounted) {
      try {
        final amp = await _recorder.getAmplitude();
        double normalized = 0;
        if (amp.current != double.negativeInfinity) {
          normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
        }
        if (mounted && _isRecording) {
          setState(() {
            _amplitudeHistory.add(normalized);
            if (_amplitudeHistory.length > _maxAmplitudeHistory) {
              _amplitudeHistory.removeAt(0);
            }
          });
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  void _showFullImage(BuildContext context, String path, String tag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (_, __, ___) => GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Hero(
                tag: tag,
                child: InteractiveViewer(
                  child: Image.file(File(path), fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingWave() {
    return SizedBox(
      width: 60,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (index) {
          final amplitude = _amplitudeHistory.isNotEmpty
              ? _amplitudeHistory[(_amplitudeHistory.length - 1 - index)
                  .clamp(0, _amplitudeHistory.length - 1)]
              : 0.3;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 3,
            height: (amplitude * 20 + 4).clamp(4.0, 24.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFE2C55),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
