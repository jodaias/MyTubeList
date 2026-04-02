import 'dart:math';
import '../constants/app_constants.dart';

class MathQuestion {
  final int a;
  final int b;

  MathQuestion(this.a, this.b);

  int get answer => a * b;

  String get question => '$a * $b = ?';
}

MathQuestion generateRandomQuestion() {
  final random = Random();
  final a = random.nextInt(AppConstants.mathQuestionRange) +
      AppConstants.mathQuestionMin;
  final b = random.nextInt(AppConstants.mathQuestionRange) +
      AppConstants.mathQuestionMin;
  return MathQuestion(a, b);
}
