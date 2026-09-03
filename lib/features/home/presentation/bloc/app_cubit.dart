import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tikgood/features/courses/data/datasources/video_service.dart';
import 'package:tikgood/features/courses/data/models/video.dart';
import 'package:tikgood/features/courses/data/models/video.dart';
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

  bool _isLoadingData = false;

  AppCubit(this._storage, this._videoService, this._notion)
      : super(const AppState()) {
    loadInitialData();
  }

  void toggleNotes({bool? value}) {
    emit(state.copyWith(isNotesOpened: value ?? !state.isNotesOpened));
  }

  // ── Initial load ─────────────────────────────────────────────────

  Future<void> loadInitialData() async {
    if (_isLoadingData) return;
    _isLoadingData = true;
    try {
      final courses = _storage.getCourses();

      final lastVideoId = _storage.getLastViewedVideoId();
      final lastTimestamp = _storage.getLastViewedTimestamp();

      final videos = <Video>[];
      for (final course in courses) {
        videos.addAll(_storage.getVideosForCourse(course.id));
      }
      videos.shuffle();

      emit(state.copyWith(
        courses: courses,
        isLoading: false,
        videoFeed: List.unmodifiable(videos),
        targetVideoId: lastVideoId,
        targetTimestamp: lastTimestamp,
      ));
    } catch (e) {
      debugPrint('loadInitialData error: $e');
      emit(state.copyWith(isLoading: false));
    } finally {
      _isLoadingData = false;
    }
  }

  // ── Feed ─────────────────────────────────────────────────────────

  void _updateFeed() {
    final videos = <Video>[];

    if (state.isFollowingTab) {
      for (final course in state.courses) {
        if (course.isFollowed) {
          videos.addAll(_storage.getVideosForCourse(course.id));
        }
      }
      videos.sort((a, b) {
        final p = (a.subPath ?? '').compareTo(b.subPath ?? '');
        return p != 0 ? p : a.name.compareTo(b.name);
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
      // Skip if course already exists
      final existingCourse = _storage.coursesBox.get(path);
      if (existingCourse != null) {
        existingCourse.isFollowed = followByDefault;
        await existingCourse.save();
        await loadInitialData();
        return;
      }

      final scannedCourses = await _videoService.scanDirectory(path);

      // Build set of existing file paths for O(1) dedup
      final existingPaths = <String>{
        for (final v in _storage.videosBox.values) v.filePath,
      };

      for (final course in scannedCourses) {
        course.isFollowed = followByDefault;
        await _storage.saveCourse(course);

        final videos = await _videoService.getVideosForCourse(course);
        for (final video in videos) {
          if (!existingPaths.contains(video.filePath)) {
            await _storage.videosBox.put(video.id, video);
            existingPaths.add(video.filePath);
          }
        }
      }
      await loadInitialData();
    } catch (e) {
      debugPrint('addCourse error: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> setFollowCourse(String courseId, bool isFollowed) async {
    final course = _storage.coursesBox.get(courseId);
    if (course == null) return;
    course.isFollowed = isFollowed;
    await course.save();
    _updateFeed();
  }

  Future<void> deleteCourse(String courseId) async {
    await _storage.deleteCourse(courseId);
    await loadInitialData();
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

  Future<void> editNote(String noteId, String newContent) async {
    await _storage.updateNoteContent(noteId, newContent);
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
    emit(AppState(
      courses: state.courses,
      videoFeed: state.videoFeed,
      isFollowingTab: state.isFollowingTab,
      isLoading: state.isLoading,
      isFullscreen: state.isFullscreen,
      isInPipMode: state.isInPipMode,
      isNotesOpened: state.isNotesOpened,
      currentNavIndex: state.currentNavIndex,
      targetVideoId: null,
      targetTimestamp: null,
    ));
  }
}
