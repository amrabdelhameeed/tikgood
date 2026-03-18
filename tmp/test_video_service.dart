import 'dart:io';
import 'package:path/path.dart' as p;
// Note: We'll use a simplified version of the models if we can't easily import them,
// but let's try to import them from the project.
import '../lib/features/courses/data/datasources/video_service.dart';
import '../lib/features/courses/data/models/course.dart';

void main() async {
  final tempDir = Directory('tmp_test_dir');
  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
  tempDir.createSync();

  try {
    print('--- Setting up test directory structure ---');
    final courseABase = Directory(p.join(tempDir.path, 'CourseA'));
    courseABase.createSync();
    
    File(p.join(courseABase.path, 'vid1.mp4')).createSync();
    
    final subFolder = Directory(p.join(courseABase.path, 'Module1'));
    subFolder.createSync();
    File(p.join(subFolder.path, 'vid2.mp4')).createSync();

    print('Test structure created:');
    print('  CourseA/vid1.mp4');
    print('  CourseA/Module1/vid2.mp4');

    final service = VideoService();
    
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

    print('\nSUCCESS: All tests passed!');
  } finally {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}
