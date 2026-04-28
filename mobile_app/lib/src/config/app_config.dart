class AppConfig {
  // ── Change only this line to switch environments ──────────────────────────
  static const _env = _Env.production;
  // ─────────────────────────────────────────────────────────────────────────

  static const _productionOrigin =
      'https://dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net';

  static const _urls = {
    _Env.device:     'http://192.168.8.102:8080/api/',
    _Env.emulator:   'http://10.0.2.2:8080/api/',
    _Env.production: '$_productionOrigin/api/',
  };

  static String get baseUrl => _urls[_env]!;
  static String get publicBaseUrl => _env == _Env.production
      ? _productionOrigin
      : baseUrl.endsWith('/api/')
          ? baseUrl.substring(0, baseUrl.length - 5)
          : baseUrl;
  static const String googleMapsApiKey = 'AIzaSyD2nfcOKfyc7TWF4alRcvbE1Jyo-omYYjY';
}

enum _Env { device, emulator, production }
