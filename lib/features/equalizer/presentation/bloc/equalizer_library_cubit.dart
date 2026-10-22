import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/equalizer_settings.dart';
import '../../domain/usecases/equalizer_usecases.dart';

class EqualizerLibraryState extends Equatable {
  const EqualizerLibraryState({
    this.presets = const [],
    this.devices = const [],
  });

  /// 만들어 둔 내 프리셋 (만든 순서).
  final List<EqualizerUserPreset> presets;

  /// 연결된 적 있는 출력 기기 (지금 기기가 맨 위).
  final List<EqualizerDevice> devices;

  EqualizerUserPreset? presetById(String? id) {
    for (final p in presets) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  List<Object?> get props => [presets, devices];
}

/// 내 프리셋 목록과 기기별 프리셋 지정. 저장과 기기 전환 적용은 네이티브가 맡는다.
class EqualizerLibraryCubit extends Cubit<EqualizerLibraryState> {
  EqualizerLibraryCubit({
    required LoadEqualizerPresets loadPresets,
    required SaveEqualizerPreset savePreset,
    required DeleteEqualizerPreset deletePreset,
    required LoadEqualizerDevices loadDevices,
    required AssignEqualizerPreset assignPreset,
    required WatchEqualizerDevice watchDevice,
  }) : _presetsUse = loadPresets,
       _saveUse = savePreset,
       _deleteUse = deletePreset,
       _devicesUse = loadDevices,
       _assignUse = assignPreset,
       _watch = watchDevice,
       super(const EqualizerLibraryState());

  final LoadEqualizerPresets _presetsUse;
  final SaveEqualizerPreset _saveUse;
  final DeleteEqualizerPreset _deleteUse;
  final LoadEqualizerDevices _devicesUse;
  final AssignEqualizerPreset _assignUse;
  final WatchEqualizerDevice _watch;
  StreamSubscription<void>? _changes;

  Future<void> load() async {
    await refresh();
    if (isClosed || _changes != null) return;
    // 기기가 연결되거나 끊기면 목록(지금 기기 표시)을 다시 읽는다.
    final stream = await _watch(const NoParams());
    if (isClosed) return;
    _changes = stream.listen((_) => refresh());
  }

  Future<void> refresh() async {
    final presets = await _presetsUse(const NoParams());
    final devices = await _devicesUse(const NoParams());
    if (!isClosed) {
      emit(EqualizerLibraryState(presets: presets, devices: devices));
    }
  }

  /// 지금 값을 [name]이라는 새 프리셋으로 저장한다.
  Future<void> saveNew(String name, EqualizerSettings settings) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _saveUse(
      EqualizerUserPreset(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: trimmed,
        settings: settings,
      ),
    );
    await refresh();
  }

  Future<void> delete(String id) async {
    await _deleteUse(id);
    await refresh();
  }

  /// [deviceKey] 기기에 프리셋을 지정한다 ([presetId]가 null이면 기본 설정을 쓴다).
  Future<void> assign(String deviceKey, String? presetId) async {
    await _assignUse((deviceKey: deviceKey, presetId: presetId));
    await refresh();
  }

  @override
  Future<void> close() {
    _changes?.cancel();
    return super.close();
  }
}
