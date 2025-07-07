// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_list_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoListModelAdapter extends TypeAdapter<VideoListModel> {
  @override
  final int typeId = 2;

  @override
  VideoListModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoListModel(
      id: fields[0] as String,
      name: fields[1] as String,
      profileId: fields[3] as String,
      videos: (fields[2] as List).cast<VideoModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, VideoListModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.profileId)
      ..writeByte(2)
      ..write(obj.videos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoListModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
