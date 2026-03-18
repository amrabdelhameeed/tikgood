// note.dart — unchanged, already correct
import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 2)
class Note extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String videoId;
  @HiveField(2)
  final int timestamp;
  @HiveField(3)
  final String type; // text, voice, image, bookmark
  @HiveField(4)
  final String content;
  @HiveField(5)
  bool isSyncedWithNotion;
  @HiveField(6)
  DateTime? createdAt;

  Note({
    required this.id,
    required this.videoId,
    required this.timestamp,
    required this.type,
    required this.content,
    this.isSyncedWithNotion = false,
    this.createdAt,
  });
}
