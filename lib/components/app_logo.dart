import 'package:flutter/material.dart';

class LogotipoAplicativo extends StatelessWidget {
  const LogotipoAplicativo({super.key, this.tamanho = 96});
  final double tamanho;
  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/logo.png',
        width: tamanho,
        height: tamanho,
        fit: BoxFit.contain,
      );
}
