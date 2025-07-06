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

  @HiveField(3)
  final String? password;

  @HiveField(4)
  final String? securityQuestion; // 🆕 pergunta secreta

  @HiveField(5)
  final String? securityAnswer; // 🆕 resposta secreta

  ProfileModel({
    required this.id,
    required this.name,
    this.allowedVideoIds = const [],
    this.password,
    this.securityQuestion,
    this.securityAnswer,
  });

  ProfileModel copyWith({
    String? id,
    String? name,
    List<String>? allowedVideoIds,
    String? password,
    String? securityQuestion,
    String? securityAnswer,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      allowedVideoIds: allowedVideoIds ?? this.allowedVideoIds,
      password: password ?? this.password,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswer: securityAnswer ?? this.securityAnswer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'allowedVideoIds': allowedVideoIds,
      'password': password,
      'securityQuestion': securityQuestion,
      'securityAnswer': securityAnswer,
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'],
      name: map['name'],
      allowedVideoIds: List<String>.from(map['allowedVideoIds']),
      password: map['password'],
      securityQuestion: map['securityQuestion'],
      securityAnswer: map['securityAnswer'],
    );
  }

  hasPassword() {
    return password != null && password!.isNotEmpty;
  }
}
