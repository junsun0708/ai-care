import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../plugin/plugin_registry.dart';
import '../../plugins/sample_health_plugin.dart';
import '../../plugins/voice_ai_plugin.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  
  final registry = PluginRegistry();
  
  registry.register(SampleHealthPlugin());
  registry.register(VoiceAIPlugin());
  registry.registerAll(getIt);
  
  getIt.registerSingleton<PluginRegistry>(registry);
}