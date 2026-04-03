class AppConfig {
  // ── Change only this line to switch environments ──────────────────────────
  static const _env = _Env.production;
  // ─────────────────────────────────────────────────────────────────────────

  static const _urls = {
    _Env.device:     'http://192.168.1.163:8080/api/',
    _Env.emulator:   'http://10.0.2.2:8080/api/',
    _Env.production: 'https://dealfinder-h0hnh3emahabaahw.southindia-01.azurewebsites.net/api/',
  };

  static String get baseUrl => _urls[_env]!;
  static const String googleMapsApiKey = 'AIzaSyD2nfcOKfyc7TWF4alRcvbE1Jyo-omYYjY';
}

enum _Env { device, emulator, production }
