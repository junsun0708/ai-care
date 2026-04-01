import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../plugin/plugin_registry.dart';
import '../../features/home/home_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/feature/:id',
      builder: (context, state) {
        final featureId = state.pathParameters['id']!;
        final registry = GetIt.I<PluginRegistry>();
        final plugin = registry.getPlugin(featureId);
        
        if (plugin == null) {
          return const Scaffold(
            body: Center(child: Text('Feature not found')),
          );
        }
        
        return plugin.buildFeature(context);
      },
    ),
  ],
);