import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../database/app_database.dart';

class ServicoSincronizacao {
  ServicoSincronizacao({required this.bancoDados});
  final BancoDeDados bancoDados;
  StreamSubscription<List<ConnectivityResult>>? _assinaturaConectividade;
  Future<void> iniciar({required Future<void> Function() aoReconectar}) async {
    _assinaturaConectividade = Connectivity().onConnectivityChanged.listen((
      resultados,
    ) async {
      if (resultados.any((r) => r != ConnectivityResult.none))
        await aoReconectar();
    });
  }

  Future<void> encerrar() async => _assinaturaConectividade?.cancel();
}
