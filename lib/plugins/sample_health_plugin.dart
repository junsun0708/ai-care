import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/plugin/app_plugin.dart';

class SampleHealthPlugin implements AppPlugin {
  @override
  String get id => 'health_check';

  @override
  String get name => 'Health Check';

  @override
  String get description => '기본 건강 체크';

  @override
  String get icon => '🏥';

  @override
  List<RequiredInfo> get requiredInfos => [];

  @override
  bool isConfigured(Map<String, String> config) => true;

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  Widget buildFeature(BuildContext context) {
    return const _HealthCheckScreen();
  }

  @override
  Widget? buildSettingsWidget(BuildContext context, Map<String, String> config, Function(Map<String, String>) onSave) => null;
}

class _HealthCheckScreen extends StatelessWidget {
  const _HealthCheckScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Check'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🏥', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('Health Check Feature', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Add your health check functionality here', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}