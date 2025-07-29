import 'dart:math';

class MathQuestion {
  final int a;
  final int b;

  MathQuestion(this.a, this.b);

  int get answer => a * b;

  String get question => '$a * $b = ?';
}

MathQuestion generateRandomQuestion() {
  final random = Random();
  final a = random.nextInt(8) + 2;
  final b = random.nextInt(8) + 2;
  return MathQuestion(a, b);
}
