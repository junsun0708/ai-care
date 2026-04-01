import 'package:get_it/get_it.dart';

import '../plugin/plugin_registry.dart';
import '../../plugins/sample_health_plugin.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final registry = PluginRegistry();
  
  registry.register(SampleHealthPlugin());
  registry.registerAll(getIt);
  
  getIt.registerSingleton<PluginRegistry>(registry);
}