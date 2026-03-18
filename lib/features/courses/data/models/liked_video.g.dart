// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liked_video.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LikedVideoAdapter extends TypeAdapter<LikedVideo> {
  @override
  final int typeId = 3;

  @override
  LikedVideo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LikedVideo(
      videoId: fields[0] as String,
      likedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LikedVideo obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.videoId)
      ..writeByte(1)
      ..write(obj.likedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LikedVideoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
