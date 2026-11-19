import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/api_vehicle.dart';
import '../models/vehicle_record.dart';
import 'fipe_api_service.dart';
import 'location_service.dart';

class RepositorioVeiculos {
  RepositorioVeiculos({
    required this.bancoDados,
    required this.servicoFipe,
    required this.localizacao,
  });

  final BancoDeDados bancoDados;
  final ServicoApiFipe servicoFipe;
  final ServicoLocalizacao localizacao;
  final FirebaseFirestore _bancoFirebase = FirebaseFirestore.instance;
  final Uuid _geradorIdentificadores = const Uuid();

  Future<List<RegistroVeiculo>> listarVeiculosLocais(String idUsuario) =>
      bancoDados.veiculos(idUsuario);
  Future<VeiculoDaApi> consultar(String placa) async {
    final conexoes = await Connectivity().checkConnectivity();
    if (!conexoes.any((resultado) => resultado != ConnectivityResult.none)) {
      throw const ExcecaoSemInternet();
    }
    return servicoFipe.consultarPlaca(placa);
  }

  Future<String?> selecionarImagem() async => (await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
      ))
          ?.path;

  Future<RegistroVeiculo> preparar({
    required String idUsuario,
    required String placa,
    required int conservacao,
    required int quilometragem,
    String? caminhoImagem,
    VeiculoDaApi? veiculoDaApi,
    DateTime? dataVisita,
    String descricao = '',
  }) async {
    return RegistroVeiculo(
      id: _geradorIdentificadores.v4(),
      idUsuario: idUsuario,
      placa: placa,
      conservacao: conservacao,
      quilometragem: quilometragem,
      caminhoImagem: caminhoImagem,
      marca: veiculoDaApi?.marca,
      modelo: veiculoDaApi?.modelo,
      ano: veiculoDaApi?.ano,
      combustivel: veiculoDaApi?.combustivel,
      cor: veiculoDaApi?.cor,
      codigoFipe: veiculoDaApi?.codigoFipe,
      valorFipe: veiculoDaApi?.valorFipe ?? 0,
      dataVisita: dataVisita,
      descricao: descricao,
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );
  }

  Future<void> salvar(RegistroVeiculo registro) async {
    await bancoDados.salvarVeiculo(registro);
    await _tentarSincronizar(registro.idUsuario);
  }

  Future<void> salvarVisitaAgendada({
    required String idUsuario,
    required String placa,
    required DateTime dataVisita,
    required double latitude,
    required double longitude,
    String descricao = '',
    VeiculoDaApi? veiculoDaApi,
  }) async {
    final registro = RegistroVeiculo(
      id: _geradorIdentificadores.v4(),
      idUsuario: idUsuario,
      placa: placa,
      marca: veiculoDaApi?.marca,
      modelo: veiculoDaApi?.modelo,
      ano: veiculoDaApi?.ano,
      combustivel: veiculoDaApi?.combustivel,
      cor: veiculoDaApi?.cor,
      codigoFipe: veiculoDaApi?.codigoFipe,
      valorFipe: veiculoDaApi?.valorFipe ?? 0,
      dataVisita: dataVisita,
      latitude: latitude,
      longitude: longitude,
      descricao: descricao,
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );
    await salvar(registro);
  }

  Future<void> atualizar(RegistroVeiculo registro) async {
    final alterado = registro.comAlteracoes(
        sincronizado: false, atualizadoEm: DateTime.now());
    await bancoDados.atualizarVeiculo(alterado);
    await _tentarSincronizar(registro.idUsuario);
  }

  Future<void> remover(RegistroVeiculo registro) async {
    await bancoDados.adicionarNaFila(
      id: _geradorIdentificadores.v4(),
      idUsuario: registro.idUsuario,
      idRemoto: registro.idRemoto ?? registro.id,
      operacao: 'delete',
      payload: registro.id,
    );
    await bancoDados.excluirVeiculo(registro.id);
    await _tentarSincronizar(registro.idUsuario);
  }

  Future<void> sincronizar(String idUsuario) => _tentarSincronizar(idUsuario);

  Future<void> _tentarSincronizar(String idUsuario) async {
    final conectado = (await Connectivity().checkConnectivity()).any(
      (resultado) => resultado != ConnectivityResult.none,
    );
    if (!conectado) return;

    final pendentes = await bancoDados.pendentes(idUsuario);
    for (final elemento in pendentes) {
      try {
        final referencia = _bancoFirebase
            .collection('users')
            .doc(idUsuario)
            .collection('vehicles')
            .doc(elemento.id);
        await referencia.set(elemento.paraFirestore(), SetOptions(merge: true));
        // Mantemos o cache local para a lista e para a foto local do Android.
        await bancoDados.atualizarVeiculo(
          elemento.comAlteracoes(idRemoto: elemento.id, sincronizado: true),
        );
      } catch (_) {
        // O registro continua pendente para a próxima tentativa online.
      }
    }

    final fila = await bancoDados.fila(idUsuario);
    for (final operacao in fila) {
      if (operacao['operation'] == 'delete') {
        final idRemoto =
            operacao['remoteId'] as String? ?? operacao['entityId'] as String?;
        if (idRemoto != null) {
          try {
            await _bancoFirebase
                .collection('users')
                .doc(idUsuario)
                .collection('vehicles')
                .doc(idRemoto)
                .delete();
          } catch (_) {
            continue;
          }
        }
      }
      await bancoDados.removerDaFila(operacao['id'] as String);
    }
  }
}
