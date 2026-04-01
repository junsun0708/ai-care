import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../core/plugin/plugin_registry.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final registry = GetIt.I<PluginRegistry>();
    final plugins = registry.plugins;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Children Health & Care'),
        centerTitle: true,
      ),
      body: plugins.isEmpty
          ? const Center(
              child: Text(
                'No features available.\nAdd plugins to get started.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plugins.length,
              itemBuilder: (context, index) {
                final plugin = plugins[index];
                return _FeatureCard(
                  id: plugin.id,
                  name: plugin.name,
                  description: plugin.description,
                  icon: plugin.icon,
                  onTap: () => context.go('/feature/${plugin.id}'),
                );
              },
            ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String id;
  final String name;
  final String description;
  final String icon;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}