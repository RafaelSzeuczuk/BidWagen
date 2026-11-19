class VeiculoDaApi {
  const VeiculoDaApi({
    this.marca,
    this.modelo,
    this.ano,
    this.combustivel,
    this.cor,
    this.codigoFipe,
    this.valorFipe,
    this.detalhes = const {},
  });

  final String? marca;
  final String? modelo;
  final int? ano;
  final String? combustivel;
  final String? cor;
  final String? codigoFipe;
  final double? valorFipe;
  final Map<String, String> detalhes;

  factory VeiculoDaApi.aPartirDoJson(Map<String, dynamic> json) {
    dynamic selecionarValor(List<String> chaves) {
      for (final key in chaves) {
        if (json[key] != null && '${json[key]}'.trim().isNotEmpty)
          return json[key];
      }
      return null;
    }

    final detalhes = <String, String>{};
    for (final entrada in json.entries) {
      if (entrada.value != null && entrada.value.toString().trim().isNotEmpty)
        detalhes[entrada.key] = entrada.value.toString();
    }
    return VeiculoDaApi(
      marca: selecionarValor(['marca', 'brand', 'nomeMarca'])?.toString(),
      modelo: selecionarValor(['modelo', 'model', 'nomeModelo'])?.toString(),
      ano: int.tryParse(
          '${selecionarValor(['ano_modelo', 'ano', 'year']) ?? ''}'),
      combustivel: selecionarValor(['combustivel', 'fuel', 'tipoCombustivel'])
          ?.toString(),
      cor: selecionarValor(['cor', 'color'])?.toString(),
      codigoFipe: selecionarValor(['codigo_fipe', 'codigoFipe', 'fipeCode'])
          ?.toString(),
      valorFipe: _interpretarValorMonetario(
          selecionarValor(['preco', 'valor', 'value', 'fipeValue'])),
      detalhes: detalhes,
    );
  }

  VeiculoDaApi comDadosFipe(Map<String, dynamic>? fipe) {
    if (fipe == null) return this;
    final mesclados = Map<String, String>.from(detalhes);
    for (final entrada in fipe.entries) {
      if (entrada.value != null && entrada.value.toString().trim().isNotEmpty)
        mesclados['fipe_${entrada.key}'] = entrada.value.toString();
    }
    return VeiculoDaApi(
      marca: marca,
      modelo: modelo,
      ano: ano,
      combustivel: combustivel,
      cor: cor,
      codigoFipe: fipe['codigo_fipe']?.toString() ?? codigoFipe,
      valorFipe: _interpretarValorMonetario(
              fipe['preco'] ?? fipe['valor'] ?? fipe['value']) ??
          valorFipe,
      detalhes: mesclados,
    );
  }

  static double? _interpretarValorMonetario(dynamic valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toDouble();
    var texto = valor.toString().trim().replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (texto.contains(','))
      texto = texto.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(texto);
  }
}
