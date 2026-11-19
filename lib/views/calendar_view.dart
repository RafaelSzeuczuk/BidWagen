import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../components/offline_notice.dart';
import '../models/vehicle_record.dart';
import '../services/auth_service.dart';
import '../services/vehicle_repository.dart';

class TelaCalendario extends StatefulWidget {
  const TelaCalendario({super.key});
  @override
  State<TelaCalendario> createState() => _EstadoTelaCalendario();
}

class _EstadoTelaCalendario extends State<TelaCalendario> {
  DateTime focado = DateTime.now();
  DateTime selecionado = DateTime.now();
  List<RegistroVeiculo> itens = [];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final usuario = context.read<ServicoAutenticacao>().usuarioAtual;
    if (usuario != null)
      itens = await context
          .read<RepositorioVeiculos>()
          .listarVeiculosLocais(usuario.uid);
    if (mounted) setState(() {});
  }

  List<RegistroVeiculo> visitasDoDia(DateTime data) => itens.where((veiculo) {
        final visita = veiculo.dataVisita;
        return visita != null &&
            visita.year == data.year &&
            visita.month == data.month &&
            visita.day == data.day;
      }).toList();

  void abrirVisita(RegistroVeiculo visita) {
    if (visita.latitude == null || visita.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta visita não possui uma localização salva.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TelaMapaVisita(visita: visita)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Agenda de visitas')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TableCalendar<RegistroVeiculo>(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2035),
              focusedDay: focado,
              selectedDayPredicate: (data) => isSameDay(data, selecionado),
              onDaySelected: (selecao, foco) => setState(() {
                selecionado = selecao;
                focado = foco;
              }),
              eventLoader: visitasDoDia,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
              ),
              calendarFormat: CalendarFormat.month,
              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Color(0xFFFFB52E),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFFFFB52E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Visitas em ${selecionado.day}/${selecionado.month}/${selecionado.year}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ...visitasDoDia(selecionado).map((veiculo) {
              final modelo = [
                veiculo.marca,
                veiculo.modelo,
              ].where((valor) => valor?.trim().isNotEmpty == true).join(' ');
              return Card(
                child: ListTile(
                  onTap: () => abrirVisita(veiculo),
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(veiculo.placa),
                  subtitle: Text(
                    '${modelo.isEmpty ? 'Modelo não informado' : modelo}\nToque para abrir o mapa',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.map_outlined),
                ),
              );
            }),
          ],
        ),
      );
}

class TelaMapaVisita extends StatefulWidget {
  const TelaMapaVisita({super.key, required this.visita});
  final RegistroVeiculo visita;

  @override
  State<TelaMapaVisita> createState() => _EstadoTelaMapaVisita();
}

class _EstadoTelaMapaVisita extends State<TelaMapaVisita> {
  @override
  void initState() {
    super.initState();
    verificarConexao();
  }

  Future<void> verificarConexao() async {
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
  Widget build(BuildContext context) {
    final visita = widget.visita;
    final ponto = LatLng(visita.latitude!, visita.longitude!);
    return Scaffold(
      appBar: AppBar(title: Text('Mapa • ${visita.placa}')),
      body: FlutterMap(
        options: MapOptions(initialCenter: ponto, initialZoom: 16),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.bidwagen',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: ponto,
                width: 64,
                height: 64,
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFE02020),
                  size: 54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
