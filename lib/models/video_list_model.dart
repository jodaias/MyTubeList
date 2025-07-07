import 'package:hive/hive.dart';
import 'package:my_tube_list/models/video_model.dart';

part 'video_list_model.g.dart';

@HiveType(typeId: 2)
class VideoListModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(3)
  final String profileId;

  @HiveField(2)
  final List<VideoModel> videos;

  VideoListModel({
    required this.id,
    required this.name,
    required this.profileId,
    this.videos = const [],
  });

  VideoListModel copyWith({
    String? id,
    String? name,
    List<VideoModel>? videos,
    String? profileId,
  }) {
    return VideoListModel(
      id: id ?? this.id,
      name: name ?? this.name,
      videos: videos ?? this.videos,
      profileId: profileId ?? this.profileId,
    );
  }
}
