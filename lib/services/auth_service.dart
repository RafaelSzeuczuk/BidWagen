import 'package:firebase_auth/firebase_auth.dart';

class ServicoAutenticacao {
  final FirebaseAuth _autenticacaoFirebase = FirebaseAuth.instance;
  Stream<User?> get alteracoesDeAutenticacao =>
      _autenticacaoFirebase.authStateChanges();
  User? get usuarioAtual => _autenticacaoFirebase.currentUser;
  Future<void> entrar(String email, String senha) => _autenticacaoFirebase
      .signInWithEmailAndPassword(email: email.trim(), password: senha);
  Future<void> cadastrar(
      {required String nome,
      required String email,
      required String senha}) async {
    final credencial = await _autenticacaoFirebase
        .createUserWithEmailAndPassword(email: email.trim(), password: senha);
    await credencial.user?.updateDisplayName(nome.trim());
  }

  Future<void> redefinirSenha(String email) =>
      _autenticacaoFirebase.sendPasswordResetEmail(email: email.trim());
  Future<void> sair() => _autenticacaoFirebase.signOut();
  String mensagem(Object erro) {
    if (erro is FirebaseAuthException) {
      switch (erro.code) {
        case 'invalid-credential':
        case 'wrong-password':
          return 'E-mail ou senha inválidos.';
        case 'email-already-in-use':
          return 'Este e-mail já está cadastrado.';
        case 'weak-password':
          return 'Use uma senha com pelo menos 6 caracteres.';
        case 'network-request-failed':
          return 'Sem internet. O login precisa de conexão.';
      }
    }
    return 'Não foi possível concluir a operação.';
  }
}
