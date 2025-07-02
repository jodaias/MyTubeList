import 'package:hive/hive.dart';

part 'profile_model.g.dart';

@HiveType(typeId: 1)
class ProfileModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<String> allowedVideoIds;

  ProfileModel({
    required this.id,
    required this.name,
    this.allowedVideoIds = const [],
  });

  ProfileModel copyWith({
    String? id,
    String? name,
    List<String>? allowedVideoIds,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      allowedVideoIds: allowedVideoIds ?? this.allowedVideoIds,
    );
  }
}
