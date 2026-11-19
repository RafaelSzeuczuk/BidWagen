import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/offline_notice.dart';
import '../components/primary_button.dart';
import '../models/api_vehicle.dart';
import '../models/vehicle_record.dart';
import '../services/auth_service.dart';
import '../services/currency_formatter.dart';
import '../services/fipe_api_service.dart';
import '../services/vehicle_repository.dart';

class TelaFormularioVeiculo extends StatefulWidget {
  const TelaFormularioVeiculo({super.key, this.registroExistente});
  final RegistroVeiculo? registroExistente;
  @override
  State<TelaFormularioVeiculo> createState() => _EstadoTelaFormularioVeiculo();
}

class _EstadoTelaFormularioVeiculo extends State<TelaFormularioVeiculo> {
  final formulario = GlobalKey<FormState>();
  late final TextEditingController placa, quilometragem, conservacao, descricao;
  VeiculoDaApi? veiculoDaApi;
  String? caminhoImagem;
  bool pesquisando = false;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    final veiculo = widget.registroExistente;
    placa = TextEditingController(text: veiculo?.placa ?? '');
    quilometragem =
        TextEditingController(text: '${veiculo?.quilometragem ?? 0}');
    conservacao = TextEditingController(text: '${veiculo?.conservacao ?? 90}');
    descricao = TextEditingController(text: veiculo?.descricao ?? '');
    caminhoImagem = veiculo?.caminhoImagem;
  }

  @override
  void dispose() {
    placa.dispose();
    quilometragem.dispose();
    conservacao.dispose();
    descricao.dispose();
    super.dispose();
  }

  Future<void> buscarVeiculo() async {
    if (placa.text.trim().length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite uma placa válida antes de pesquisar.'),
        ),
      );
      return;
    }
    setState(() => pesquisando = true);
    try {
      veiculoDaApi =
          await context.read<RepositorioVeiculos>().consultar(placa.text);
      if (mounted) setState(() {});
    } catch (erro) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          erro is ExcecaoSemInternet
              ? avisoOfflineSnackBar()
              : SnackBar(
                  content: Text(
                    erro.toString().replaceFirst('Exception: ', ''),
                  ),
                ),
        );
    } finally {
      if (mounted) setState(() => pesquisando = false);
    }
  }

  Future<void> selecionarImagem() async {
    caminhoImagem =
        await context.read<RepositorioVeiculos>().selecionarImagem();
    if (mounted) setState(() {});
  }

  double get descontoConservacao {
    final valor = int.tryParse(conservacao.text) ?? 100;
    if (valor >= 95) return .04;
    if (valor >= 90) return .10;
    if (valor >= 80) return .22;
    if (valor >= 70) return .35;
    if (valor >= 60) return .48;
    if (valor >= 50) return .60;
    return .65;
  }

  double get descontoQuilometragem {
    final valor = int.tryParse(quilometragem.text) ?? 0;
    if (valor < 50000) return .05;
    if (valor < 100000) return .12;
    if (valor < 150000) return .18;
    if (valor < 200000) return .24;
    if (valor < 250000) return .30;
    if (valor < 300000) return .40;
    return .45;
  }

  Widget previsualizacaoOferta() {
    final fipe =
        veiculoDaApi?.valorFipe ?? widget.registroExistente?.valorFipe ?? 0;
    if (fipe <= 0) return const SizedBox.shrink();
    final desconto =
        (descontoConservacao + descontoQuilometragem).clamp(0.0, .75);
    final oferta = fipe * (1 - desconto);
    return Card(
      margin: const EdgeInsets.only(top: 18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Oferta sugerida',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 5),
            Text(
              'R\$ ${formatarValorEmReais(oferta)}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Desconto aplicado: ${(desconto * 100).toStringAsFixed(0)}%  •  FIPE: R\$ ${formatarValorEmReais(fipe)}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> salvar() async {
    if (!(formulario.currentState?.validate() ?? false)) return;
    setState(() => salvando = true);
    try {
      final repositorio = context.read<RepositorioVeiculos>();
      final usuario = context.read<ServicoAutenticacao>().usuarioAtual!;
      if (widget.registroExistente == null) {
        final registro = await repositorio.preparar(
          idUsuario: usuario.uid,
          placa: placa.text.trim(),
          conservacao: int.parse(conservacao.text),
          quilometragem: int.parse(quilometragem.text),
          caminhoImagem: caminhoImagem,
          veiculoDaApi: veiculoDaApi,
          descricao: descricao.text.trim(),
        );
        await repositorio.salvar(registro);
      } else {
        await repositorio.atualizar(
          widget.registroExistente!.comAlteracoes(
            placa: placa.text.trim(),
            quilometragem: int.parse(quilometragem.text),
            conservacao: int.parse(conservacao.text),
            descricao: descricao.text.trim(),
            caminhoImagem: caminhoImagem,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (erro) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(erro.toString().replaceFirst('Exception: ', '')),
          ),
        );
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  Widget tituloSecao(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white60)),
          ],
        ),
      );

  String rotuloCampo(String key) {
    const labels = {
      'ano_fabricacao': 'Ano de fabricação',
      'ano_modelo': 'Ano do modelo',
      'placa_modelo_antigo': 'Placa modelo antigo',
      'placa_modelo_novo': 'Placa modelo novo',
      'sub_segmento': 'Subsegmento',
      'tipo_veiculo': 'Tipo de veículo',
      'uf_placa': 'UF da placa',
      'quantidade_passageiro': 'Quantidade de passageiros',
      'capacidade_carga': 'Capacidade de carga',
      'cap_maxima_tracao': 'Capacidade máxima de tração',
      'peso_bruto_total': 'Peso bruto total',
      'codigo_fipe': 'Código FIPE',
      'codigo_modelo': 'Código do modelo',
      'codigo_marca': 'Código da marca',
      'codigo_combustivel': 'Código do combustível',
    };
    if (labels.containsKey(key)) return labels[key]!;
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (palavra) => palavra.isEmpty
              ? palavra
              : '${palavra[0].toUpperCase()}${palavra.substring(1)}',
        )
        .join(' ');
  }

  Widget cartaoInformacoesApi(VeiculoDaApi dados) {
    final entradas = dados.detalhes.entries.toList();
    return Card(
      margin: const EdgeInsets.only(top: 14, bottom: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExpansionTile(
              initiallyExpanded: true,
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Informações completas da API',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${entradas.length} campos retornados'),
              children: entradas
                  .map(
                    (entrada) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              rotuloCampo(entrada.key),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 6,
                            child: Text(
                              entrada.value,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const Divider(height: 18),
            Row(
              children: [
                Icon(
                  Icons.currency_exchange,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  dados.valorFipe != null && dados.valorFipe! > 0
                      ? 'FIPE: R\$ ${formatarValorEmReais(dados.valorFipe!)}'
                      : 'FIPE não localizada',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: dados.valorFipe != null && dados.valorFipe! > 0
                        ? Theme.of(context).colorScheme.primary
                        : Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            if (dados.codigoFipe != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Código FIPE: ${dados.codigoFipe}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dados = veiculoDaApi;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.registroExistente == null
              ? 'Avaliar veículo'
              : 'Editar avaliação',
        ),
      ),
      body: Form(
        key: formulario,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            tituloSecao(
              'Identificação',
              'Consulte os dados completos pela placa.',
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: placa,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Placa',
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    validator: (valor) =>
                        valor == null || valor.trim().length < 7
                            ? 'Informe a placa'
                            : null,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 58,
                  child: IconButton.filled(
                    onPressed: pesquisando ? null : buscarVeiculo,
                    icon: pesquisando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                  ),
                ),
              ],
            ),
            if (dados != null) cartaoInformacoesApi(dados),
            const SizedBox(height: 8),
            tituloSecao(
              'Avaliação comercial',
              'Informe os dados para calcular a oferta.',
            ),
            TextFormField(
              controller: conservacao,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Conservação (%)',
                prefixIcon: Icon(Icons.health_and_safety_outlined),
              ),
              validator: (valor) {
                final number = int.tryParse(valor ?? '');
                return number == null || number < 0 || number > 100
                    ? 'Use um valor entre 0 e 100'
                    : null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: quilometragem,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Quilometragem (km)',
                prefixIcon: Icon(Icons.speed),
              ),
              validator: (valor) => int.tryParse(valor ?? '') == null
                  ? 'Informe a quilometragem'
                  : null,
            ),
            const SizedBox(height: 14),
            previsualizacaoOferta(),
            const SizedBox(height: 14),
            TextFormField(
              controller: descricao,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Observações',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 24),
            tituloSecao(
              'Imagem do veículo',
              'A foto fica armazenada localmente no Android.',
            ),
            OutlinedButton.icon(
              onPressed: selecionarImagem,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(
                caminhoImagem == null ? 'Tirar foto do veículo' : 'Trocar foto',
              ),
            ),
            if (caminhoImagem != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(caminhoImagem!),
                    height: 190,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 28),
            BotaoPrimario(
              label: 'Salvar avaliação',
              onPressed: salvar,
              carregando: salvando,
            ),
          ],
        ),
      ),
    );
  }
}
