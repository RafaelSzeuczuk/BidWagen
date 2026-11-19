import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/vehicle_record.dart';
import '../services/currency_formatter.dart';

class CartaoVeiculo extends StatelessWidget {
  const CartaoVeiculo({
    super.key,
    required this.veiculo,
    required this.aoEditar,
    required this.aoExcluir,
  });

  final RegistroVeiculo veiculo;
  final VoidCallback aoEditar;
  final VoidCallback aoExcluir;

  @override
  Widget build(BuildContext context) {
    final tituloVeiculo =
        '${veiculo.marca ?? 'Veículo'} ${veiculo.modelo ?? ''}'.trim();
    final corSuave = Theme.of(context).colorScheme.onSurface.withOpacity(.68);
    final possuiFoto = veiculo.caminhoImagem != null &&
        File(veiculo.caminhoImagem!).existsSync();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: possuiFoto
                      ? Image.file(
                          File(veiculo.caminhoImagem!),
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 54,
                          height: 54,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.directions_car_filled_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tituloVeiculo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        veiculo.placa,
                        style: TextStyle(
                          color: corSuave,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  padding: const EdgeInsets.all(8),
                  onSelected: (value) =>
                      value == 'edit' ? aoEditar() : aoExcluir(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar avaliação'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Excluir avaliação'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _EtiquetaInformacao(
                  icone: Icons.speed_outlined,
                  label: '${veiculo.quilometragem} km',
                ),
                _EtiquetaInformacao(
                  icone: Icons.shield_outlined,
                  label: '${veiculo.conservacao}% conservação',
                ),
                if (veiculo.dataVisita != null)
                  _EtiquetaInformacao(
                    icone: Icons.event_outlined,
                    label: DateFormat('dd/MM/yyyy').format(veiculo.dataVisita!),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              height: 1,
              color: Theme.of(context).colorScheme.outline.withOpacity(.35),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ValorCalculado(
                    label: 'Referência FIPE',
                    value: 'R\$ ${formatarValorEmReais(veiculo.valorFipe)}',
                    corSuave: corSuave,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _ValorCalculado(
                    label: 'Oferta sugerida',
                    value:
                        'R\$ ${formatarValorEmReais(veiculo.ofertaSugerida)}',
                    accent: true,
                    corSuave: corSuave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EtiquetaInformacao extends StatelessWidget {
  const _EtiquetaInformacao({required this.icone, required this.label});
  final IconData icone;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone,
                size: 16, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}

class _ValorCalculado extends StatelessWidget {
  const _ValorCalculado({
    required this.label,
    required this.value,
    required this.corSuave,
    this.accent = false,
  });
  final String label;
  final String value;
  final Color corSuave;
  final bool accent;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: corSuave, fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color:
                  accent ? Theme.of(context).colorScheme.primary : Colors.white,
            ),
          ),
        ],
      );
}
