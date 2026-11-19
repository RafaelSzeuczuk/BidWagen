import 'package:flutter/material.dart';

class BotaoPrimario extends StatelessWidget {
  const BotaoPrimario({
    super.key,
    required this.label,
    required this.onPressed,
    this.carregando = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool carregando;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: carregando ? null : onPressed,
          child: carregando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(label),
        ),
      );
}
