import 'package:hive/hive.dart';
import 'package:my_tube_list/models/video_list_model.dart';

part 'profile_model.g.dart';

@HiveType(typeId: 3)
enum UserCategory {
  @HiveField(0)
  toddler('1-5 anos', 'Toddler'),
  @HiveField(1)
  child('6-10 anos', 'Child'),
  @HiveField(2)
  preteen('11-17 anos', 'Preteen'),
  @HiveField(3)
  youngAdult('18-30 anos', 'Young_Adult'),
  @HiveField(4)
  adult('31-45 anos', 'Adult'),
  @HiveField(5)
  middleAge('46-60 anos', 'Middle_Age'),
  @HiveField(6)
  senior('60+ anos', 'Senior');

  const UserCategory(this.displayName, this.firebaseValue);

  final String displayName;
  final String firebaseValue;

  /// Retorna a categoria baseada na idade
  static UserCategory fromAge(int age) {
    if (age >= 1 && age <= 5) return UserCategory.toddler;
    if (age >= 6 && age <= 10) return UserCategory.child;
    if (age >= 11 && age <= 17) return UserCategory.preteen;
    if (age >= 18 && age <= 30) return UserCategory.youngAdult;
    if (age >= 31 && age <= 45) return UserCategory.adult;
    if (age >= 46 && age <= 60) return UserCategory.middleAge;
    if (age >= 61) return UserCategory.senior;
    return UserCategory.adult; // Padrão
  }

  /// Verifica se deve mostrar desafio matemático
  bool get shouldShowMathChallenge {
    return this == UserCategory.toddler || this == UserCategory.child;
  }
}

@HiveType(typeId: 1)
class ProfileModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(6)
  final String username;

  @HiveField(2)
  final List<VideoListModel> videoLists;

  @HiveField(3)
  final String? password;

  @HiveField(4)
  final String? securityQuestion; // 🆕 pergunta secreta

  @HiveField(5)
  final String? securityAnswer; // 🆕 resposta secreta

  @HiveField(7)
  final UserCategory? category; // 🆕 categoria do usuário

  ProfileModel({
    required this.id,
    required this.name,
    required this.username,
    this.category = UserCategory.adult,
    this.videoLists = const [],
    this.password,
    this.securityQuestion,
    this.securityAnswer,
  });

  ProfileModel copyWith({
    String? id,
    String? name,
    String? username,
    List<VideoListModel>? videoLists,
    String? password,
    String? securityQuestion,
    String? securityAnswer,
    UserCategory? category,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      videoLists: videoLists ?? this.videoLists,
      password: password ?? this.password,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswer: securityAnswer ?? this.securityAnswer,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'videoLists': videoLists,
      'password': password,
      'securityQuestion': securityQuestion,
      'securityAnswer': securityAnswer,
      'category': category,
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'],
      name: map['name'],
      username: map['username'],
      videoLists: List<VideoListModel>.from(map['videoLists']),
      password: map['password'],
      securityQuestion: map['securityQuestion'],
      securityAnswer: map['securityAnswer'],
      category: parseCategory(map['category']),
    );
  }

  /// Converte string do Firebase para enum UserCategory
  static UserCategory? parseCategory(String? categoryString) {
    if (categoryString == null) return null;

    try {
      return UserCategory.values.firstWhere(
        (category) => category.firebaseValue == categoryString,
        orElse: () => UserCategory.adult,
      );
    } catch (e) {
      return UserCategory.adult; // Padrão
    }
  }

  hasPassword() {
    return password != null && password!.isNotEmpty;
  }
}
