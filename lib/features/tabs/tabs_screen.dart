import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/plugin/plugin_registry.dart';
import '../../plugins/voice_ai_plugin.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  final _prefs = GetIt.I<SharedPreferences>();
  List<String> _selectedFeatures = [];
  Map<String, Map<String, String>> _featureConfigs = {};
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final selectedJson = _prefs.getString('selected_features');
    final configsJson = _prefs.getString('feature_configs');
    
    if (selectedJson != null) {
      _selectedFeatures = List<String>.from(jsonDecode(selectedJson));
    }
    if (configsJson != null) {
      _featureConfigs = Map<String, Map<String, String>>.from(
        (jsonDecode(configsJson) as Map).map(
          (k, v) => MapEntry(k, Map<String, String>.from(v)),
        ),
      );
    }
  }

  Widget _buildPluginWidget(String id, Map<String, String> config) {
    final registry = GetIt.I<PluginRegistry>();
    final plugin = registry.getPlugin(id);
    
    if (plugin == null) {
      return const Center(child: Text('Plugin not found'));
    }

    if (id == 'voice_ai') {
      return VoiceAIScreen(config: config);
    }

    return plugin.buildFeature(context);
  }

  @override
  Widget build(BuildContext context) {
    final registry = GetIt.I<PluginRegistry>();
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    final tabs = <Map<String, String>>[];
    for (final id in _selectedFeatures) {
      final plugin = registry.getPlugin(id);
      if (plugin != null) {
        tabs.add({
          'id': id,
          'name': plugin.name,
          'icon': plugin.icon,
        });
      }
    }

    if (tabs.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text('선택된 기능이 없습니다.', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('기능 선택으로 이동'),
              ),
            ],
          ),
        ),
      );
    }

    final currentId = _selectedFeatures[_currentIndex];
    final currentConfig = _featureConfigs[currentId] ?? {};

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.favorite, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      tabs[_currentIndex]['name']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.go('/'),
                      icon: Icon(Icons.home_outlined, color: Colors.grey[600]),
                      tooltip: '홈으로',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildPluginWidget(currentId, currentConfig),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (index) {
                final isSelected = _currentIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tabs[index]['icon']!,
                            style: TextStyle(
                              fontSize: isSelected ? 26 : 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tabs[index]['name']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? primaryColor : Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}