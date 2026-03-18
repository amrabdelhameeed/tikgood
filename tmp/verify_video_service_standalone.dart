import 'dart:io';
import 'package:path/path.dart' as p;

// --- Simplified Mock Classes ---
class Course {
  final String id;
  final String name;
  final String folderPath;
  Course({required this.id, required this.name, required this.folderPath});
}

class Video {
  final String id;
  final String courseId;
  final String name;
  final String filePath;
  final String? subPath;
  Video({required this.id, required this.courseId, required this.name, required this.filePath, this.subPath});
}

// --- Simplified VideoService Logic ---
class VideoServiceLogic {
  Future<List<Course>> scanDirectory(String path) async {
    final rootDir = Directory(path);
    if (!await rootDir.exists()) return [];

    if (await _hasVideos(rootDir)) {
      return [Course(id: path, name: p.basename(path), folderPath: path)];
    }
    return [];
  }

  Future<List<Video>> getVideosForCourse(Course course) async {
    final dir = Directory(course.folderPath);
    if (!await dir.exists()) return [];

    List<Video> videos = [];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final path = entity.path.toLowerCase();
        if (path.endsWith('.mp4') || path.endsWith('.mkv')) {
          final relativePath = p.relative(entity.path, from: course.folderPath);
          final directoryPath = p.dirname(relativePath);
          
          videos.add(Video(
            id: 'mock-id',
            courseId: course.id,
            name: p.basenameWithoutExtension(entity.path),
            filePath: entity.path,
            subPath: directoryPath == '.' ? null : directoryPath.replaceAll('\\', '/'),
          ));
        }
      }
    }
    return videos;
  }

  Future<bool> _hasVideos(Directory dir) async {
    try {
      final entities = await dir.list(recursive: true).toList();
      for (final entity in entities) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if (path.endsWith('.mp4') || path.endsWith('.mkv')) {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }
}

void main() async {
  final tempDir = Directory('tmp_verify_dir');
  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
  tempDir.createSync();

  try {
    print('--- Setting up test directory structure ---');
    final courseABase = Directory(p.join(tempDir.path, 'MyCourse'));
    courseABase.createSync();
    
    File(p.join(courseABase.path, 'video_root.mp4')).createSync();
    
    final subFolder = Directory(p.join(courseABase.path, 'Deep', 'Folder'));
    subFolder.createSync(recursive: true);
    File(p.join(subFolder.path, 'video_deep.mp4')).createSync();

    print('Test structure created:');
    print('  MyCourse/video_root.mp4');
    print('  MyCourse/Deep/Folder/video_deep.mp4');

    final service = VideoServiceLogic();
    
    print('\n--- Testing scanDirectory ---');
    final scannedCourses = await service.scanDirectory(courseABase.path);
    print('Courses found: ${scannedCourses.length}');
    for (var c in scannedCourses) {
      print(' - Course: ${c.name} (Path: ${c.folderPath})');
    }

    if (scannedCourses.length != 1) {
      print('FAILED: Expected exactly 1 course, found ${scannedCourses.length}');
      exit(1);
    }

    print('\n--- Testing getVideosForCourse ---');
    final videos = await service.getVideosForCourse(scannedCourses[0]);
    print('Videos found: ${videos.length}');
    for (var v in videos) {
      print(' - Video: ${v.name} (SubPath: ${v.subPath})');
    }

    if (videos.length != 2) {
      print('FAILED: Expected 2 videos, found ${videos.length}');
      exit(1);
    }
    
    bool foundDeep = false;
    for (var v in videos) {
      if (v.name == 'video_deep' && v.subPath == 'Deep/Folder') {
        foundDeep = true;
      }
    }
    
    if (!foundDeep) {
      print('FAILED: Could not find deep video with correct subPath');
      exit(1);
    }

    print('\nSUCCESS: All tests passed!');
  } finally {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}
