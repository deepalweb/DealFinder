class AppConfig {
  static const _envName =
      String.fromEnvironment('DEALFINDER_ENV', defaultValue: 'production');
  static const _backendOverride =
      String.fromEnvironment('DEALFINDER_BACKEND_URL', defaultValue: '');

  static const _productionOrigin =
      'https://dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net';

  static const _urls = {
    _Env.device:     'http://192.168.8.102:8080/api/',
    _Env.emulator:   'http://10.0.2.2:8080/api/',
    _Env.production: '$_productionOrigin/api/',
  };

  static String get baseUrl {
    if (_backendOverride.isNotEmpty) {
      return _normalizeApiUrl(_backendOverride);
    }
    return _urls[_parseEnv(_envName)]!;
  }

  static String get publicBaseUrl =>
      baseUrl.endsWith('/api/')
          ? baseUrl.substring(0, baseUrl.length - 5)
          : baseUrl;

  static const String googleMapsApiKey = 'AIzaSyD2nfcOKfyc7TWF4alRcvbE1Jyo-omYYjY';

  static _Env _parseEnv(String value) {
    switch (value) {
      case 'device':
        return _Env.device;
      case 'emulator':
        return _Env.emulator;
      case 'production':
      default:
        return _Env.production;
    }
  }

  static String _normalizeApiUrl(String url) {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/api')) {
      return '$trimmed/';
    }
    return '$trimmed/api/';
  }
}

enum _Env { device, emulator, production }
