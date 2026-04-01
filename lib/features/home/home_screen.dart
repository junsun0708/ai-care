import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/plugin/app_plugin.dart';
import '../../core/plugin/plugin_registry.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _prefs = GetIt.I<SharedPreferences>();
  Set<String> _selectedFeatures = {};
  Map<String, Map<String, String>> _featureConfigs = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final selectedJson = _prefs.getString('selected_features');
    final configsJson = _prefs.getString('feature_configs');
    
    setState(() {
      if (selectedJson != null) {
        _selectedFeatures = Set<String>.from(jsonDecode(selectedJson));
      }
      if (configsJson != null) {
        _featureConfigs = Map<String, Map<String, String>>.from(
          (jsonDecode(configsJson) as Map).map(
            (k, v) => MapEntry(k, Map<String, String>.from(v)),
          ),
        );
      }
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setString('selected_features', jsonEncode(_selectedFeatures.toList()));
    await _prefs.setString('feature_configs', jsonEncode(_featureConfigs));
  }

  void _toggleFeature(String id, AppPlugin plugin) {
    setState(() {
      if (_selectedFeatures.contains(id)) {
        _selectedFeatures.remove(id);
      } else {
        if (plugin.requiredInfos.isEmpty || 
            plugin.isConfigured(_featureConfigs[id] ?? {})) {
          _selectedFeatures.add(id);
        } else {
          _showSettingsDialog(id, plugin);
        }
      }
    });
    _saveSettings();
  }

  void _showSettingsDialog(String id, AppPlugin plugin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${plugin.name} 설정',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (plugin.buildSettingsWidget != null)
                  plugin.buildSettingsWidget!(
                    ctx,
                    _featureConfigs[id] ?? {},
                    (newConfig) {
                      setState(() {
                        _featureConfigs[id] = newConfig;
                      });
                      _saveSettings();
                      Navigator.pop(ctx);
                    },
                  )!
                else
                  const Text('필수 정보가 없습니다.'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSettings(String id, AppPlugin plugin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${plugin.name} 설정',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (plugin.buildSettingsWidget != null)
                  plugin.buildSettingsWidget!(
                    ctx,
                    _featureConfigs[id] ?? {},
                    (newConfig) {
                      setState(() {
                        _featureConfigs[id] = newConfig;
                      });
                      _saveSettings();
                    },
                  )!
                else
                  const Text('설정이 없습니다.'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isConfigured(String id, AppPlugin plugin) {
    return plugin.isConfigured(_featureConfigs[id] ?? {});
  }

  @override
  Widget build(BuildContext context) {
    final registry = GetIt.I<PluginRegistry>();
    final plugins = registry.plugins;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withValues(alpha: 0.08),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Care',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '아이 건강을 위한 스마트 도우미',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app, color: primaryColor),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '사용할 기능을 선택하고 설정하세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: plugins.length,
                  itemBuilder: (context, index) {
                    final plugin = plugins[index];
                    final isSelected = _selectedFeatures.contains(plugin.id);
                    final isConfigured = _isConfigured(plugin.id, plugin);
                    final hasRequired = plugin.requiredInfos.isNotEmpty;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected 
                                  ? primaryColor.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: isSelected
                              ? Border.all(color: primaryColor, width: 2)
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleFeature(plugin.id, plugin),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isSelected
                                            ? [primaryColor, primaryColor.withValues(alpha: 0.7)]
                                            : [Colors.grey[300]!, Colors.grey[200]!],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        plugin.icon,
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
                                          plugin.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          plugin.description,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      if (hasRequired)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isConfigured 
                                                ? Colors.green[50]
                                                : Colors.orange[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isConfigured ? Icons.check_circle : Icons.warning_amber,
                                                size: 14,
                                                color: isConfigured ? Colors.green : Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isConfigured ? '설정완료' : '설정필요',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: isConfigured ? Colors.green[700] : Colors.orange[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: isSelected ? primaryColor : Colors.grey[200],
                                          shape: BoxShape.circle,
                                        ),
                                        child: isSelected
                                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                                            : null,
                                      ),
                                    ],
                                  ),
                                  if (hasRequired) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.settings_outlined, color: Colors.grey[400]),
                                      onPressed: () => _openSettings(plugin.id, plugin),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_selectedFeatures.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _prefs.setString('selected_features', jsonEncode(_selectedFeatures.toList()));
                          context.go('/tabs');
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedFeatures.length}개 기능 시작하기',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}