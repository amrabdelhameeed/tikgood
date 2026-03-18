import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as mk;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tikgood/core/utils/tik_tok_icons.dart';
import 'package:avatar_plus/avatar_plus.dart';
import 'package:android_pip/android_pip.dart';
import 'package:android_pip/pip_widget.dart';
import 'package:android_pip/actions/pip_action.dart';
import 'package:android_pip/actions/pip_actions_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:tikgood/widgets/video_player/heart_widget.dart';

import '../../features/courses/data/models/video.dart';
import '../../features/home/presentation/bloc/app_cubit.dart';
import '../../features/home/presentation/bloc/app_state.dart';
import '../../core/database/storage_service.dart';
import 'action_button.dart';
import 'notes_sheet.dart';

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.15)
      ..quadraticBezierTo(0, 0, size.width * 0.12, size.height * 0.08)
      ..lineTo(size.width * 0.88, size.height * 0.45)
      ..quadraticBezierTo(
          size.width, size.height * 0.5, size.width * 0.88, size.height * 0.55)
      ..lineTo(size.width * 0.12, size.height * 0.92)
      ..quadraticBezierTo(0, size.height, 0, size.height * 0.85)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => false;
}

class _SpeedChevron extends StatefulWidget {
  final double initialPosition;
  final double size;
  const _SpeedChevron({required this.initialPosition, this.size = 16});

  @override
  State<_SpeedChevron> createState() => _SpeedChevronState();
}

