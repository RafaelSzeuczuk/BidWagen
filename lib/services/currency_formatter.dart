String formatarValorEmReais(double valor) {
  final valorFixo = valor.toStringAsFixed(2).split('.');
  final parteInteira = valorFixo[0];
  final negativo = parteInteira.startsWith('-');
  final digitos = negativo ? parteInteira.substring(1) : parteInteira;
  final digitosAgrupados = digitos.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${negativo ? '-' : ''}$digitosAgrupados,${valorFixo[1]}';
}
