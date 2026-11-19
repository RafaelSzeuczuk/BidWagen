import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../components/offline_notice.dart';
import '../components/primary_button.dart';
import '../models/api_vehicle.dart';
import '../services/auth_service.dart';
import '../services/fipe_api_service.dart';
import '../services/vehicle_repository.dart';

class TelaAgendamento extends StatefulWidget {
  const TelaAgendamento({super.key});
  @override
  State<TelaAgendamento> createState() => _EstadoTelaAgendamento();
}

class _EstadoTelaAgendamento extends State<TelaAgendamento> {
  final placa = TextEditingController();
  final endereco = TextEditingController();
  final observacoes = TextEditingController();
  final mapController = MapController();
  DateTime dataSelecionada = DateTime.now().add(const Duration(days: 1));
  LatLng pontoSelecionado = const LatLng(-15.793889, -47.882778);
  List<_LocalEncontrado> locais = [];
  VeiculoDaApi? veiculoDaApi;
  bool localizando = true;
  bool pesquisandoEndereco = false;
  bool pesquisandoVeiculo = false;
  bool salvando = false;

  String mensagemErroApi(Object erro) {
    if (erro is ExcecaoSemInternet ||
        erro is http.ClientException ||
        erro is IOException ||
        erro is TimeoutException) {
      return 'Você está offline.';
    }
    return erro.toString().replaceFirst('Exception: ', '');
  }

  void mostrarErroApi(Object erro) {
    final mensagem = mensagemErroApi(erro);
    ScaffoldMessenger.of(context).showSnackBar(
      mensagem == 'Você está offline.'
          ? avisoOfflineSnackBar()
          : SnackBar(content: Text(mensagem)),
    );
  }

  @override
  void initState() {
    super.initState();
    verificarConexaoMapa();
    localizarUsuario();
  }

  Future<void> verificarConexaoMapa() async {
    try {
      final conexoes = await Connectivity().checkConnectivity();
      if (!conexoes.any((resultado) => resultado != ConnectivityResult.none))
        mostrarAvisoOfflineMapa();
    } catch (_) {
      mostrarAvisoOfflineMapa();
    }
  }