class _SpeedChevronState extends State<_SpeedChevron>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      value: widget.initialPosition, // ← start at offset BEFORE repeat
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 1.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.15), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _ctrl.repeat(); // ← repeat immediately, already at offset
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: CustomPaint(
          size: Size(widget.size * 0.6, widget.size),
          painter: _TrianglePainter(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TikTokSpeedBadge  — pinned to bottom of its parent
// ─────────────────────────────────────────────────────────────────────────────
class _TikTokSpeedBadge extends StatelessWidget {
  const _TikTokSpeedBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding:
            const EdgeInsets.only(bottom: 0), // adjust to sit above nav bar
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          // decoration: BoxDecoration(
          //   color: Colors.black.withOpacity(0.5),
          //   borderRadius: BorderRadius.circular(6),
          //   border:
          //       Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
          // ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                'Speed:2X',
                style: TextStyle(
                  fontFamily: 'tiktok',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.3,
                  height: 1,
                ),
              ),
              SizedBox(width: 5),
              _SpeedChevron(initialPosition: 0.0),
              SizedBox(width: 1),
              _SpeedChevron(initialPosition: 0.33),
              SizedBox(width: 1),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StableVideo
// ─────────────────────────────────────────────────────────────────────────────
class _StableVideo extends StatefulWidget {
  final mk.VideoController controller;

  const _StableVideo({required this.controller, super.key});

  @override
  _StableVideoState createState() => _StableVideoState();
}

class _StableVideoState extends State<_StableVideo> {
  final GlobalKey<mk.VideoState> _videoKey = GlobalKey<mk.VideoState>();
  late final Widget _cached;

  EdgeInsets _lastPadding = EdgeInsets.zero;

  void setSubtitlePadding(EdgeInsets padding) {
    _lastPadding = padding;
    _videoKey.currentState?.setSubtitleViewPadding(padding);
  }

  void setSubtitleVisibility(bool visible) {
    if (visible) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _videoKey.currentState?.setSubtitleViewPadding(_lastPadding);
      });
    } else {
      _videoKey.currentState?.setSubtitleViewPadding(const EdgeInsets.only(
        bottom: 1000,
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    // Cache the widget once — rebuilding mk.Video with the same key causes
    // a ValueNotifier<VideoViewParameters> disposed crash inside media_kit.
    _cached = mk.Video(
      key: _videoKey,
      wakelock: true,
      focusNode: FocusNode(),
      resumeUponEnteringForegroundMode: true,
      controller: widget.controller,
      controls: mk.NoVideoControls,
      fit: BoxFit.contain,
      pauseUponEnteringBackgroundMode: false,
      fill: Colors.transparent,
      subtitleViewConfiguration:
          const mk.SubtitleViewConfiguration(visible: true),
    );
  }

  @override
  void didUpdateWidget(_StableVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Intentionally no rebuild — prevents ValueNotifier crash in media_kit.
  }

  @override
  Widget build(BuildContext context) => _cached;
}

// ─────────────────────────────────────────────────────────────────────────────
// VideoItem
// ─────────────────────────────────────────────────────────────────────────────
class VideoItem extends StatefulWidget {
  final Video video;
  final bool isActive;
  final String? courseName;
  final int? initialTimestamp;
  final bool isFollowingCourse;

  const VideoItem({
    required this.video,
    this.isActive = true,
    this.courseName,
    this.initialTimestamp,
    this.isFollowingCourse = false,
    super.key,
  });

  @override
  State<VideoItem> createState() => VideoItemState();
}

class VideoItemState extends State<VideoItem>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Player _player = Player();
  late final mk.VideoController _controller = mk.VideoController(_player);
  late final AnimationController _diskController;

  final GlobalKey<_StableVideoState> _stableKey =
      GlobalKey<_StableVideoState>();

  bool _isPlaying = true;
  bool _showPlayPause = false;
  bool _isNotesOpen = false;
  bool _isSpeeding = false;
  bool _isSeeking = false;

  double _currentProgress = 0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  int _videoWidth = 0;
  int _videoHeight = 0;
  bool _isLandscapeMode = false;

  bool _isInPipMode = false;

  bool _isLiked = false;
  final GlobalKey<TikTokHeartButtonState> _heartKey =
      GlobalKey<TikTokHeartButtonState>();

  final List<Offset> _hearts = [];

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<int?>? _widthSub;
  StreamSubscription<int?>? _heightSub;

  // ── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _isLiked = context.read<StorageService>().isVideoLiked(widget.video.id);

    _diskController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _player.open(Media(widget.video.filePath));
    _player.setPlaylistMode(PlaylistMode.loop);

    if (widget.initialTimestamp != null && widget.initialTimestamp! > 0) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted || _disposed) return;
        _player.seek(Duration(seconds: widget.initialTimestamp!));
        context.read<AppCubit>().clearJumpTarget();
      });
    }

    _playingSub = _player.stream.playing.listen((playing) {
      if (!mounted || _disposed) return;
      setState(() => _isPlaying = playing);
      playing ? _diskController.repeat() : _diskController.stop();
    });

    _positionSub = _player.stream.position.listen((position) {
      if (!mounted || _isSeeking || _disposed) return;
      if (_totalDuration.inMilliseconds > 0) {
        setState(() {
          _currentPosition = position;
          _currentProgress =
              position.inMilliseconds / _totalDuration.inMilliseconds;
        });
        if (widget.isActive &&
            position.inSeconds % 5 == 0 &&
            position.inSeconds > 0) {
          context.read<AppCubit>().saveLastViewedVideo(
                widget.video.id,
                position.inSeconds,
              );
        }
      }
    });

    _durationSub = _player.stream.duration.listen((duration) {
      if (!mounted || _disposed) return;
      setState(() => _totalDuration = duration);
    });

    _widthSub = _player.stream.width.listen((w) {
      if (!mounted || _disposed || w == null || w <= 0) return;
      setState(() => _videoWidth = w);
    });

    _heightSub = _player.stream.height.listen((h) {
      if (!mounted || _disposed || h == null || h <= 0) return;
      setState(() => _videoHeight = h);
    });

    if (!widget.isActive) _player.pause();

    // ── PIP: do NOT call _syncPipArming() here.
    // It will be triggered reactively in didUpdateWidget when isActive becomes
    // true, and in the BlocListener when the nav index changes.
    // Calling it unconditionally in initState is what caused PIP to arm on
    // every tab's VideoItem at startup.

    WidgetsBinding.instance.addObserver(this);
  }

  // ── App lifecycle (foreground ↔ background) ───────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Guard 1: only the currently-playing video handles this.
    if (!widget.isActive) return;

    // Guard 2: only arm PIP when the user is on the Home tab (index 0).
    final appCubit = context.read<AppCubit>();
    final isOnHome = appCubit.state.currentNavIndex == 0;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (mounted && isOnHome) {
        _closeNotesSheet();
        setState(() => _isInPipMode = true);
        appCubit.setPipMode(true);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(() => _isInPipMode = false);
        appCubit.setPipMode(false);
      }
    }
  }

  // ── PIP arming/disarming ──────────────────────────────────────────────────

  /// Arms PIP if [isOnHome] is true, clears it otherwise.
  /// Safe to call multiple times — the OS calls are idempotent.
  Future<void> _syncPipArming({required bool isOnHome}) async {
    try {
      final isPipAvailable = await AndroidPIP.isPipAvailable;
      if (isPipAvailable != true) return;

      if (isOnHome) {
        await AndroidPIP().setAutoPipMode();
        debugPrint('PIP: armed (home tab, video=${widget.video.id})');
      } else {
        await AndroidPIP().setAutoPipMode(autoEnter: false);
        debugPrint('PIP: disarmed (not home tab, video=${widget.video.id})');
      }
    } catch (e) {
      debugPrint('PIP: sync failed — $e');
    }
  }

  /// Called by PipWidget whenever the user taps controls inside the PIP window.
  void _onPipAction(PipAction action) {
    switch (action) {
      case PipAction.play:
        _player.play();
        break;
      case PipAction.pause:
        _player.pause();
        break;
      case PipAction.next:
        _player.seek(_currentPosition + const Duration(seconds: 10));
        break;
      case PipAction.previous:
        _player.seek(_currentPosition - const Duration(seconds: 10));
        break;
      default:
        break;
    }
  }

  // ── fullscreen ────────────────────────────────────────────────────────────

  void _toggleLandscapeContext() {
    final nextState = !context.read<AppCubit>().state.isFullscreen;
    context.read<AppCubit>().setFullscreen(nextState);
    if (nextState) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  // ── frame capture ─────────────────────────────────────────────────────────

  Future<String?> _captureFrame() async {
    try {
      final bytes = await _controller.player.screenshot();
      if (bytes == null || bytes.isEmpty) return null;
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/frame_$ts.png');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('VideoItem: frame capture failed — $e');
      return null;
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double _renderedVideoHeight(double containerW, double containerH) {
    if (_videoWidth <= 0 || _videoHeight <= 0) return containerH;
    final videoAspect = _videoWidth / _videoHeight;
    final containerAspect = containerW / containerH;
    return videoAspect >= containerAspect
        ? containerW / videoAspect
        : containerH;
  }

  void _togglePlayPause() {
    _isPlaying ? _player.pause() : _player.play();
    setState(() => _showPlayPause = true);
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showPlayPause = false);
    });
  }

  void _handleDoubleTap(TapDownDetails details) {
    setState(() {
      _hearts.add(details.localPosition);
      _isLiked = true;
    });
    _heartKey.currentState?.triggerLike();
    context.read<StorageService>().likeVideo(widget.video.id);
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted)
        setState(() {
          if (_hearts.isNotEmpty) _hearts.removeAt(0);
        });
    });
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (details.localPosition.dx > MediaQuery.of(context).size.width * 0.7) {
      _player.setRate(2.0);
      setState(() => _isSpeeding = true);
      HapticFeedback.heavyImpact();
    }
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    _player.setRate(1.0);
    setState(() => _isSpeeding = false);
  }

  @override
  void didUpdateWidget(VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      widget.isActive ? _player.play() : _player.pause();

      // When this video becomes the active one, sync PIP arming immediately.
      // When it becomes inactive, disarm PIP so another video can take over.
      if (widget.isActive) {
        final isOnHome = context.read<AppCubit>().state.currentNavIndex == 0;
        _syncPipArming(isOnHome: isOnHome);
      } else {
        // Disarm — this video is no longer visible.
        _syncPipArming(isOnHome: false);
      }
    }

    if (widget.initialTimestamp != null &&
        widget.initialTimestamp != oldWidget.initialTimestamp) {
      _player.seek(Duration(seconds: widget.initialTimestamp!));
      Future.microtask(() {
        if (mounted) context.read<AppCubit>().clearJumpTarget();
      });
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _playingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _widthSub?.cancel();
    _heightSub?.cancel();
    _diskController.dispose();
    _player.pause();
    Future.delayed(const Duration(milliseconds: 200), () {
      _player.dispose();
    });
    if (_isLandscapeMode) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  // ── build ─────────────────────────────────────────────────────────────────

  int? _previousNavIndex;

  void _checkAndCloseNotesSheet() {
    final appCubit = context.read<AppCubit>();
    final currentNavIndex = appCubit.state.currentNavIndex;

    if (_previousNavIndex == null) {
      _previousNavIndex = currentNavIndex;
      return;
    }

    if (_previousNavIndex != 0 &&
        currentNavIndex == 0 &&
        appCubit.state.isInPipMode &&
        _isNotesOpen) {
      _closeNotesSheet();
    }
    _previousNavIndex = currentNavIndex;
  }

  void _closeNotesSheet() {
    if (_isNotesOpen) {
      Navigator.of(context).pop();
      setState(() => _isNotesOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkAndCloseNotesSheet();
    _isLandscapeMode = context.watch<AppCubit>().state.isFullscreen;
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final topPad = MediaQuery.of(context).padding.top;

    final containerH = screenH;
    final renderedH = _renderedVideoHeight(screenW, containerH);
    final barH = (containerH - renderedH) / 2;
    final subtitleOffset = renderedH * 0.2;
    final bottomPadding = _isLandscapeMode
        ? 0.0
        : (barH - subtitleOffset).clamp(0.0, double.infinity);

    final double videoHeight = _isNotesOpen ? (screenH * 0.35) : screenH;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _stableKey.currentState?.setSubtitlePadding(
          EdgeInsets.only(bottom: bottomPadding),
        );
      }
    });

    final bool hideAllUI = _isSpeeding;

    final Widget videoCore = Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _togglePlayPause,
          onDoubleTapDown: _handleDoubleTap,
          onDoubleTap: () {},
          onLongPressStart: _onLongPressStart,
          onLongPressEnd: _onLongPressEnd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. VIDEO ──────────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: videoHeight,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.fastOutSlowIn,
                  color: Colors.black,
                  child: _StableVideo(
                    key: _stableKey,
                    controller: _controller,
                  ),
                ),
              ),

              // ── 2. GRADIENTS ──────────────────────────────────────────
              if (!_isNotesOpen &&
                  !_isLandscapeMode &&
                  !_isInPipMode &&
                  !hideAllUI) ...[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 120,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],

              // ── 3. PLAY/PAUSE FLASH ───────────────────────────────────
              if (_showPlayPause && !hideAllUI)
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 1.5),
                    duration: const Duration(milliseconds: 200),
                    builder: (_, value, __) => Opacity(
                      opacity: (2.0 - value).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                              color: Colors.black26, shape: BoxShape.circle),
                          child: Icon(
                            _isPlaying
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── 4. HEARTS ─────────────────────────────────────────────
              if (!hideAllUI)
                ..._hearts.map((pos) => Positioned(
                      left: pos.dx - 40,
                      top: pos.dy - 40,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        builder: (_, value, __) => Opacity(
                          opacity: (1.0 - value).clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, -100 * value),
                            child: Transform.scale(
                              scale: 1.0 + value,
                              child: const Icon(Icons.favorite,
                                  color: Color(0xFFFE2C55), size: 80),
                            ),
                          ),
                        ),
                      ),
                    )),

              // ── 5. PORTRAIT UI ────────────────────────────────────────
              if (!_isNotesOpen &&
                  !_isLandscapeMode &&
                  !_isInPipMode &&
                  !hideAllUI) ...[
                Positioned(
                  left: 16,
                  right: 100,
                  bottom: 28,
                  child: _buildBottomDetails(),
                ),
                Positioned(
                  right: 8,
                  bottom: 16,
                  child: _buildRightActions(),
                ),
              ],

              // ── 6. PROGRESS BAR ───────────────────────────────────────
              if (!_isNotesOpen && !_isInPipMode && !hideAllUI)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildProgressBar(),
                ),

              // ── 7. 2× SPEED BADGE ─────────────────────────────────────
              AnimatedOpacity(
                opacity: _isSpeeding ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  child: Align(
                    alignment: const Alignment(0, -0.25),
                    child: const _TikTokSpeedBadge(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 8. EXIT FULLSCREEN (landscape) ────────────────────────────────
        if (_isLandscapeMode && !_isNotesOpen && !hideAllUI)
          Positioned(
            right: 16,
            top: topPad + 8,
            child: SafeArea(
              child: Material(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _toggleLandscapeContext,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.fullscreen_exit,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    // ── BlocListener re-syncs PIP arming whenever the nav tab changes ────────
    // This is the key fix: when the user swipes to the Following tab while a
    // video is active, we immediately call clearAutoPipMode() so Android no
    // longer triggers PIP on background for that tab.
    return BlocListener<AppCubit, AppState>(
      listenWhen: (prev, curr) =>
          widget.isActive && prev.currentNavIndex != curr.currentNavIndex,
      listener: (context, state) {
        final isOnHome = state.currentNavIndex == 0;
        _syncPipArming(isOnHome: isOnHome);
      },
      child: PipWidget(
        pipLayout: PipActionsLayout.media_only_pause,
        onPipAction: _onPipAction,
        pipChild: _buildPipOnlyVideo(),
        child: videoCore,
      ),
    );
  }

  // ── Minimal video-only widget used as PIP child ───────────────────────────
  Widget _buildPipOnlyVideo() {
    return ColoredBox(
      color: Colors.black,
      child: _StableVideo(
        controller: _controller,
      ),
    );
  }

  // ── sub-widgets ───────────────────────────────────────────────────────────

  bool _subtitlesVisible = true;

  Widget _buildBottomDetails() {
    final courseName = widget.courseName ?? widget.video.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          courseName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.music_note, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: 16,
                child: widget.video.name.length > 100
                    ? Marquee(
                        text: widget.video.name,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        scrollAxis: Axis.horizontal,
                        blankSpace: 20.0,
                        velocity: 30.0,
                        pauseAfterRound: const Duration(seconds: 3),
                        accelerationDuration: const Duration(milliseconds: 500),
                        accelerationCurve: Curves.easeIn,
                        decelerationDuration: const Duration(milliseconds: 500),
                        decelerationCurve: Curves.easeOut,
                      )
                    : Text(
                        widget.video.name,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ),
          ],
        ),
        // const SizedBox(height: 8),
        // GestureDetector(
        //   onTap: () {
        //     setState(() => _subtitlesVisible = !_subtitlesVisible);
        //     _stableKey.currentState?.setSubtitleVisibility(_subtitlesVisible);
        //     HapticFeedback.lightImpact();
        //   },
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Icon(
        //         _subtitlesVisible
        //             ? Icons.subtitles_rounded
        //             : Icons.subtitles_off_rounded,
        //         color: Colors.white.withOpacity(0.75),
        //         size: 13,
        //       ),
        //       // const SizedBox(width: 4),
        //       // Text(
        //       //   _subtitlesVisible ? 'Hide subtitles' : 'Show subtitles',
        //       //   style: TextStyle(
        //       //     color: Colors.white.withOpacity(0.75),
        //       //     fontSize: 11,
        //       //   ),
        //       // ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildRightActions() {
    final noteCount = context
        .watch<StorageService>()
        .getNotesForVideo(widget.video.id)
        .length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCreatorAvatar(),
        const SizedBox(height: 24),
        TikTokHeartButton(
          key: _heartKey,
          icon: TikTokIcons.heart,
          liked: _isLiked,
          onDoubleTap: (isLiked) {
            setState(() {
              _isLiked = isLiked;
            });
            if (isLiked) {
              context.read<StorageService>().likeVideo(widget.video.id);
            } else {
              context.read<StorageService>().unlikeVideo(widget.video.id);
            }
          },
          iconSize: 30,
        ),
        const SizedBox(height: 24),
        TikTokActionButton(
          icon: TikTokIcons.chat_bubble,
          label: '$noteCount',
          onTap: _showNotesSheet,
          iconSize: 25,
        ),
        const SizedBox(height: 20),
        TikTokActionButton(
          icon: Icons.bookmark_rounded,
          label: 'Save',
          onTap: () {
            context.read<AppCubit>().addNote(
                  videoId: widget.video.id,
                  timestamp: _player.state.position.inSeconds,
                  type: 'bookmark',
                  content: 'Saved to bookmarks',
                );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saved to bookmarks!'),
                backgroundColor: Color(0xFFFE2C55),
                duration: Duration(seconds: 2),
              ),
            );
          },
          iconSize: 30,
        ),
        const SizedBox(height: 20),
        TikTokActionButton(
          icon: TikTokIcons.reply,
          label: 'Share',
          onTap: () {},
          mirrorHorizontal: false,
          iconSize: 20,
        ),
        const SizedBox(height: 20),
        RotationTransition(
          turns: _diskController,
          child: _buildMusicDisk(),
        ),
      ],
    );
  }

  Widget _buildCreatorAvatar() {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            context
                .push('/course/${Uri.encodeComponent(widget.video.courseId)}');
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              color: Colors.grey.shade800,
            ),
            child: ClipOval(
              child: AvatarPlus(
                widget.courseName ?? widget.video.courseId,
                height: 48,
                width: 48,
              ),
            ),
          ),
        ),
        if (!widget.isFollowingCourse)
          Positioned(
            bottom: -10,
            child: GestureDetector(
              onTap: () {
                context.read<AppCubit>().setFollowCourse(
                      widget.video.courseId,
                      true,
                    );
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Following ${widget.courseName ?? 'course'}!',
                    ),
                    backgroundColor: const Color(0xFFFE2C55),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFFE2C55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 15),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMusicDisk() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black87,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child:
          const Icon(Icons.music_note_rounded, color: Colors.white, size: 22),
    );
  }

  Widget _buildProgressBar() {
    final screenW = MediaQuery.of(context).size.width;
    final filled = screenW * _currentProgress.clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (details) {
        setState(() => _isSeeking = true);
        HapticFeedback.heavyImpact();
      },
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final p = (details.localPosition.dx / box.size.width).clamp(0.0, 1.0);
        setState(() {
          _currentProgress = p;
          _currentPosition = Duration(
            milliseconds: (p * _totalDuration.inMilliseconds).toInt(),
          );
        });
      },
      onHorizontalDragEnd: (_) {
        _player.seek(_currentPosition);
        setState(() => _isSeeking = false);
      },
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final p = (details.localPosition.dx / box.size.width).clamp(0.0, 1.0);
        setState(() {
          _currentProgress = p;
          _isSeeking = true;
          _currentPosition = Duration(
            milliseconds: (p * _totalDuration.inMilliseconds).toInt(),
          );
        });
        _player.seek(_currentPosition);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _isSeeking = false);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _isSeeking ? 80 : 15,
        width: screenW,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomLeft,
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: _isSeeking ? 6 : 2,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: AnimatedContainer(
                duration: _isSeeking
                    ? Duration.zero
                    : const Duration(milliseconds: 100),
                height: _isSeeking ? 6 : 2,
                width: filled,
                color: Colors.white,
              ),
            ),
            if (_isSeeking) ...[
              Positioned(
                bottom: -6,
                left: (filled - 9).clamp(0.0, screenW - 18),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black45,
                          blurRadius: 10,
                          spreadRadius: 1)
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _fmt(_currentPosition),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${_fmt(_totalDuration)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── notes sheet ───────────────────────────────────────────────────────────

  void _showNotesSheet() {
    context.read<AppCubit>().toggleNotes(value: true);
    setState(() => _isNotesOpen = true);
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => TikTokNotesSheet(
        video: widget.video,
        currentTimestamp: _player.state.position.inSeconds,
        onSeek: (timestamp) {
          _player.seek(Duration(seconds: timestamp));
        },
        onCaptureFrame: _captureFrame,
        onAddNote: (type, content) => context.read<AppCubit>().addNote(
              videoId: widget.video.id,
              timestamp: _player.state.position.inSeconds,
              type: type,
              content: content,
            ),
      ),
    ).then((_) {
      if (mounted) setState(() => _isNotesOpen = false);
    }).whenComplete(() => context.read<AppCubit>().toggleNotes(value: false));
  }
}
