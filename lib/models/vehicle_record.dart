class RegistroVeiculo {
  const RegistroVeiculo({
    required this.id,
    required this.idUsuario,
    required this.placa,
    this.marca,
    this.modelo,
    this.ano,
    this.combustivel,
    this.cor,
    this.codigoFipe,
    this.valorFipe = 0,
    this.quilometragem = 0,
    this.conservacao = 100,
    this.descricao = '',
    this.caminhoImagem,
    this.latitude,
    this.longitude,
    this.dataVisita,
    this.idRemoto,
    this.sincronizado = false,
    this.excluidoEm,
    this.criadoEm,
    this.atualizadoEm,
  });

  final String id;
  final String idUsuario;
  final String placa;
  final String? marca;
  final String? modelo;
  final int? ano;
  final String? combustivel;
  final String? cor;
  final String? codigoFipe;
  final double valorFipe;
  final int quilometragem;
  final int conservacao;
  final String descricao;
  final String? caminhoImagem;
  final double? latitude;
  final double? longitude;
  final DateTime? dataVisita;
  final String? idRemoto;
  final bool sincronizado;
  final DateTime? excluidoEm;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  double get descontoConservacao {
    if (conservacao >= 95) return 0.04;
    if (conservacao >= 90) return 0.10;
    if (conservacao >= 80) return 0.22;
    if (conservacao >= 70) return 0.35;
    if (conservacao >= 60) return 0.48;
    if (conservacao >= 50) return 0.60;
    return 0.65;
  }

  double get descontoQuilometragem {
    if (quilometragem < 50000) return 0.05;
    if (quilometragem < 100000) return .12;
    if (quilometragem < 150000) return .18;
    if (quilometragem < 200000) return .24;
    if (quilometragem < 250000) return .30;
    if (quilometragem < 300000) return .40;
    return .45;
  }

  double get ofertaSugerida {
    final desconto =
        (descontoConservacao + descontoQuilometragem).clamp(0.0, 0.75);
    return valorFipe * (1 - desconto);
  }

  double get descontoTotal => descontoConservacao + descontoQuilometragem;

  RegistroVeiculo comAlteracoes({
    String? id,
    String? idUsuario,
    String? placa,
    String? marca,
    String? modelo,
    int? ano,
    String? combustivel,
    String? cor,
    String? codigoFipe,
    double? valorFipe,
    int? quilometragem,
    int? conservacao,
    String? descricao,
    String? caminhoImagem,
    double? latitude,
    double? longitude,
    DateTime? dataVisita,
    String? idRemoto,
    bool? sincronizado,
    DateTime? excluidoEm,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) =>
      RegistroVeiculo(
        id: id ?? this.id,
        idUsuario: idUsuario ?? this.idUsuario,
        placa: placa ?? this.placa,
        marca: marca ?? this.marca,
        modelo: modelo ?? this.modelo,
        ano: ano ?? this.ano,
        combustivel: combustivel ?? this.combustivel,
        cor: cor ?? this.cor,
        codigoFipe: codigoFipe ?? this.codigoFipe,
        valorFipe: valorFipe ?? this.valorFipe,
        quilometragem: quilometragem ?? this.quilometragem,
        conservacao: conservacao ?? this.conservacao,
        descricao: descricao ?? this.descricao,
        caminhoImagem: caminhoImagem ?? this.caminhoImagem,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        dataVisita: dataVisita ?? this.dataVisita,
        idRemoto: idRemoto ?? this.idRemoto,
        sincronizado: sincronizado ?? this.sincronizado,
        excluidoEm: excluidoEm ?? this.excluidoEm,
        criadoEm: criadoEm ?? this.criadoEm,
        atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      );

  Map<String, Object?> paraMapa() => {
        'id': id,
        'userId': idUsuario,
        'plate': placa,
        'brand': marca,
        'model': modelo,
        'year': ano,
        'fuel': combustivel,
        'color': cor,
        'fipeCode': codigoFipe,
        'fipeValue': valorFipe,
        'mileage': quilometragem,
        'condition': conservacao,
        'description': descricao,
        'imagePath': caminhoImagem,
        'latitude': latitude,
        'longitude': longitude,
        'visitDate': dataVisita?.millisecondsSinceEpoch,
        'remoteId': idRemoto,
        'synced': sincronizado ? 1 : 0,
        'deletedAt': excluidoEm?.millisecondsSinceEpoch,
        'createdAt': (criadoEm ?? DateTime.now()).millisecondsSinceEpoch,
        'updatedAt': (atualizadoEm ?? DateTime.now()).millisecondsSinceEpoch,
      };

  factory RegistroVeiculo.aPartirDoMapa(Map<String, Object?> map) =>
      RegistroVeiculo(
        id: map['id'] as String,
        idUsuario: map['userId'] as String,
        placa: map['plate'] as String,
        marca: map['brand'] as String?,
        modelo: map['model'] as String?,
        ano: map['year'] as int?,
        combustivel: map['fuel'] as String?,
        cor: map['color'] as String?,
        codigoFipe: map['fipeCode'] as String?,
        valorFipe: (map['fipeValue'] as num?)?.toDouble() ?? 0,
        quilometragem: (map['mileage'] as num?)?.toInt() ?? 0,
        conservacao: (map['condition'] as num?)?.toInt() ?? 100,
        descricao: map['description'] as String? ?? '',
        caminhoImagem: map['imagePath'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        dataVisita: _converterData(map['visitDate']),
        idRemoto: map['remoteId'] as String?,
        sincronizado: (map['synced'] as num?) == 1,
        excluidoEm: _converterData(map['deletedAt']),
        criadoEm: _converterData(map['createdAt']),
        atualizadoEm: _converterData(map['updatedAt']),
      );

  static DateTime? _converterData(Object? valor) =>
      valor is int ? DateTime.fromMillisecondsSinceEpoch(valor) : null;

  Map<String, Object?> paraFirestore() {
    final dados = Map<String, Object?>.from(paraMapa());
    dados.remove('imagePath');
    dados.remove('synced');
    dados.remove('remoteId');
    dados.remove('deletedAt');
    if (dataVisita == null) {
      dados.remove('latitude');
      dados.remove('longitude');
    }
    return dados;
  }
}
