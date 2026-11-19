import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'database/app_database.dart';
import 'services/auth_service.dart';
import 'services/fipe_api_service.dart';
import 'services/location_service.dart';
import 'services/sync_service.dart';
import 'services/vehicle_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final bancoDados = BancoDeDados();
  final repositorio = RepositorioVeiculos(
    bancoDados: bancoDados,
    servicoFipe: ServicoApiFipe(),
    localizacao: ServicoLocalizacao(),
  );
  final servicoSincronizacao = ServicoSincronizacao(bancoDados: bancoDados);
  await servicoSincronizacao.iniciar(
    aoReconectar: () async {
      final usuario = ServicoAutenticacao().usuarioAtual;
      if (usuario != null) await repositorio.sincronizar(usuario.uid);
    },
  );

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: bancoDados),
        Provider.value(value: repositorio),
        Provider.value(value: servicoSincronizacao),
        Provider(create: (_) => ServicoAutenticacao()),
      ],
      child: const AplicativoBidWagen(),
    ),
  );
}
