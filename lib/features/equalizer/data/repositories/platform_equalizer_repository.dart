import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/platform/equalizer_channel.dart';
import '../../domain/entities/equalizer_settings.dart';
import '../../domain/repositories/equalizer_repository.dart';

/// 기본 값은 shared_preferences(JSON 한 덩어리)에 저장하고, Android 재생 엔진의 Equalizer · BassBoost에 반영한다.
/// 출력 기기 전용 값은 네이티브가 쥐고(`EqualizerProfiles`), 기기가 바뀌면 네이티브가 알아서 바꿔 적용한다.
/// Android가 아니면 `info`가 null이라 화면에 나오지 않는다.
class PlatformEqualizerRepository implements EqualizerRepository {
  PlatformEqualizerRepository(this._channel);

  static const _key = 'player.equalizer';

  final EqualizerChannel _channel;

  @override
  Future<EqualizerSetup> load() async {
    final prefs = await SharedPreferences.getInstance();
    final base = _decode(prefs.getString(_key));
    final info = await _info();
    if (info == null) return EqualizerSetup(info: null, settings: base);
    // 전용 값이 없는 기기에 쓸 기본 값을 네이티브에도 알려 둔다.
    final device = await _device();
    try {
      await _channel.setBase(_encode(base));
      if (device?.hasProfile == true) {
        final profile = await _channel.profile();
        if (profile != null) {
          return EqualizerSetup(
            info: info,
            settings: _decode(jsonEncode(profile)),
            device: device,
          );
        }
      }
    } on Object {
      // 네이티브를 못 부르면 기본 값으로 쓴다.
    }
    return EqualizerSetup(info: info, settings: base, device: device);
  }

  Future<EqualizerInfo?> _info() async {
    if (!Platform.isAndroid) return null;
    try {
      final map = await _channel.info();
      if (map == null) return null;
      final hz = [for (final v in map['bands'] as List) (v as num).toInt()];
      if (hz.isEmpty) return null;
      return EqualizerInfo(
        bandHz: hz,
        minDb: (map['minDb'] as num).toDouble(),
        maxDb: (map['maxDb'] as num).toDouble(),
        bassBoostSupported: map['bassBoost'] == true,
        virtualizerSupported: map['virtualizer'] == true,
        reverbSupported: map['reverb'] == true,
        limiterSupported: map['limiter'] == true,
      );
    } on Object {
      return null;
    }
  }

