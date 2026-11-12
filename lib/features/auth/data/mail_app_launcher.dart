import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:injectable/injectable.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tente d'ouvrir l'application mail native de l'appareil.
///
/// Aucune API multiplateforme ne garantit l'ouverture du client mail par défaut,donc
/// on croise juste les doigts:
///
/// Android : intent ACTION_MAIN avec la catégorie APP_EMAIL. Le système affiche le
/// client par défaut, ou un sélecteur s'il y en a plusieurs. Le manifeste doit
/// déclarer cet intent dans `<queries>` (voir le README).
///
/// iOS : pour le PWA, y a pas un truc équivalent sur ios. On essaie les schémas des clients les plus
/// répandus (Gmail, Outlook, Mail) et on ouvre le premier disponible. S'il n'y a rien,
/// on retourne false tout ce qui reste à faire c'est de demander à l'uilisateur d'ouvrir lui même l'app
@lazySingleton
class MailAppLauncher {
  Future<bool> openMailApp() async {
    if (Platform.isAndroid) return _openOnAndroid();
    if (Platform.isIOS) return _openOnIOS();
    return false;
  }

  Future<bool> _openOnAndroid() async {
    try {
      const intent = AndroidIntent(
        action: 'action_main',
        category: 'android.intent.category.APP_EMAIL',
      );
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _openOnIOS() async {
    const candidateSchemes = <String>[
      'googlegmail://',
      'ms-outlook://',
      'message://', // Mail.app
    ];

    for (final scheme in candidateSchemes) {
      final uri = Uri.parse(scheme);
      if (await canLaunchUrl(uri)) return launchUrl(uri);
    }
    return false;
  }
}
