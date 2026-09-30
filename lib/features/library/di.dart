import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import 'data/device_music_scanners.dart';
import 'data/drift_library_repository.dart';
import 'domain/library_repository.dart';
import 'domain/track.dart';

/// 보관함 의존성 연결. 테스트는 리포지토리 · 스캐너 provider를 바꿔 끼운다.
final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => DriftLibraryRepository(ref.watch(appDatabaseProvider)),
);

final deviceMusicScannerProvider = Provider<DeviceMusicScanner>(
  (ref) =>
      Platform.isAndroid ? MediaStoreMusicScanner() : DirectoryMusicScanner(),
);

/// 보관함 곡 목록 (추가일 최신순).
final libraryTracksProvider = StreamProvider<List<Track>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchTracks(),
);
