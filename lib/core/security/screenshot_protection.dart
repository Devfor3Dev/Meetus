import 'dart:io';

import 'package:flutter/services.dart';

/// Bloque captures et enregistrements d'écran, via un MethodChannel
///
/// Android : FLAG_SECURE sur la fenêtre,
/// iOS : pour le PWA Apple n'offre aucune API de blocage, donc ce service ne fait rien.
///

abstract final class ScreenshotProtection {
  static const MethodChannel _channel = MethodChannel('loveline/security');

  static Future<void> enable() => _invoke('enableSecureScreen');

  static Future<void> disable() => _invoke('disableSecureScreen');

  static Future<void> _invoke(String method) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException {
      // Canal natif absent
    } on MissingPluginException {
      // Même cas.
    }
  }

  const ScreenshotProtection._();
}
