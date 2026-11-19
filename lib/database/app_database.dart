import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/vehicle_record.dart';

class BancoDeDados {
  Database? _bancoLocal;
  Future<Database> get bancoDados async {
    if (_bancoLocal != null) return _bancoLocal!;
    final caminhoBanco = join(await getDatabasesPath(), 'bidwagen.db');
    _bancoLocal = await openDatabase(
      caminhoBanco,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''CREATE TABLE vehicles (
        id TEXT PRIMARY KEY, userId TEXT NOT NULL, plate TEXT NOT NULL, brand TEXT,
        model TEXT, year INTEGER, fuel TEXT, color TEXT, fipeCode TEXT, fipeValue REAL,
        mileage INTEGER, condition INTEGER, description TEXT, imagePath TEXT,
        latitude REAL, longitude REAL, visitDate INTEGER, remoteId TEXT, synced INTEGER,
        deletedAt INTEGER, createdAt INTEGER, updatedAt INTEGER
      )''');
        await db.execute('''CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY, userId TEXT NOT NULL, entityId TEXT NOT NULL,
        remoteId TEXT, operation TEXT NOT NULL, payload TEXT, createdAt INTEGER NOT NULL
      )''');
      },
    );
    return _bancoLocal!;
  }

  Future<void> salvarVeiculo(RegistroVeiculo registro) async =>
      (await bancoDados).insert(
        'vehicles',
        registro.paraMapa(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
  Future<void> atualizarVeiculo(RegistroVeiculo registro) async =>
      (await bancoDados).update(
        'vehicles',
        registro.paraMapa(),
        where: 'id = ?',
        whereArgs: [registro.id],
      );
  Future<void> salvarVeiculoBaixado(RegistroVeiculo registro) async {
    final db = await bancoDados;
    await db.transaction((transacao) async {
      final exclusaoPendente = await transacao.query(
        'sync_queue',
        where: 'userId = ? AND operation = ? AND remoteId = ?',
        whereArgs: [registro.idUsuario, 'delete', registro.id],
        limit: 1,
      );
      if (exclusaoPendente.isNotEmpty) return;

      final existentes = await transacao.query(
        'vehicles',
        where: 'id = ? AND userId = ?',
        whereArgs: [registro.id, registro.idUsuario],
        limit: 1,
      );
      if (existentes.isNotEmpty && existentes.first['synced'] == 0) return;

      final dados = registro.paraMapa();
      if (existentes.isNotEmpty) {
        final imagemLocal = existentes.first['imagePath'] as String?;
        if (imagemLocal != null && imagemLocal.isNotEmpty) {
          dados['imagePath'] = imagemLocal;
        }
      }
      await transacao.insert(
        'vehicles',
        dados,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<RegistroVeiculo>> veiculos(String idUsuario) async {
    final linhas = await (await bancoDados).query(
      'vehicles',
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [idUsuario],
      orderBy: 'visitDate ASC',
    );
    return linhas.map(RegistroVeiculo.aPartirDoMapa).toList();
  }

  Future<List<RegistroVeiculo>> pendentes(String idUsuario) async {
    final linhas = await (await bancoDados).query(
      'vehicles',
      where: 'userId = ? AND synced = 0 AND deletedAt IS NULL',
      whereArgs: [idUsuario],
    );
    return linhas.map(RegistroVeiculo.aPartirDoMapa).toList();
  }

  Future<void> excluirVeiculo(String id) async =>
      (await bancoDados).delete('vehicles', where: 'id = ?', whereArgs: [id]);
  Future<void> limparSincronizados(String id) async =>
      (await bancoDados).delete('vehicles', where: 'id = ?', whereArgs: [id]);
  Future<void> adicionarNaFila({
    required String id,
    required String idUsuario,
    String? idRemoto,
    required String operacao,
    String? payload,
  }) async =>
      (await bancoDados).insert(
          'sync_queue',
          {
            'id': id,
            'userId': idUsuario,
            'entityId': id,
            'remoteId': idRemoto,
            'operation': operacao,
            'payload': payload,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<Map<String, Object?>>> fila(String idUsuario) async =>
      (await bancoDados).query(
        'sync_queue',
        where: 'userId = ?',
        whereArgs: [idUsuario],
        orderBy: 'createdAt ASC',
      );
  Future<void> removerDaFila(String id) async =>
      (await bancoDados).delete('sync_queue', where: 'id = ?', whereArgs: [id]);
}
