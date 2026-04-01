import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

abstract class AppPlugin {
  String get id;
  String get name;
  String get description;
  String get icon;
  void registerDependencies(GetIt getIt);
  Widget buildFeature(BuildContext context);
}