import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/plugin/app_plugin.dart';

class SampleHealthPlugin implements AppPlugin {
  @override
  String get id => 'health_check';

  @override
  String get name => 'Health Check';

  @override
  String get description => 'Basic health check for children';

  @override
  String get icon => '🏥';

  @override
  void registerDependencies(GetIt getIt) {
    // Register dependencies for this feature
  }

  @override
  Widget buildFeature(BuildContext context) {
    return const _HealthCheckScreen();
  }
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
            Text(
              '🏥',
              style: TextStyle(fontSize: 64),
            ),
            SizedBox(height: 16),
            Text(
              'Health Check Feature',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Add your health check functionality here',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}