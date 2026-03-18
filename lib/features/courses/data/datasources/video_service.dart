import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/course.dart';
import '../models/video.dart';
import 'package:path/path.dart' as p;

class VideoService {
  final _uuid = const Uuid();

  // Centralized allowed extensions
  static const _supportedExtensions = {'.mp4', '.mkv', '.mov', '.avi', '.webm'};

  Future<List<Course>> scanDirectory(String path) async {
    final rootDir = Directory(path);
    if (!await rootDir.exists()) return [];

    if (await _hasVideos(rootDir)) {
      return [_createCourse(rootDir)];
    }
    return [];
  }

  Future<List<Video>> getVideosForCourse(Course course) async {
    final dir = Directory(course.folderPath);
    if (!await dir.exists()) return [];

    List<Video> videos = [];

    try {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();

          // Only process if it's a supported video format
          if (_supportedExtensions.contains(ext)) {
            final relativePath =
                p.relative(entity.path, from: course.folderPath);
            final directoryPath = p.dirname(relativePath);

            videos.add(Video(
              id: _uuid.v4(),
              courseId: course.id,
              name: p.basenameWithoutExtension(entity.path),
              filePath: entity.path,
              subPath: directoryPath == '.'
                  ? null
                  : directoryPath.replaceAll('\\', '/'),
            ));
          }
        }
      }
    } catch (e) {
      debugPrint("Error during scan: $e");
    }

    // Sort by path, then by name
    videos.sort((a, b) {
      final pathCompare = (a.subPath ?? "").compareTo(b.subPath ?? "");
      if (pathCompare != 0) return pathCompare;
      return a.name.compareTo(b.name);
    });

    return videos;
  }

  Future<bool> _hasVideos(Directory dir) async {
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (_supportedExtensions.contains(ext)) return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Course _createCourse(Directory dir) {
    return Course(
      id: dir.path,
      name: p.basename(dir.path),
      folderPath: dir.path,
      isFollowed: true,
    );
  }
}
