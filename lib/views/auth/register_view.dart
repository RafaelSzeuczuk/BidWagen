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

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    senha.dispose();
    confirmacao.dispose();
    super.dispose();
  }

  Future<void> enviarFormulario() async {
    if (nome.text.trim().isEmpty || email.text.trim().isEmpty) {
      setState(() => erro = 'Preencha o nome e o e-mail.');
      return;
    }

    final requisitosPendentes = <String>[];

    if (senha.text.length < 6) {
      requisitosPendentes.add('pelo menos 6 caracteres');
    }

    if (!RegExp(r'[A-ZÀ-ÖØ-Þ]').hasMatch(senha.text)) {
      requisitosPendentes.add('uma letra maiúscula');
    }

    if (!RegExp(r'[a-zà-öø-ÿ]').hasMatch(senha.text)) {
      requisitosPendentes.add('uma letra minúscula');
    }

    if (!RegExp(r'[0-9]').hasMatch(senha.text)) {
      requisitosPendentes.add('um número');
    }

    if (!RegExp(r'[^A-Za-zÀ-ÖØ-öø-ÿ0-9\s]').hasMatch(senha.text)) {
      requisitosPendentes.add('um símbolo');
    }

    if (requisitosPendentes.isNotEmpty) {
      setState(() {
        erro = 'A senha precisa conter ${requisitosPendentes.join(', ')}.';
      });
      return;
    }

    if (senha.text != confirmacao.text) {
      setState(() => erro = 'As senhas não coincidem.');
      return;
    }

    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      await context.read<ServicoAutenticacao>().cadastrar(
            nome: nome.text,
            email: email.text,
            senha: senha.text,
          );

      if (mounted) Navigator.pop(context);
    } catch (excecao) {
      if (mounted) {
        setState(() {
          erro = context.read<ServicoAutenticacao>().mensagem(excecao);
        });
      }
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
              decoration: const InputDecoration(
                labelText: 'Nome completo',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: senha,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                hintText: 'Mínimo 6 caracteres, incluindo A, a, 1 e !',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: confirmacao,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar senha',
              ),
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