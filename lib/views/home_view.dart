import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/app_logo.dart';
import '../components/vehicle_card.dart';
import '../models/vehicle_record.dart';
import '../services/auth_service.dart';
import '../services/vehicle_repository.dart';
import 'calendar_view.dart';
import 'schedule_view.dart';
import 'vehicle_form_view.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _EstadoTelaInicial();
}

class _EstadoTelaInicial extends State<TelaInicial> {
  List<RegistroVeiculo> itens = [];
  bool carregando = true;

  List<RegistroVeiculo> get avaliacoes =>
      itens.where((elemento) => elemento.dataVisita == null).toList();

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final usuario = context.read<ServicoAutenticacao>().usuarioAtual;
    if (usuario == null) return;
    setState(() => carregando = true);
    itens = await context
        .read<RepositorioVeiculos>()
        .listarVeiculosLocais(usuario.uid);
    if (mounted) setState(() => carregando = false);
  }

  Future<void> remover(RegistroVeiculo veiculo) async {
    await context.read<RepositorioVeiculos>().remover(veiculo);
    await carregar();
  }

  void abrirTela(Widget tela) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => tela),
    ).then((_) => carregar());
  }

  Widget cartaoAcao({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    required bool contornado,
  }) {
    final esquema = Theme.of(context).colorScheme;
    return Material(
      color: contornado ? esquema.surface : esquema.primary,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: contornado
                  ? esquema.primary.withOpacity(.8)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: contornado
                      ? esquema.primaryContainer
                      : Colors.white.withOpacity(.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: contornado ? esquema.onPrimaryContainer : Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: contornado
                            ? Colors.white70
                            : Colors.white.withOpacity(.82),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: contornado ? Colors.white70 : Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget cartaoBoasVindas(String saudacao) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Row(
          children: [
            const LogotipoAplicativo(tamanho: 54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, $saudacao',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Avalie com dados. Negocie melhor.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget secaoRegistros() {
    if (carregando)
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    if (avaliacoes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 36,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 10),
              const Text(
                'Nenhum registro ainda.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Use uma das ações acima para começar.',
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: avaliacoes
          .map(
            (veiculo) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: CartaoVeiculo(
                veiculo: veiculo,
                aoEditar: () => abrirTela(
                    TelaFormularioVeiculo(registroExistente: veiculo)),
                aoExcluir: () => remover(veiculo),
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.read<ServicoAutenticacao>().usuarioAtual;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BidWagen',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -.3),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: IconButton(
              tooltip: 'Agenda',
              onPressed: () => abrirTela(const TelaCalendario()),
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Sair',
              onPressed: () => context.read<ServicoAutenticacao>().sair(),
              icon: const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: carregar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            cartaoBoasVindas(
                usuario?.displayName ?? usuario?.email ?? 'avaliador'),
            const SizedBox(height: 24),
            Text(
              'Ações rápidas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            cartaoAcao(
              icon: Icons.analytics_outlined,
              title: 'Avaliar veículo',
              subtitle: 'Consulte a placa, a FIPE e a oferta sugerida.',
              onPressed: () => abrirTela(const TelaFormularioVeiculo()),
              contornado: false,
            ),
            const SizedBox(height: 12),
            cartaoAcao(
              icon: Icons.location_on_outlined,
              title: 'Agendar visita',
              subtitle: 'Escolha a data e marque o local no mapa.',
              onPressed: () => abrirTela(const TelaAgendamento()),
              contornado: true,
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Text(
                  'Avaliações recentes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${avaliacoes.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            secaoRegistros(),
          ],
        ),
      ),
    );
  }
}
