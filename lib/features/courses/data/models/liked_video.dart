import 'package:hive/hive.dart';

part 'liked_video.g.dart';

@HiveType(typeId: 3)
class LikedVideo extends HiveObject {
  @HiveField(0)
  final String videoId;

  @HiveField(1)
  final DateTime likedAt;

  LikedVideo({
    required this.videoId,
    DateTime? likedAt,
  }) : likedAt = likedAt ?? DateTime.now();
}
