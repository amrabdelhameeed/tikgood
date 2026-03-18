import 'package:tikgood/features/courses/data/models/course.dart';
import 'package:tikgood/features/courses/data/models/video.dart';

class AppState {
  final List<Course> courses;
  final List<Video> videoFeed;
  final bool isFollowingTab;
  final bool isLoading;
  final bool isFullscreen;
  final bool isInPipMode;
  final bool isNotesOpened;
  final int currentNavIndex;

  final String? targetVideoId;
  final int? targetTimestamp;

  const AppState({
    this.courses = const [],
    this.videoFeed = const [],
    this.isFollowingTab = true,
    this.isLoading = false,
    this.isFullscreen = false,
    this.isInPipMode = false,
    this.isNotesOpened = false,
    this.currentNavIndex = 0,
    this.targetVideoId,
    this.targetTimestamp,
  });

  AppState copyWith({
    List<Course>? courses,
    List<Video>? videoFeed,
    bool? isFollowingTab,
    bool? isLoading,
    bool? isFullscreen,
    bool? isInPipMode,
    bool? isNotesOpened,
    int? currentNavIndex,
    String? targetVideoId,
    int? targetTimestamp,
  }) {
    return AppState(
      courses: courses ?? this.courses,
      videoFeed: videoFeed ?? this.videoFeed,
      isFollowingTab: isFollowingTab ?? this.isFollowingTab,
      isLoading: isLoading ?? this.isLoading,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isInPipMode: isInPipMode ?? this.isInPipMode,
      isNotesOpened: isNotesOpened ?? this.isNotesOpened,
      currentNavIndex: currentNavIndex ?? this.currentNavIndex,
      targetVideoId: targetVideoId ?? this.targetVideoId,
      targetTimestamp: targetTimestamp ?? this.targetTimestamp,
    );
  }
}
