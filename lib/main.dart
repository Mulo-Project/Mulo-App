import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/cache/cache_cleaner.dart';
import 'core/di/injector.dart';
import 'features/engine/data/engine_updater.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const MusicApp());
  unawaited(CacheCleaner.run());
  // 받기 엔진(yt-dlp)을 켤 때마다 확인해 새 버전이 있으면 조용히 올린다 (인터넷이 없으면 건너뛴다).
  unawaited(sl<EngineUpdater>().checkOnLaunch());
}
