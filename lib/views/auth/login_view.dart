import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/app_logo.dart';
import '../../components/primary_button.dart';
import '../../services/auth_service.dart';
import 'forgot_password_view.dart';
import 'register_view.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _EstadoTelaLogin();
}

class _EstadoTelaLogin extends State<TelaLogin> {
  final email = TextEditingController();
  final senha = TextEditingController();
  bool carregando = false;
  String? erro;

  Future<void> enviarFormulario() async {
    if (email.text.trim().isEmpty || senha.text.isEmpty) {
      setState(() => erro = 'Informe e-mail e senha.');
      return;
    }
    setState(() => carregando = true);
    try {
      await context.read<ServicoAutenticacao>().entrar(email.text, senha.text);
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  const LogotipoAplicativo(tamanho: 130),
                  const SizedBox(height: 12),
                  const Text(
                    'BidWagen',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Avalie melhor. Negocie com segurança.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 34),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: senha,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (erro != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        erro!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  const SizedBox(height: 20),
                  BotaoPrimario(
                    label: 'Entrar',
                    onPressed: enviarFormulario,
                    carregando: carregando,
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TelaRecuperarSenha(),
                      ),
                    ),
                    child: const Text('Esqueci minha senha'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TelaCadastro()),
                    ),
                    child: const Text('Ainda não tenho conta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
