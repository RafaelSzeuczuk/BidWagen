import 'package:geolocator/geolocator.dart';

class ServicoLocalizacao {
  Future<Position> posicaoAtual() async {
    if (!await Geolocator.isLocationServiceEnabled())
      throw Exception('Ative o serviço de localização para continuar.');
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever)
      throw Exception('Permissão de localização negada.');
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
