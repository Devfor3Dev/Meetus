import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/network/api_config.dart';
import 'core/security/screenshot_protection.dart';
import 'core/storage/auth_session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiConfig.assertSecureInRelease();
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);

  await configureDependencies();
  await getIt<AuthSessionStore>().restore();

  // Active en release seulement, on verra  en dev
  if (kReleaseMode) await ScreenshotProtection.enable();

  runApp(const ProviderScope(child: LovelineApp()));
}
