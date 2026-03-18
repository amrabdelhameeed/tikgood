import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/home/presentation/bloc/app_cubit.dart';
import '../../features/home/presentation/bloc/app_state.dart';
import 'video_item.dart';
import 'top_navigation.dart';

class VideoFeedView extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const VideoFeedView({
    required this.scaffoldKey,
    super.key,
  });

  @override
  State<VideoFeedView> createState() => VideoFeedViewState();
}

class VideoFeedViewState extends State<VideoFeedView> {
  // Back to the original simple PageController — no custom spring physics.
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_checkForInitialTarget);
  }

  @override
  void didUpdateWidget(VideoFeedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Also check when widget updates (e.g., after data loads)
    WidgetsBinding.instance.addPostFrameCallback(_checkForInitialTarget);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final videos = state.videoFeed;

        // Quick lookup: courseId → courseName for the bottom details label.
        final courseMap = {
          for (final c in state.courses) c.id: c.name,
        };

        // Set of followed course IDs for the follow button logic.
        final followedCourseIds = {
          for (final c in state.courses)
            if (c.isFollowed) c.id,
        };

        return BlocListener<AppCubit, AppState>(
          listenWhen: (prev, current) =>
              current.targetVideoId != null &&
              current.targetVideoId != prev.targetVideoId,
          listener: (context, state) {
            if (state.targetVideoId != null) {
              final index =
                  videos.indexWhere((v) => v.id == state.targetVideoId);
              if (index != -1 && _pageController.hasClients) {
                // If the video is found in the current feed, jump to it
                // The VideoItem will handle seeking and clearing the target.
                animateToVideo(index);
              }
            }
          },
          child: Stack(
            children: [
              // ── Video Feed ──────────────────────────────────────────────
              videos.isEmpty
                  ? _buildEmptyState(context, state)
                  : PageView.builder(
                      scrollDirection: Axis.vertical,
                      controller: _pageController,
                      // Original default physics — no custom spring.
                      itemCount: videos.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                        // Persist the last viewed video
                        if (index < videos.length) {
                          context.read<AppCubit>().saveLastViewedVideo(
                                videos[index].id,
                                0, // timestamp resets on page change; VideoItem updates it
                              );
                        }
                      },
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        return VideoItem(
                          key: ValueKey(video.id),
                          video: video,
                          courseName: courseMap[video.courseId],
                          isActive: index == _currentIndex,
                          isFollowingCourse:
                              followedCourseIds.contains(video.courseId),
                          initialTimestamp: state.targetVideoId == video.id
                              ? state.targetTimestamp
                              : null,
                        );
                      },
                    ),

              // ── Top Navigation ──────────────────────────────────────────
              if (!state.isFullscreen)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: TopNavigation(
                    state: state,
                    // Change 'onMenuPressed' to 'onLivePressed' here:
                    onLivePressed: () =>
                        widget.scaffoldKey.currentState?.openDrawer(),
                    onFollowingTabPressed: () =>
                        context.read<AppCubit>().switchToFollowing(),
                    onForYouTabPressed: () =>
                        context.read<AppCubit>().switchToForYou(),
                    onFullscreenPressed: () {
                      final nextState = !state.isFullscreen;
                      context.read<AppCubit>().setFullscreen(nextState);
                      if (nextState) {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.landscapeLeft,
                          DeviceOrientation.landscapeRight,
                        ]);
                        SystemChrome.setEnabledSystemUIMode(
                            SystemUiMode.immersiveSticky);
                      } else {
                        SystemChrome.setPreferredOrientations(
                            [DeviceOrientation.portraitUp]);
                        SystemChrome.setEnabledSystemUIMode(
                            SystemUiMode.edgeToEdge);
                      }
                    },
                  ),
                ),

              // ── Loading overlay ─────────────────────────────────────────
              if (state.isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFFE2C55)),
                        SizedBox(height: 16),
                        Text('Scanning videos...',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _checkForInitialTarget(_) {
    final state = context.read<AppCubit>().state;
    if (state.targetVideoId != null) {
      final index =
          state.videoFeed.indexWhere((v) => v.id == state.targetVideoId);
      if (index != -1) {
        animateToVideo(index);
      }
    }
  }

  Widget _buildEmptyState(BuildContext context, AppState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            state.isFollowingTab
                ? Icons.subscriptions_outlined
                : Icons.video_library_outlined,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: 20),
          Text(
            state.isFollowingTab
                ? 'Follow a course to see videos here'
                : 'Add a course to get started',
            style: const TextStyle(color: Colors.white54, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          if (state.isFollowingTab && state.courses.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => context.read<AppCubit>().switchToForYou(),
              icon: const Icon(Icons.explore),
              label: const Text('Browse All Courses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE2C55),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
        ],
      ),
    );
  }

  void animateToVideo(int index) {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
  }
}
