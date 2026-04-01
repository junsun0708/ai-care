import 'package:get_it/get_it.dart';

import 'app_plugin.dart';

class PluginRegistry {
  final List<AppPlugin> _plugins = [];

  void register(AppPlugin plugin) {
    _plugins.add(plugin);
  }

  List<AppPlugin> get plugins => List.unmodifiable(_plugins);

  AppPlugin? getPlugin(String id) {
    try {
      return _plugins.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void registerAll(GetIt getIt) {
    for (final plugin in _plugins) {
      plugin.registerDependencies(getIt);
    }
  }
}