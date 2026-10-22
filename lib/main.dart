import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/cache/cache_cleaner.dart';
import 'core/di/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const MusicApp());
  unawaited(CacheCleaner.run());
}
