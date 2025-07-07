import 'package:hive/hive.dart';
import 'package:my_tube_list/models/video_list_model.dart';

part 'profile_model.g.dart';

@HiveType(typeId: 1)
class ProfileModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<VideoListModel> videoLists;

  @HiveField(3)
  final String? password;

  @HiveField(4)
  final String? securityQuestion; // 🆕 pergunta secreta

  @HiveField(5)
  final String? securityAnswer; // 🆕 resposta secreta

  ProfileModel({
    required this.id,
    required this.name,
    this.videoLists = const [],
    this.password,
    this.securityQuestion,
    this.securityAnswer,
  });

  ProfileModel copyWith({
    String? id,
    String? name,
    List<VideoListModel>? videoLists,
    String? password,
    String? securityQuestion,
    String? securityAnswer,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      videoLists: videoLists ?? this.videoLists,
      password: password ?? this.password,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswer: securityAnswer ?? this.securityAnswer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'videoLists': videoLists,
      'password': password,
      'securityQuestion': securityQuestion,
      'securityAnswer': securityAnswer,
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'],
      name: map['name'],
      videoLists: List<VideoListModel>.from(map['videoLists']),
      password: map['password'],
      securityQuestion: map['securityQuestion'],
      securityAnswer: map['securityAnswer'],
    );
  }

  hasPassword() {
    return password != null && password!.isNotEmpty;
  }
}
