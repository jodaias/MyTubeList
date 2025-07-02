import 'package:flutter/material.dart';
import 'math_question.dart';

Future<bool> showMathConfirmationModal(
    BuildContext context, String title, String textBtn) async {
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
                        ? () => Navigator.of(context).pop(true)
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
