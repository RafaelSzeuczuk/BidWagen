import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/app_logo.dart';
import '../../components/primary_button.dart';
import '../../services/auth_service.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _EstadoTelaCadastro();
}

class _EstadoTelaCadastro extends State<TelaCadastro> {
  final nome = TextEditingController();
  final email = TextEditingController();
  final senha = TextEditingController();
  final confirmacao = TextEditingController();
  bool carregando = false;
  String? erro;

  Future<void> enviarFormulario() async {
    if (nome.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        senha.text.length < 6) {
      setState(
        () => erro =
            'Preencha os campos e use uma senha com 6 ou mais caracteres.',
      );
      return;
    }
    if (senha.text != confirmacao.text) {
      setState(() => erro = 'As senhas não coincidem.');
      return;
    }
    setState(() => carregando = true);
    try {
      await context.read<ServicoAutenticacao>().cadastrar(
            nome: nome.text,
            email: email.text,
            senha: senha.text,
          );
      if (mounted) Navigator.pop(context);
    } catch (excecao) {
      setState(
          () => erro = context.read<ServicoAutenticacao>().mensagem(excecao));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const LogotipoAplicativo(tamanho: 90),
            TextField(
              controller: nome,
              decoration: const InputDecoration(labelText: 'Nome completo'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: senha,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: confirmacao,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar senha'),
            ),
            if (erro != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  erro!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 14),
            BotaoPrimario(
              label: 'Cadastrar',
              onPressed: enviarFormulario,
              carregando: carregando,
            ),
          ],
        ),
      ),
    );
  }
}