  Future<EqualizerDevice?> _device() async {
    try {
      final map = await _channel.device();
      if (map == null) return null;
      return EqualizerDevice(
        key: '${map['key']}',
        kind: '${map['type']}',
        name: '${map['name'] ?? ''}',
        hasProfile: map['hasProfile'] == true,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> apply(EqualizerSettings settings) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.apply(
        enabled: settings.enabled,
        levels: settings.levels,
        bassBoost: settings.bassBoost,
        virtualizer: settings.virtualizer,
        reverb: settings.reverb.index,
        limiter: settings.limiter,
      );
    } on Object {
      // 엔진을 못 부르면 다음 시작 때 다시 반영된다.
    }
  }

  @override
  Future<void> save(EqualizerSettings settings) async {
    if ((await _device())?.hasProfile == true) {
      try {
        await _channel.saveProfile(_encode(settings));
        return;
      } on Object {
        // 저장하지 못하면 기본 값으로 저장한다.
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_encode(settings, named: true)));
    if (Platform.isAndroid) {
      try {
        await _channel.setBase(_encode(settings));
      } on Object {
        // 다음 시작 때 다시 알려 준다.
      }
    }
  }

  @override
  Future<void> setDeviceProfile(
    bool enabled,
    EqualizerSettings settings,
  ) async {
    if (!Platform.isAndroid) return;
    try {
      if (enabled) {
        await _channel.saveProfile(_encode(settings));
      } else {
        await _channel.deleteProfile();
      }
    } on Object {
      // 네이티브를 못 부르면 바뀌지 않는다.
    }
  }

  @override
  Future<EqualizerSetup> loadForDevice(String deviceKey) async {
    final prefs = await SharedPreferences.getInstance();
    final base = _decode(prefs.getString(_key));
    final info = await _info();
    if (info == null) return EqualizerSetup(info: null, settings: base);
    final device = (await devices())
        .where((d) => d.key == deviceKey)
        .firstOrNull;
    try {
      final profile = await _channel.profileFor(deviceKey);
      if (profile != null) {
        return EqualizerSetup(
          info: info,
          settings: _decode(jsonEncode(profile)),
          device: device,
        );
      }
    } on Object {
      // 읽지 못하면 기본 값으로 보여 준다.
    }
    return EqualizerSetup(info: info, settings: base, device: device);
  }

  @override
  Future<void> saveForDevice(
    String deviceKey,
    EqualizerSettings settings,
  ) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.saveProfileFor(deviceKey, _encode(settings));
    } on Object {
      // 저장하지 못하면 그대로다.
    }
  }

  @override
  Stream<void> watchDevice() => _channel.deviceChanges;

  @override
  Future<List<EqualizerUserPreset>> presets() async {
    if (!Platform.isAndroid) return const [];
    try {
      final list = await _channel.presets() ?? const [];
      return [
        for (final p in list.whereType<Map<Object?, Object?>>())
          EqualizerUserPreset(
            id: '${p['id']}',
            name: '${p['name'] ?? ''}',
            settings: _decode(jsonEncode(p)),
          ),
      ];
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> savePreset(EqualizerUserPreset preset) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.savePreset({
        ..._encode(preset.settings),
        'id': preset.id,
        'name': preset.name,
      });
    } on Object {
      // 저장하지 못하면 목록에 나타나지 않는다.
    }
  }

  @override
  Future<void> deletePreset(String id) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.deletePreset(id);
    } on Object {
      // 지우지 못하면 목록에 남는다.
    }
  }

  @override
  Future<List<EqualizerDevice>> devices() async {
    if (!Platform.isAndroid) return const [];
    try {
      final list = await _channel.devices() ?? const [];
      return [
        for (final d in list.whereType<Map<Object?, Object?>>())
          EqualizerDevice(
            key: '${d['key']}',
            kind: '${d['type']}',
            name: '${d['name'] ?? ''}',
            hasProfile: d['hasProfile'] == true,
            presetId: d['presetId'] as String?,
            current: d['current'] == true,
          ),
      ];
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> assignPreset(String deviceKey, String? presetId) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.assignPreset(deviceKey, presetId);
    } on Object {
      // 지정하지 못하면 그대로다.
    }
  }

  /// 네이티브에 보내는 모양 (`reverb`는 번호). [named]면 저장용으로 이름을 쓴다.
  Map<String, Object?> _encode(EqualizerSettings s, {bool named = false}) => {
    'enabled': s.enabled,
    'preset': s.preset.name,
    'levels': s.levels,
    'bassBoost': s.bassBoost,
    'virtualizer': s.virtualizer,
    'reverb': named ? s.reverb.name : s.reverb.index,
    'limiter': s.limiter,
  };

  EqualizerSettings _decode(String? raw) {
    if (raw == null) return const EqualizerSettings();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final reverb = map['reverb'];
      return EqualizerSettings(
        enabled: map['enabled'] == true,
        preset: EqualizerPreset.values.firstWhere(
          (p) => p.name == map['preset'],
          orElse: () => EqualizerPreset.flat,
        ),
        levels: [
          for (final v in (map['levels'] as List)) (v as num).toDouble(),
        ],
        bassBoost: (map['bassBoost'] as num?)?.toDouble() ?? 0,
        virtualizer: (map['virtualizer'] as num?)?.toDouble() ?? 0,
        reverb: reverb is num
            ? EqualizerReverb.values[reverb.toInt().clamp(
                0,
                EqualizerReverb.values.length - 1,
              )]
            : EqualizerReverb.values.firstWhere(
                (r) => r.name == reverb,
                orElse: () => EqualizerReverb.none,
              ),
        limiter: map['limiter'] != false,
      );
    } on Object {
      return const EqualizerSettings();
    }
  }
}
