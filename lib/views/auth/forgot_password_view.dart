import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/primary_button.dart';
import '../../services/auth_service.dart';

class TelaRecuperarSenha extends StatefulWidget {
  const TelaRecuperarSenha({super.key});

  @override
  State<TelaRecuperarSenha> createState() => _EstadoTelaRecuperarSenha();
}

class _EstadoTelaRecuperarSenha extends State<TelaRecuperarSenha> {
  final email = TextEditingController();
  bool carregando = false;
  String? mensagem;

  Future<void> enviarFormulario() async {
    if (email.text.trim().isEmpty) {
      setState(() => mensagem = 'Informe seu e-mail.');
      return;
    }
    setState(() => carregando = true);
    try {
      await context.read<ServicoAutenticacao>().redefinirSenha(email.text);
      setState(() => mensagem = 'Solicitação enviada. Confira seu e-mail.');
    } catch (excecao) {
      setState(() =>
          mensagem = context.read<ServicoAutenticacao>().mensagem(excecao));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 18),
            BotaoPrimario(
              label: 'Enviar link',
              onPressed: enviarFormulario,
              carregando: carregando,
            ),
            if (mensagem != null)
              Padding(
                  padding: const EdgeInsets.all(16), child: Text(mensagem!)),
          ],
        ),
      ),
    );
  }
}
