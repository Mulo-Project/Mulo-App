import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/platform/equalizer_channel.dart';
import '../../domain/entities/equalizer_settings.dart';
import '../../domain/repositories/equalizer_repository.dart';

/// 값은 shared_preferences(JSON 한 덩어리)에 저장하고, Android 재생 엔진의 Equalizer · BassBoost에 반영한다.
/// Android가 아니면 `info`가 null이라 화면에 나오지 않는다.
class PlatformEqualizerRepository implements EqualizerRepository {
  PlatformEqualizerRepository(this._channel);

  static const _key = 'player.equalizer';

  final EqualizerChannel _channel;

  @override
  Future<EqualizerSetup> load() async {
    final prefs = await SharedPreferences.getInstance();
    return EqualizerSetup(
      info: await _info(),
      settings: _decode(prefs.getString(_key)),
    );
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
      );
    } on Object {
      // 엔진을 못 부르면 다음 시작 때 다시 반영된다.
    }
  }

  @override
  Future<void> save(EqualizerSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'enabled': settings.enabled,
        'preset': settings.preset.name,
        'levels': settings.levels,
        'bassBoost': settings.bassBoost,
      }),
    );
  }

  EqualizerSettings _decode(String? raw) {
    if (raw == null) return const EqualizerSettings();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
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
      );
    } on Object {
      return const EqualizerSettings();
    }
  }
}
