import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tikgood/features/courses/data/datasources/video_service.dart';
import 'package:uuid/uuid.dart';
import '../../../notes/data/models/note.dart';
import '../../../../core/database/storage_service.dart';
import '../../../notes/data/datasources/notion_service.dart';
import 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  final StorageService _storage;
  final VideoService _videoService;
  final NotionService _notion;
  final _uuid = const Uuid();

  AppCubit(this._storage, this._videoService, this._notion)
      : super(const AppState()) {
    loadInitialData();
  }

  void toggleNotes({bool? value}) {
    emit(state.copyWith(isNotesOpened: value ?? !state.isNotesOpened));
  }

  // ── Initial load ─────────────────────────────────────────────────

  Future<void> loadInitialData() async {
    emit(state.copyWith(isLoading: true));
    final courses = _storage.getCourses();
    emit(state.copyWith(courses: courses, isLoading: false));
    _updateFeed();

    // Restore last viewed video position on startup
    final lastVideoId = _storage.getLastViewedVideoId();
    final lastTimestamp = _storage.getLastViewedTimestamp();
    if (lastVideoId != null) {
      emit(state.copyWith(
        targetVideoId: lastVideoId,
        targetTimestamp: lastTimestamp ?? 0,
      ));
    }
  }

  // ── Feed ─────────────────────────────────────────────────────────

  void _updateFeed() {
    final videos = <dynamic>[];

    if (state.isFollowingTab) {
      for (final course in state.courses) {
        if (course.isFollowed) {
          videos.addAll(_storage.getVideosForCourse(course.id));
        }
      }
      videos.sort((a, b) {
        final p = ((a.subPath ?? '') as String)
            .compareTo((b.subPath ?? '') as String);
        return p != 0 ? p : (a.name as String).compareTo(b.name as String);
      });
    } else {
      for (final course in state.courses) {
        videos.addAll(_storage.getVideosForCourse(course.id));
      }
      videos.shuffle();
    }

    emit(state.copyWith(videoFeed: List.unmodifiable(videos)));
  }

  void switchToFollowing() {
    if (!state.isFollowingTab) {
      emit(state.copyWith(isFollowingTab: true));
      _updateFeed();
    }
  }

  void switchToForYou() {
    if (state.isFollowingTab) {
      emit(state.copyWith(isFollowingTab: false));
      _updateFeed();
    }
  }

  // ── Course management ────────────────────────────────────────────

  Future<void> addCourse(String path, {bool followByDefault = true}) async {
    emit(state.copyWith(isLoading: true));
    try {
      final scannedCourses = await _videoService.scanDirectory(path);
      for (final course in scannedCourses) {
        course.isFollowed = followByDefault;
        await _storage.saveCourse(course);

        final videos = await _videoService.getVideosForCourse(course);
        for (final video in videos) {
          await _storage.videosBox.put(video.id, video);
        }
      }
      await loadInitialData();
    } catch (e) {
      debugPrint('addCourse error: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> setFollowCourse(String courseId, bool isFollowed) async {
    final course = state.courses.firstWhere((c) => c.id == courseId);
    course.isFollowed = isFollowed;
    await course.save();
    _updateFeed();
  }

  // ── Notes ────────────────────────────────────────────────────────

  Future<void> addNote({
    required String videoId,
    required int timestamp,
    required String type,
    String content = 'Note',
  }) async {
    final note = Note(
      id: _uuid.v4(),
      videoId: videoId,
      timestamp: timestamp,
      type: type,
      content: content,
      createdAt: DateTime.now(),
    );

    await _storage.addNote(note);
    emit(state.copyWith()); // trigger UI rebuild

    // Auto-sync to Notion in the background (non-blocking)
    _notion.autoSync();
  }

  Future<void> deleteNote(String noteId) async {
    await _storage.deleteNote(noteId);
    emit(state.copyWith()); // trigger UI rebuild
  }

  // ── Navigation / Feed Jumping ────────────────────────────────────

  void jumpToNote(String videoId, int timestamp) {
    emit(state.copyWith(
      targetVideoId: videoId,
      targetTimestamp: timestamp,
    ));
  }

  void setFullscreen(bool isFullscreen) {
    emit(state.copyWith(isFullscreen: isFullscreen));
  }

  void setPipMode(bool isInPipMode) {
    emit(state.copyWith(isInPipMode: isInPipMode));
  }

  void setCurrentNavIndex(int index) {
    // When navigating to home (index 0) and PIP is enabled, close notes sheet
    if (index == 0 && state.isInPipMode && state.isNotesOpened) {
      toggleNotes(value: false);
    }
    emit(state.copyWith(currentNavIndex: index));
  }

  /// Persist the currently viewed video and its playback position.
  Future<void> saveLastViewedVideo(String videoId, int timestamp) async {
    await _storage.saveLastViewedVideoId(videoId);
    await _storage.saveLastViewedTimestamp(timestamp);
  }

  void clearJumpTarget() {
    // To clear the targets, we need to pass null to copyWith.
    // But our copyWith uses ??, so passing null won't clear it.
    // Let's create a new state instance with the values cleared.
    emit(AppState(
      courses: state.courses,
      videoFeed: state.videoFeed,
      isFollowingTab: state.isFollowingTab,
      isLoading: state.isLoading,
      targetVideoId: null,
      targetTimestamp: null,
    ));
  }
}
