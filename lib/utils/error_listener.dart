import 'package:flutter/material.dart';

/// Verifica se um provider tem erro e exibe SnackBar.
/// Retorna true se havia erro.
bool showProviderError(
    BuildContext context, String? errorMessage, VoidCallback clearError) {
  if (errorMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        clearError();
      }
    });
    return true;
  }
  return false;
}
