import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

abstract class AppPlugin {
  String get id;
  String get name;
  String get description;
  String get icon;
  
  List<RequiredInfo> get requiredInfos;
  
  bool isConfigured(Map<String, String> config);
  
  void registerDependencies(GetIt getIt);
  Widget buildFeature(BuildContext context);
  Widget? buildSettingsWidget(BuildContext context, Map<String, String> config, Function(Map<String, String>) onSave);
}

class RequiredInfo {
  final String key;
  final String label;
  final String? hint;
  final bool isSecret;
  
  const RequiredInfo({
    required this.key,
    required this.label,
    this.hint,
    this.isSecret = false,
  });
}