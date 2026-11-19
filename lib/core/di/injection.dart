import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

/// Point d'entrée de l'injection de dépendances,
/// `injectable` génère `injection.config.dart` avec
/// `dart run build_runner build --delete-conflicting-outputs`.
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() => getIt.init();
