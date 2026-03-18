// video.dart
import 'package:hive/hive.dart';

part 'video.g.dart';

@HiveType(typeId: 1)
class Video extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String courseId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final String filePath;
  @HiveField(4)
  int lastSecondWatched;
  @HiveField(5)
  final String? subPath;
  @HiveField(6)
  String? notionPageId; // cached Notion page ID for this video

  Video({
    required this.id,
    required this.courseId,
    required this.name,
    required this.filePath,
    this.lastSecondWatched = 0,
    this.subPath,
    this.notionPageId,
  });
}
