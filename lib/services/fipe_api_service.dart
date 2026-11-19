import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/api_vehicle.dart';

class ExcecaoSemInternet implements Exception {
  const ExcecaoSemInternet();

  @override
  String toString() => 'Você está offline.';
}

class ServicoApiFipe {
  static const _urlBase = 'https://placas.app.br/api/v1';
  static const _agenteUsuario = 'BidWagen/1.0';
  String? _token;

  Future<http.Response> _postComTratamentoDeConexao(
    Uri url, {
    required Map<String, String> cabecalhos,
    String? corpo,
  }) async {
    try {
      return await http
          .post(url, headers: cabecalhos, body: corpo)
          .timeout(const Duration(seconds: 15));
    } on http.ClientException {
      throw const ExcecaoSemInternet();
    } on IOException {
      throw const ExcecaoSemInternet();
    } on TimeoutException {
      throw const ExcecaoSemInternet();
    }
  }

  Future<String> _obterToken() async {
    if (_token?.isNotEmpty == true) return _token!;
    final configurado = dotenv.env['PLACAS_API_TOKEN'];
    if (configurado?.isNotEmpty == true) {
      _token = configurado;
      return _token!;
    }
    final resposta = await _postComTratamentoDeConexao(
      Uri.parse('$_urlBase/authenticate'),
      cabecalhos: {
        'Content-Type': 'application/json',
        'User-Agent': _agenteUsuario
      },
      corpo: jsonEncode({
        'email': dotenv.env['PLACAS_API_EMAIL'],
        'password': dotenv.env['PLACAS_API_PASSWORD'],
      }),
    );
    if (resposta.statusCode < 200 || resposta.statusCode >= 300)
      throw Exception('Falha na autenticação da API de placas.');
    final dados = _converterParaMapa(jsonDecode(resposta.body));
    _token =
        (dados['token'] ?? dados['access_token'] ?? dados['jwt'])?.toString();
    if (_token == null || _token!.isEmpty)
      throw Exception('A API não retornou um token JWT.');
    return _token!;
  }

  Future<dynamic> _enviarRequisicaoPost(
      String caminhoRota, Map<String, dynamic> body) async {
    final token = await _obterToken();
    final resposta = await _postComTratamentoDeConexao(
      Uri.parse('$_urlBase$caminhoRota'),
      cabecalhos: {
        'Content-Type': 'application/json',
        'User-Agent': _agenteUsuario,
        'Authorization': 'Bearer $token',
      },
      corpo: jsonEncode(body),
    );
    if (resposta.statusCode < 200 || resposta.statusCode >= 300)
      throw Exception('API retornou HTTP ${resposta.statusCode}.');
    return jsonDecode(resposta.body);
  }

  Future<VeiculoDaApi> consultarPlaca(String placa) async {
    final decodificado = await _enviarRequisicaoPost('/placas/numero', {
      'placa': placa.replaceAll('-', '').trim().toLowerCase(),
    });
    final dadosVeiculoJson = _converterParaMapa(decodificado);
    final veiculo = VeiculoDaApi.aPartirDoJson(dadosVeiculoJson);

    // A API de placa não envia o preço FIPE diretamente. O endpoint /fipe/marca
    // retorna a tabela da marca, então filtramos o modelo e o ano retornados pela placa.
    try {
      final fipe = await _buscarDadosFipe(veiculo);
      return veiculo.comDadosFipe(fipe);
    } on ExcecaoSemInternet {
      rethrow;
    } catch (_) {
      // Os dados da placa continuam disponíveis mesmo se a tabela FIPE estiver indisponível.
      return veiculo;
    }
  }

  Future<Map<String, dynamic>?> _buscarDadosFipe(VeiculoDaApi veiculo) async {
    final marca = veiculo.marca?.trim();
    if (marca == null || marca.isEmpty) return null;
    final decodificado =
        await _enviarRequisicaoPost('/fipe/marca', {'marca': marca});
    final lista = decodificado is List
        ? decodificado
            .whereType<Map>()
            .map((elemento) => Map<String, dynamic>.from(elemento))
            .toList()
        : <Map<String, dynamic>>[];
    if (lista.isEmpty) return null;

    final modeloAlvo = _normalizar(veiculo.modelo ?? '');
    final anoAlvo = veiculo.ano;
    Map<String, dynamic>? melhor;
    var melhorPontuacao = -1.0;

    for (final elemento in lista) {
      final modeloCandidato = _normalizar(elemento['modelo']?.toString() ?? '');
      if (modeloCandidato.isEmpty) continue;
      final anoCandidato = int.tryParse(elemento['ano']?.toString() ?? '');
      var pontuacao = _pontuarModelos(modeloAlvo, modeloCandidato);
      if (anoAlvo != null && anoCandidato == anoAlvo) pontuacao += 4;
      if (anoAlvo != null && anoCandidato != null)
        pontuacao -= (anoCandidato - anoAlvo).abs() * .01;
      if (pontuacao > melhorPontuacao) {
        melhorPontuacao = pontuacao;
        melhor = elemento;
      }
    }
    return melhor;
  }

  double _pontuarModelos(String alvo, String candidato) {
    if (alvo.isEmpty || candidato.isEmpty) return 0;
    if (alvo == candidato) return 10;
    final palavrasAlvo =
        alvo.split(' ').where((palavra) => palavra.length > 1).toSet();
    final palavrasCandidatas =
        candidato.split(' ').where((palavra) => palavra.length > 1).toSet();
    final palavrasComuns = palavrasAlvo.intersection(palavrasCandidatas).length;
    var pontuacao = palavrasComuns.toDouble();
    if (candidato.contains(alvo) || alvo.contains(candidato)) pontuacao += 2;
    return pontuacao;
  }

  String _normalizar(String valor) {
    return valor
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúãõç ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Map<String, dynamic> _converterParaMapa(dynamic valor) {
    if (valor is Map<String, dynamic>) return valor;
    if (valor is Map) return Map<String, dynamic>.from(valor);
    throw Exception('Formato inesperado retornado pela API.');
  }
}
