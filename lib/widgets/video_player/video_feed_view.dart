import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tikgood/core/widgets/swipe_to_profile_wrapper.dart';
import 'package:tikgood/core/widgets/tiktok_loading_widget.dart';
import 'package:tikgood/features/courses/presentation/pages/course_profile_page.dart';
import '../../features/home/presentation/bloc/app_cubit.dart';
import '../../features/home/presentation/bloc/app_state.dart';
import '../../core/database/storage_service.dart';
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
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkForInitialTarget());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Called from BlocListener AND initState ────────────────────────────────
  void _handleJumpTarget() {
    final state = context.read<AppCubit>().state;
    final targetId = state.targetVideoId;
    if (targetId == null) return;

    // Always read videoFeed fresh from state, not from a stale closure
    final index = state.videoFeed.indexWhere((v) => v.id == targetId);
    if (index == -1) return;

    animateToVideo(index);
    // DON'T clearJumpTarget here — VideoItem.initState needs targetTimestamp
    // to still be set when it mounts after the page jump.
    // VideoItem clears it itself after seeking.
  }

  void _checkForInitialTarget() {
    final state = context.read<AppCubit>().state;
    // Feed might not be loaded yet — retry once feed is non-empty
    if (state.videoFeed.isEmpty) return;
    _handleJumpTarget();
  }

  @override
  Widget build(BuildContext context) {
    // BlocListener is OUTSIDE BlocBuilder so it always reads fresh state
    // and is never affected by stale closure captures.
    return BlocListener<AppCubit, AppState>(
      listenWhen: (prev, curr) =>
          curr.targetVideoId != null &&
          curr.targetVideoId != prev.targetVideoId,
      listener: (context, state) => _handleJumpTarget(),
      child: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final videos = state.videoFeed;
          final courseMap = {for (final c in state.courses) c.id: c.name};
          final followedCourseIds = {
            for (final c in state.courses)
              if (c.isFollowed) c.id,
          };

          // Feed just loaded and we have a pending target → jump now
          if (videos.isNotEmpty && state.targetVideoId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _handleJumpTarget();
            });
          }

          return Stack(
            children: [
              videos.isEmpty
                  ? _buildEmptyState(context, state)
                  : PageView.builder(
                      scrollDirection: Axis.vertical,
                      controller: _pageController,
                      itemCount: videos.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                        if (index < videos.length) {
                          context.read<AppCubit>().saveLastViewedVideo(
                                videos[index].id,
                                0,
                              );
                        }
                      },
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        final courseName = courseMap[video.courseId];

                        return SwipeToProfileWrapper(
                          key: ValueKey('swipe_${video.id}'),
                          overlayBuilder: (_) => CourseProfilePage(
                            courseId: video.courseId,
                            showBackButton:
                                false, // wrapper provides the back button
                          ),
                          child: VideoItem(
                            key: ValueKey(video.id),
                            video: video,
                            courseName: courseName,
                            isActive: index == _currentIndex,
                            isFollowingCourse:
                                followedCourseIds.contains(video.courseId),
                            initialTimestamp: state.targetVideoId == video.id
                                ? state.targetTimestamp
                                : null,
                            subtitleVisible: context
                                .read<StorageService>()
                                .getSubtitleVisible(),
                          ),
                        );
                      },
                    ),
              if (!state.isFullscreen)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: TopNavigation(
                    state: state,
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
              if (state.isLoading)
                const SizedBox(
                  key: ValueKey('loading'),
                  child: TikTokLoadingAnimation(),
                ),
            ],
          );
        },
      ),
    );
  }

  void animateToVideo(int index) {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
      setState(() => _currentIndex = index);
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
}
