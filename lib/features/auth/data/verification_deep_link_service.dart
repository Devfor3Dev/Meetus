import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// On attend le lien `loveline://verified`, ouvert par la page de confirmation que
/// l'API sert sur `GET /auth/verify` quand l'utilisateur clique le lien reçu par
/// e-mail.
///
/// Le manifeste Android et le Info.plist iOS doivent déclarer ce schéma
/// (voir le README).
@lazySingleton
class VerificationDeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  /// [onVerified] est appelé une fois par lien reçu. L'appelant décide de la suite,
  /// en général avancer le flux vers la connexion.
  void startListening({required VoidCallback onVerified}) {
    _subscription?.cancel();
    _subscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'loveline' && uri.host == 'verified') onVerified();
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
