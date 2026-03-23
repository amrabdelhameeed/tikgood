import 'dart:io';

import 'package:background_on_back/background_on_back.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as mk;
import 'package:tikgood/core/utils/tik_tok_icons.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/notes/presentation/pages/notes_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/settings/presentation/pages/streak_settings_page.dart';
import 'features/following/presentation/pages/following_page.dart';
import 'features/courses/presentation/pages/add_course_page.dart';
import 'features/courses/presentation/pages/course_profile_page.dart';
import 'features/liked_videos/presentation/pages/liked_videos_page.dart';
import 'features/home/presentation/bloc/app_cubit.dart';
import 'features/home/presentation/bloc/app_state.dart';
import 'features/goals/presentation/pages/goal_screen.dart';
import 'features/goals/presentation/pages/goal_middleware_screen.dart';
import 'features/goals/data/services/goal_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/goal-middleware',
    routes: [
      GoRoute(
        path: '/goal-middleware',
        builder: (context, state) {
          final goalService = context.read<GoalService>();
          if (!goalService.getGoalReminderEnabled()) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.go('/');
              }
            });
            return const Scaffold(backgroundColor: Colors.black);
          }
          return GoalMiddlewareScreen(
            onGoalSet: () => context.go('/'),
            onSkip: () => context.go('/'),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, __) => const HomePage()),
            GoRoute(
              path: '/course/:courseId',
              builder: (context, state) {
                final courseId =
                    Uri.decodeComponent(state.pathParameters['courseId']!);
                return CourseProfilePage(courseId: courseId);
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/favorites', builder: (_, __) => const FavoritesPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/add', builder: (_, __) => const AddCoursePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/notes', builder: (_, __) => const NotesPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/settings', builder: (_, __) => const SettingsPage()),
            GoRoute(
                path: '/liked-videos',
                builder: (_, __) => const LikedVideosPage()),
            GoRoute(
                path: '/streak',
                builder: (_, __) => const StreakSettingsPage()),
            GoRoute(path: '/goals', builder: (_, __) => const GoalScreen()),
          ]),
        ],
      ),
      // Video player route (full screen)
      GoRoute(
        path: '/video',
        builder: (context, state) {
          final videoPath = state.uri.queryParameters['path'] ?? '';
          final videoName = state.uri.queryParameters['name'] ?? 'Video';
          return VideoPlayerPage(
            videoPath: videoPath,
            videoName: Uri.decodeComponent(videoName),
          );
        },
      ),
    ],
  );
}

class _FollowingIcon extends StatelessWidget {
  final bool isActive;
  const _FollowingIcon({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final double opacity = isActive ? 1.0 : 0.5;

    const double bigSize = 18.0;
    const double smallSize = 18.0;
    const double overlap = 7.0;

    final double smallVisible = smallSize - overlap;

    return SizedBox(
      width: bigSize + smallVisible,
      height: bigSize,
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Icon(
              TikTokIcons.profile,
              color: Colors.white.withOpacity(opacity),
              size: bigSize,
            ),
          ),
          Positioned(
            right: 0,
            top: (bigSize - smallSize) / 2,
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerRight,
                widthFactor: smallVisible / smallSize,
                child: Icon(
                  TikTokIcons.profile,
                  color: Colors.white.withOpacity(opacity * 0.65),
                  size: smallSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, Key? key})
      : super(key: key ?? const ValueKey('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  void _onNavTap(BuildContext context, int index) {
    navigationShell.goBranch(index);
    // Update nav index in cubit
    context.read<AppCubit>().setCurrentNavIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          final router = GoRouter.of(context);

          if (router.canPop()) {
            router.pop();
          } else {
            debugPrint('EXIT APP or send to background');
            BackgroundOnBack.pop();
          }
        },
        child: BlocBuilder<AppCubit, AppState>(builder: (context, state) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: state.isFullscreen ||
                    state.isInPipMode ||
                    state.isNotesOpened
                ? null
                : Container(
                    color: Colors.black,
                    child: SafeArea(
                      top: false,
                      child: Container(
                        height: 60, // ↑ from 50 — more room to tap
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.white, width: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            _NavItem(
                              index: 0,
                              currentIndex: navigationShell.currentIndex,
                              icon: TikTokIcons.home,
                              label: 'Home',
                              onTap: () => _onNavTap(context, 0),
                            ),
                            // Following tab
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _onNavTap(context, 1),
                                behavior: HitTestBehavior.opaque,
                                child: SizedBox(
                                  // Full height = full tap area
                                  height: double.infinity,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _FollowingIcon(
                                        isActive:
                                            navigationShell.currentIndex == 1,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Following',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(
                                              navigationShell.currentIndex == 1
                                                  ? 1.0
                                                  : 0.5),
                                          fontSize: 10,
                                          fontWeight:
                                              navigationShell.currentIndex == 1
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            _CustomAddButton(
                              onTap: () => _onNavTap(context, 2),
                            ),
                            _NavItem(
                              index: 3,
                              currentIndex: navigationShell.currentIndex,
                              icon: TikTokIcons.messages,
                              label: 'Inbox',
                              onTap: () => _onNavTap(context, 3),
                            ),
                            _NavItem(
                              index: 4,
                              currentIndex: navigationShell.currentIndex,
                              icon: TikTokIcons.profile,
                              label: 'Profile',
                              onTap: () => _onNavTap(context, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          );
        }));
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = index == currentIndex;
    final double opacity = isActive ? 1.0 : 0.5;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          // Fills the full nav bar height → maximum tap target
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white.withOpacity(opacity), size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(opacity),
                  fontSize: 10,
                  fontFamily: 'tiktok',
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CustomAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.topCenter,
          height: double.infinity,
          child: Center(
            child: SizedBox(
              width: 45.0,
              height: 28.0,
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 10.0),
                    width: 38.0,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 250, 45, 108),
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 10.0),
                    width: 38.0,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 32, 211, 234),
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 38.0,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.black,
                        size: 20.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VideoPlayerPage — shared video player for all video playback
// ─────────────────────────────────────────────────────────────────────────────

class VideoPlayerPage extends StatefulWidget {
  final String videoPath;
  final String videoName;

  const VideoPlayerPage({
    super.key,
    required this.videoPath,
    required this.videoName,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final Player _player;
  late final mk.VideoController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  static const Color _accentColor = Color(0xFFFE2C55);

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = mk.VideoController(_player);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = File(widget.videoPath);
      if (await file.exists()) {
        await _player.open(Media(widget.videoPath));
        await _player.play();
        setState(() {
          _isInitialized = true;
        });
      } else {
        setState(() {
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.videoName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white38,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Video not available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.videoName,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: _accentColor),
      );
    }

    return Center(
      child: mk.Video(
        controller: _controller,
      ),
    );
  }
}
