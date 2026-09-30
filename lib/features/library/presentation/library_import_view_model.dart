import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di.dart';
import '../domain/library_repository.dart';

/// 기기 음악 불러오기 결과 (화면이 안내 문구를 고른다).
sealed class ImportOutcome {
  const ImportOutcome();
}

class ImportAdded extends ImportOutcome {
  const ImportAdded(this.count);

  /// 새로 추가된 곡 수 (0이면 이미 다 있음).
  final int count;
}

class ImportDenied extends ImportOutcome {
  const ImportDenied();
}

class ImportFailed extends ImportOutcome {
  const ImportFailed();
}

@immutable
class ImportState {
  const ImportState({this.running = false});

  final bool running;
}

/// 기기 음악 불러오기 (상세 기능 #11).
class LibraryImportViewModel extends Notifier<ImportState> {
  @override
  ImportState build() => const ImportState();

  /// 불러오기를 실행한다. 이미 실행 중이거나 사용자가 취소하면 null.
  Future<ImportOutcome?> importDeviceMusic() async {
    if (state.running) return null;
    state = const ImportState(running: true);
    try {
      final result = await ref.read(deviceMusicScannerProvider).scan();
      return switch (result) {
        ScanCancelled() => null,
        ScanPermissionDenied() => const ImportDenied(),
        ScanFound(:final tracks) => ImportAdded(
          await ref.read(libraryRepositoryProvider).addTracks(tracks),
        ),
      };
    } catch (_) {
      return const ImportFailed();
    } finally {
      state = const ImportState();
    }
  }
}

final libraryImportProvider =
    NotifierProvider<LibraryImportViewModel, ImportState>(
      LibraryImportViewModel.new,
    );
