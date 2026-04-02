import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../plugin/plugin_registry.dart';
import '../../plugins/sample_health_plugin.dart';
import '../../plugins/voice_ai_plugin.dart';
import '../../plugins/welfare_plugin.dart';
import '../../plugins/waiting_reservation_plugin.dart';
import '../../plugins/notice_summary_plugin.dart';
import '../../plugins/safety_notification_plugin.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  
  final registry = PluginRegistry();
  
  registry.register(SampleHealthPlugin());
  registry.register(VoiceAIPlugin());
  registry.register(WelfarePlugin());
  registry.register(WaitingReservationPlugin());
  registry.register(NoticeSummaryPlugin());
  registry.register(SafetyNotificationPlugin());
  registry.registerAll(getIt);
  
  getIt.registerSingleton<PluginRegistry>(registry);
}