  void mostrarAvisoOfflineMapa() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(avisoOfflineSnackBar());
    });
  }

  @override
  void dispose() {
    placa.dispose();
    endereco.dispose();
    observacoes.dispose();
    super.dispose();
  }

  Future<void> localizarUsuario() async {
    try {
      final posicao =
          await context.read<RepositorioVeiculos>().localizacao.posicaoAtual();
      final ponto = LatLng(posicao.latitude, posicao.longitude);
      if (!mounted) return;
      setState(() {
        pontoSelecionado = ponto;
        localizando = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) mapController.move(ponto, 16);
      });
    } catch (_) {
      if (mounted) setState(() => localizando = false);
    }
  }

  Future<void> buscarEndereco() async {
    final query = endereco.text.trim();
    if (query.length < 3) return;
    setState(() => pesquisandoEndereco = true);
    try {
      final conexoes = await Connectivity().checkConnectivity();
      if (!conexoes.any((resultado) => resultado != ConnectivityResult.none)) {
        throw const ExcecaoSemInternet();
      }
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'limit': '5',
        'q': query,
      });
      final resposta = await http.get(
        uri,
        headers: {'User-Agent': 'BidWagen/1.0 (Android app)'},
      ).timeout(const Duration(seconds: 15));
      if (resposta.statusCode != 200)
        throw Exception('Não foi possível pesquisar esse endereço.');
      final lista = (jsonDecode(resposta.body) as List)
          .map((elemento) =>
              _LocalEncontrado.aPartirDoJson(elemento as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => locais = lista);
      if (lista.isEmpty && mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum endereço encontrado.')),
        );
    } catch (erro) {
      if (mounted) mostrarErroApi(erro);
    } finally {
      if (mounted) setState(() => pesquisandoEndereco = false);
    }
  }

  void selecionarLocal(_LocalEncontrado local) {
    final ponto = LatLng(local.latitude, local.longitude);
    setState(() {
      pontoSelecionado = ponto;
      endereco.text = local.nome;
      locais = [];
    });
    mapController.move(ponto, 16);
  }

  Future<void> selecionarData() async {
    final data = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate: dataSelecionada,
    );
    if (data != null) setState(() => dataSelecionada = data);
  }

  Future<VeiculoDaApi?> buscarVeiculo() async {
    final valor = placa.text.trim();
    if (valor.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe uma placa válida antes de pesquisar.'),
        ),
      );
      return null;
    }
    setState(() => pesquisandoVeiculo = true);
    try {
      final resultado =
          await context.read<RepositorioVeiculos>().consultar(valor);
      if (mounted) setState(() => veiculoDaApi = resultado);
      return resultado;
    } catch (erro) {
      if (mounted) mostrarErroApi(erro);
      return null;
    } finally {
      if (mounted) setState(() => pesquisandoVeiculo = false);
    }
  }

  Future<void> salvar() async {
    if (placa.text.trim().length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a placa do veículo.')),
      );
      return;
    }
    final valorPlaca = placa.text.trim().toUpperCase();
    setState(() => salvando = true);
    try {
      final veiculo = veiculoDaApi ??
          await context.read<RepositorioVeiculos>().consultar(valorPlaca);
      if (mounted) setState(() => veiculoDaApi = veiculo);
      final usuario = context.read<ServicoAutenticacao>().usuarioAtual!;
      await context.read<RepositorioVeiculos>().salvarVisitaAgendada(
            idUsuario: usuario.uid,
            placa: valorPlaca,
            dataVisita: dataSelecionada,
            latitude: pontoSelecionado.latitude,
            longitude: pontoSelecionado.longitude,
            descricao:
                '${endereco.text.trim()}${observacoes.text.trim().isEmpty ? '' : '\n${observacoes.text.trim()}'}',
            veiculoDaApi: veiculo,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Visita agendada com sucesso.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (erro) {
      if (mounted) mostrarErroApi(erro);
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Agendar visita')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          children: [
            Text(
              'Onde será a visita?',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'Pesquise o endereço ou toque no mapa para marcar o local.',
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: placa,
                    readOnly: salvando || pesquisandoVeiculo,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() => veiculoDaApi = null),
                    onSubmitted: (_) => buscarVeiculo(),
                    decoration: const InputDecoration(
                      labelText: 'Placa do veículo',
                      prefixIcon: Icon(Icons.directions_car_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed:
                      pesquisandoVeiculo || salvando ? null : buscarVeiculo,
                  icon: pesquisandoVeiculo
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            if (veiculoDaApi != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  [veiculoDaApi!.marca, veiculoDaApi!.modelo]
                          .where((valor) => valor?.trim().isNotEmpty == true)
                          .join(' ')
                          .isEmpty
                      ? 'Modelo não localizado na API.'
                      : 'Veículo: ${[
                          veiculoDaApi!.marca,
                          veiculoDaApi!.modelo
                        ].where((valor) => valor?.trim().isNotEmpty == true).join(' ')}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: endereco,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => buscarEndereco(),
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar endereço',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: pesquisandoEndereco ? null : buscarEndereco,
                  icon: pesquisandoEndereco
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            if (locais.isNotEmpty)
              Card(
                child: Column(
                  children: locais
                      .map(
                        (local) => ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(
                            local.nome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => selecionarLocal(local),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: selecionarData,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                'Data: ${dataSelecionada.day.toString().padLeft(2, '0')}/${dataSelecionada.month.toString().padLeft(2, '0')}/${dataSelecionada.year}',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 340,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: pontoSelecionado,
                        initialZoom: 13,
                        onTap: (_, ponto) =>
                            setState(() => pontoSelecionado = ponto),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.bidwagen',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: pontoSelecionado,
                              width: 56,
                              height: 56,
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFFE02020),
                                size: 48,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: FloatingActionButton.small(
                        heroTag: 'current-location',
                        onPressed: localizarUsuario,
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFE02020),
                        child: localizando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Coordenadas: ${pontoSelecionado.latitude.toStringAsFixed(6)}, ${pontoSelecionado.longitude.toStringAsFixed(6)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: observacoes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Informações prévias',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 24),
            BotaoPrimario(
              label: 'Salvar agendamento',
              onPressed: salvando || pesquisandoVeiculo ? null : salvar,
              carregando: salvando || pesquisandoVeiculo,
            ),
          ],
        ),
      );
}

class _LocalEncontrado {
  const _LocalEncontrado({
    required this.nome,
    required this.latitude,
    required this.longitude,
  });
  final String nome;
  final double latitude;
  final double longitude;
  factory _LocalEncontrado.aPartirDoJson(Map<String, dynamic> json) =>
      _LocalEncontrado(
        nome: json['display_name'] as String? ?? 'Endereço selecionado',
        latitude: double.parse(json['lat'].toString()),
        longitude: double.parse(json['lon'].toString()),
      );
}
