import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/courses/data/models/course.dart';
import '../../features/courses/data/models/video.dart';
import '../../features/courses/data/models/liked_video.dart';
import '../../features/notes/data/models/note.dart';
import '../../features/notes/data/datasources/notion_service.dart'; // for DbIds

class StorageService {
  static const String coursesBoxName = 'courses';
  static const String videosBoxName = 'videos';
  static const String notesBoxName = 'notes';
  static const String likedVideosBoxName = 'liked_videos';
  static const String settingsBoxName = 'settings';

  late Box<Course> coursesBox;
  late Box<Video> videosBox;
  late Box<Note> notesBox;
  late Box<LikedVideo> likedVideosBox;
  late Box settingsBox;

  Future<void> init() async {
    coursesBox = await Hive.openBox<Course>(coursesBoxName);
    videosBox = await Hive.openBox<Video>(videosBoxName);
    notesBox = await Hive.openBox<Note>(notesBoxName);
    likedVideosBox = await Hive.openBox<LikedVideo>(likedVideosBoxName);
    settingsBox = await Hive.openBox(settingsBoxName);
    await Hive.openBox<String>('appServicesKey');
  }

  // --- Courses ---
  List<Course> getCourses() => coursesBox.values.toList();
  Future<void> saveCourse(Course course) async =>
      await coursesBox.put(course.id, course);

  // --- Videos ---
  List<Video> getVideosForCourse(String courseId) =>
      videosBox.values.where((v) => v.courseId == courseId).toList();

  Video? getVideo(String videoId) => videosBox.get(videoId);

  Future<void> updateLastWatched(String videoId, int seconds) async {
    final video = videosBox.get(videoId);
    if (video != null) {
      video.lastSecondWatched = seconds;
      await video.save();
    }
  }

  // --- Notes ---
  List<Note> getNotesForVideo(String videoId) {
    final notes = notesBox.values.where((n) => n.videoId == videoId).toList();
    notes.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return notes;
  }

  Future<void> addNote(Note note) async => await notesBox.put(note.id, note);

  Future<void> deleteNote(String noteId) async => await notesBox.delete(noteId);

  Future<void> updateNoteContent(String noteId, String newContent) async {
    final note = notesBox.get(noteId);
    if (note != null) {
      note.content = newContent;
      note.isSyncedWithNotion = false;
      await note.save();
    }
  }

  /// Deletes a course and all its associated data (videos, notes, liked videos).
  Future<void> deleteCourse(String courseId) async {
    // Delete all videos for this course
    final videoIds = <String>[];
    for (final video in videosBox.values.where((v) => v.courseId == courseId)) {
      videoIds.add(video.id);
      await video.delete();
    }

    // Delete all notes for those videos
    for (final note in notesBox.values.where((n) => videoIds.contains(n.videoId))) {
      await note.delete();
    }

    // Delete liked video entries for those videos
    for (final liked in likedVideosBox.values.where((l) => videoIds.contains(l.videoId))) {
      await liked.delete();
    }

    // Delete the course itself
    await coursesBox.delete(courseId);
  }

  List<Note> getUnsyncedNotes() =>
      notesBox.values.where((n) => !n.isSyncedWithNotion).toList();

  // --- Settings: Notion API key ---
  String? getNotionApiKey() => settingsBox.get('notion_api_key');
  Future<void> saveNotionApiKey(String key) async =>
      await settingsBox.put('notion_api_key', key);

  // --- Settings: Parent page (replaces old single DB id) ---
  String? getNotionParentPageId() => settingsBox.get('notion_parent_page_id');
  Future<void> saveNotionParentPageId(String id) async =>
      await settingsBox.put('notion_parent_page_id', id);

  // Keep old getter as alias so nothing else breaks during migration
  String? getNotionDatabaseId() => getNotionParentPageId();
  Future<void> saveNotionDatabaseId(String id) => saveNotionParentPageId(id);

