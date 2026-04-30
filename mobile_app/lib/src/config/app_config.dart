import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  static String get baseUrl {
    final configuredApiBase = _readConfig('MOBILE_API_BASE_URL');
    if (configuredApiBase.isNotEmpty) {
      return _normalizeApiBase(configuredApiBase);
    }

    final backendUrl = _readConfig('BACKEND_URL');
    if (backendUrl.isNotEmpty) {
      return _normalizeApiBase(backendUrl);
    }

    return _urls[_env]!;
  }

  static String get publicBaseUrl {
    final configuredPublicBase = _readConfig('MOBILE_PUBLIC_BASE_URL');
    if (configuredPublicBase.isNotEmpty) {
      return _normalizePublicBase(configuredPublicBase);
    }

    final backendUrl = _readConfig('BACKEND_URL');
    if (backendUrl.isNotEmpty) {
      return _normalizePublicBase(backendUrl);
    }

    return _env == _Env.production
        ? _productionOrigin
        : _normalizePublicBase(baseUrl);
  }

  static String get googleMapsApiKey => _readConfig('GOOGLE_MAPS_API_KEY');

  static bool get hasGoogleMapsApiKey => googleMapsApiKey.isNotEmpty;

  static String _readConfig(String key) {
    final dartDefine = String.fromEnvironment(key);
    if (dartDefine.isNotEmpty) {
      return dartDefine;
    }

    try {
      final envValue = dotenv.env[key];
      if (envValue != null && envValue.isNotEmpty) {
        return envValue;
      }
    } catch (_) {}

    return '';
  }

  static String _normalizeApiBase(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/api')) {
      return '$trimmed/';
    }
    return '$trimmed/api/';
  }

  static String _normalizePublicBase(String value) {
    return value.trim().replaceAll(RegExp(r'/+$'), '');
  }
}

enum _Env { device, emulator, production }
