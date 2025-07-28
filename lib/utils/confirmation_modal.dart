import 'package:flutter/material.dart';
import 'math_question.dart';
import '../models/profile_model.dart';

/// Verifica se deve mostrar o desafio matemático baseado na categoria
bool shouldShowMathChallenge(UserCategory? category) {
  // Se não tem categoria definida, mostrar o desafio (padrão para crianças)
  if (category == null) return true;
  // Usar a propriedade do enum
  return category.shouldShowMathChallenge;
}

Future<bool> showMathConfirmationModal(
    BuildContext context, String title, String textBtn,
    {UserCategory? userCategory}) async {
  // Verificar se deve mostrar o desafio matemático
  if (!shouldShowMathChallenge(userCategory)) {
    // Se não deve mostrar o desafio, mostrar confirmação simples
    return await showConfirmationDialog(
      context,
      title: title,
      content: 'Deseja continuar?',
      confirmText: textBtn,
    );
  }

  // Mostrar desafio matemático para crianças
  final question = generateRandomQuestion();
  final answerController = TextEditingController();
  bool isButtonEnabled = false;

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              void checkAnswer(String input) {
                final inputInt = int.tryParse(input);
                if (inputInt != null && inputInt == question.answer) {
                  setState(() => isButtonEnabled = true);
                } else {
                  setState(() => isButtonEnabled = false);
                }
              }

              return AlertDialog(
                title: Text(title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Resolva a conta para habilitar o botão:'),
                    const SizedBox(height: 8),
                    Text(
                      question.question,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: answerController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      onChanged: checkAnswer,
                      decoration: const InputDecoration(
                        labelText: 'Sua resposta',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: isButtonEnabled
                        ? () {
                            Navigator.of(context).pop(true);
                          }
                        : null,
                    child: Text(textBtn),
                  ),
                ],
              );
            },
          );
        },
      ) ??
      false;
}

Future<bool> showExitConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmação'),
      content: const Text('Deseja mesmo sair?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Não'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sim'),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmText = 'Confirmar',
  String cancelText = 'Cancelar',
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        ),
      ) ??
      false;
}
