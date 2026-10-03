import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/injector.dart';
import 'features/player/data/datasources/audio_engine_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initAudioBackend();
  configureDependencies();
  runApp(const MusicApp());
}
