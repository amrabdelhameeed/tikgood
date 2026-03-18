// course.dart
import 'package:hive/hive.dart';

part 'course.g.dart';

@HiveType(typeId: 0)
class Course extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String folderPath;
  @HiveField(3)
  bool isFollowed;
  @HiveField(4)
  String? notionPageId; // cached Notion page ID for this course

  Course({
    required this.id,
    required this.name,
    required this.folderPath,
    this.isFollowed = false,
    this.notionPageId,
  });
}