  // --- Settings: 4 bootstrapped DB ids ---
  DbIds? getNotionDbIds() {
    final raw = settingsBox.get('notion_db_ids');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      return DbIds(
        coursesDbId: map['coursesDbId'] as String,
        videosDbId: map['videosDbId'] as String,
        notesDbId: map['notesDbId'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveNotionDbIds(DbIds ids) async {
    await settingsBox.put(
      'notion_db_ids',
      jsonEncode({
        'coursesDbId': ids.coursesDbId,
        'videosDbId': ids.videosDbId,
        'notesDbId': ids.notesDbId,
      }),
    );
  }

  Future<void> clearNotionDbIds() async =>
      await settingsBox.delete('notion_db_ids');

  // --- Settings: Cloudinary ---
  String? getCloudinaryCloudName() => settingsBox.get('cloudinary_cloud_name');
  Future<void> saveCloudinaryCloudName(String name) async =>
      await settingsBox.put('cloudinary_cloud_name', name);

  String? getCloudinaryUploadPreset() =>
      settingsBox.get('cloudinary_upload_preset');
  Future<void> saveCloudinaryUploadPreset(String preset) async =>
      await settingsBox.put('cloudinary_upload_preset', preset);

  // --- Settings: Cloudinary signed uploads (API key + secret) ---
  // NOTE: embedding the API secret in a client app means it can be
  // extracted from the binary. Fine for a personal app, but for a
  // public Play Store release use a backend signer instead.
  String? getCloudinaryApiKey() => settingsBox.get('cloudinary_api_key');
  Future<void> saveCloudinaryApiKey(String key) async =>
      await settingsBox.put('cloudinary_api_key', key);

  String? getCloudinaryApiSecret() =>
      settingsBox.get('cloudinary_api_secret');
  Future<void> saveCloudinaryApiSecret(String secret) async =>
      await settingsBox.put('cloudinary_api_secret', secret);

  // --- Settings: Subtitle visibility ---
  bool getSubtitleVisible() => settingsBox.get('subtitle_visible') ?? true;
  Future<void> saveSubtitleVisible(bool visible) async =>
      await settingsBox.put('subtitle_visible', visible);

  // --- Settings: Last viewed video ---
  String? getLastViewedVideoId() => settingsBox.get('last_viewed_video_id');
  Future<void> saveLastViewedVideoId(String videoId) async =>
      await settingsBox.put('last_viewed_video_id', videoId);

  int? getLastViewedTimestamp() => settingsBox.get('last_viewed_timestamp');
  Future<void> saveLastViewedTimestamp(int seconds) async =>
      await settingsBox.put('last_viewed_timestamp', seconds);
// Replace the 4 cache methods in StorageService with these:

  String? getNotionCoursePageId(String courseId) =>
      coursesBox.get(courseId)?.notionPageId;

  Future<void> saveNotionCoursePageId(
      String courseId, String notionPageId) async {
    final course = coursesBox.get(courseId);
    if (course != null) {
      course.notionPageId = notionPageId;
      await course.save();
    }
  }

  String? getNotionVideoPageId(String videoId) =>
      videosBox.get(videoId)?.notionPageId;

  Future<void> saveNotionVideoPageId(
      String videoId, String notionPageId) async {
    final video = videosBox.get(videoId);
    if (video != null) {
      video.notionPageId = notionPageId;
      await video.save();
    }
  }

  // --- Liked Videos ---
  bool isVideoLiked(String videoId) => likedVideosBox.containsKey(videoId);

  List<LikedVideo> getLikedVideos() => likedVideosBox.values.toList();

  /// Get all liked videos with their full Video objects, sorted by liked date (newest first)
  List<Map<String, dynamic>> getLikedVideosWithDetails() {
    final likedVideos = getLikedVideos();
    final List<Map<String, dynamic>> result = [];

    for (final liked in likedVideos) {
      final video = getVideo(liked.videoId);
      if (video != null) {
        result.add({
          'video': video,
          'likedAt': liked.likedAt,
        });
      }
    }

    // Sort by liked date, newest first
    result.sort((a, b) =>
        (b['likedAt'] as DateTime).compareTo(a['likedAt'] as DateTime));

    return result;
  }

  Future<void> likeVideo(String videoId) async {
    if (!likedVideosBox.containsKey(videoId)) {
      final likedVideo = LikedVideo(videoId: videoId);
      await likedVideosBox.put(videoId, likedVideo);
    }
  }

  Future<void> unlikeVideo(String videoId) async {
    await likedVideosBox.delete(videoId);
  }

  Future<void> toggleVideoLike(String videoId) async {
    if (isVideoLiked(videoId)) {
      await unlikeVideo(videoId);
    } else {
      await likeVideo(videoId);
    }
  }

  // --- Streak ---
  int getStreakCount() =>
      settingsBox.get('streak_count', defaultValue: 0) as int;
  Future<void> saveStreakCount(int count) async =>
      await settingsBox.put('streak_count', count);

  String? getLastOpenDate() =>
      settingsBox.get('streak_last_open_date') as String?;
  Future<void> saveLastOpenDate(String isoDate) async =>
      await settingsBox.put('streak_last_open_date', isoDate);

  // --- Reminder ---
  /// Stored as "HH:mm" 24-hour string, e.g. "20:00"
  String getReminderTime() =>
      settingsBox.get('reminder_time', defaultValue: '20:00') as String;
  Future<void> saveReminderTime(String hhmm) async =>
      await settingsBox.put('reminder_time', hhmm);

  bool getReminderEnabled() =>
      settingsBox.get('reminder_enabled', defaultValue: false) as bool;
  Future<void> saveReminderEnabled(bool enabled) async =>
      await settingsBox.put('reminder_enabled', enabled);
}
