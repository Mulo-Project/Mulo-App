import 'package:equatable/equatable.dart';

/// 이퀄라이저 프리셋. [custom]은 대역을 직접 만진 상태.
enum EqualizerPreset {
  flat,
  bass,
  treble,
  vocal,
  rock,
  pop,
  jazz,
  classical,
  dance,
  custom;

  /// 낮은 소리 → 높은 소리 5점의 dB 곡선. 기기 대역 수에 맞춰 [levelsFor]가 펴 준다.
  List<double>? get _curve => switch (this) {
    flat => const [0, 0, 0, 0, 0],
    bass => const [6, 4, 1, 0, 0],
    treble => const [0, 0, 1, 4, 6],
    vocal => const [-2, 0, 3, 3, -1],
    rock => const [4, 1, -2, 1, 4],
    pop => const [2, 1, 0, 3, 1],
    jazz => const [2, 2, 1, 0, -2],
    classical => const [0, 0, 0, 2, 3],
    dance => const [6, 3, -1, 0, 1],
    custom => null,
  };

  /// [bands]개 대역의 dB (기기가 허용하는 [minDb]~[maxDb]로 자른다).
  List<double> levelsFor(int bands, {double minDb = -15, double maxDb = 15}) {
    final curve = _curve ?? const [0.0, 0.0, 0.0, 0.0, 0.0];
    if (bands <= 0) return const [];
    return [
      for (var i = 0; i < bands; i++)
        _sample(curve, bands == 1 ? 0 : i / (bands - 1)).clamp(minDb, maxDb),
    ];
  }

  static double _sample(List<double> curve, double t) {
    final pos = t * (curve.length - 1);
    final lo = pos.floor();
    final hi = pos.ceil();
    return curve[lo] + (curve[hi] - curve[lo]) * (pos - lo);
  }
}

/// 공간 울림(리버브). 번호는 Android `PresetReverb`의 프리셋 번호와 같다.
enum EqualizerReverb {
  none,
  smallRoom,
  mediumRoom,
  largeRoom,
  mediumHall,
  largeHall,
  plate,
}

/// 기기가 알려 주는 이퀄라이저 능력 (Android: Equalizer / BassBoost).
class EqualizerInfo extends Equatable {
  const EqualizerInfo({
    required this.bandHz,
    required this.minDb,
    required this.maxDb,
    required this.bassBoostSupported,
    this.virtualizerSupported = false,
    this.reverbSupported = false,
    this.limiterSupported = false,
  });

  /// 대역별 중심 주파수 (Hz), 낮은 쪽부터.
  final List<int> bandHz;
  final double minDb;
  final double maxDb;
  final bool bassBoostSupported;
  final bool virtualizerSupported;
  final bool reverbSupported;

  /// 클리핑 방지 리미터 (Android 9+).
  final bool limiterSupported;

  @override
  List<Object?> get props => [
    bandHz,
    minDb,
    maxDb,
    bassBoostSupported,
    virtualizerSupported,
    reverbSupported,
    limiterSupported,
  ];
}

/// 저장되는 이퀄라이저 값. 기본은 꺼짐 · 평평한 소리.
class EqualizerSettings extends Equatable {
  const EqualizerSettings({
    this.enabled = false,
    this.preset = EqualizerPreset.flat,
    this.levels = const [],
    this.bassBoost = 0,
    this.virtualizer = 0,
    this.reverb = EqualizerReverb.none,
    this.limiter = true,
  });

  final bool enabled;
  final EqualizerPreset preset;

  /// 대역별 dB (대역 수는 기기에 맞춘다).
  final List<double> levels;

  /// 저음 강화 0 ~ 1.
  final double bassBoost;

  /// 입체 음향 0 ~ 1.
  final double virtualizer;
  final EqualizerReverb reverb;

  /// 클리핑 방지 (소리를 키워도 찢어지지 않게). 기본 켜짐.
  final bool limiter;

  EqualizerSettings copyWith({
    bool? enabled,
    EqualizerPreset? preset,
    List<double>? levels,
    double? bassBoost,
    double? virtualizer,
    EqualizerReverb? reverb,
    bool? limiter,
  }) => EqualizerSettings(
    enabled: enabled ?? this.enabled,
    preset: preset ?? this.preset,
    levels: levels ?? this.levels,
    bassBoost: bassBoost ?? this.bassBoost,
    virtualizer: virtualizer ?? this.virtualizer,
    reverb: reverb ?? this.reverb,
    limiter: limiter ?? this.limiter,
  );

  /// 기기 대역 수에 맞춰 [levels]를 고른다 (수가 다르면 프리셋 곡선으로 다시 만든다).
  EqualizerSettings fitTo(EqualizerInfo info) {
    final n = info.bandHz.length;
    final fitted = levels.length == n
        ? [for (final v in levels) v.clamp(info.minDb, info.maxDb)]
        : preset.levelsFor(n, minDb: info.minDb, maxDb: info.maxDb);
    return copyWith(
      levels: fitted,
      bassBoost: info.bassBoostSupported ? bassBoost.clamp(0.0, 1.0) : 0,
      virtualizer: info.virtualizerSupported ? virtualizer.clamp(0.0, 1.0) : 0,
      reverb: info.reverbSupported ? reverb : EqualizerReverb.none,
    );
  }

  @override
  List<Object?> get props => [
    enabled,
    preset,
    levels,
    bassBoost,
    virtualizer,
    reverb,
    limiter,
  ];
}

/// 시작할 때 읽는 묶음: 기기 능력(없으면 null = 지원하지 않음)과 저장된 값.
/// 지금 소리가 나가는 출력 기기. [hasProfile]이면 이 기기 전용 이퀄라이저 값이 있다.
class EqualizerDevice extends Equatable {
  const EqualizerDevice({
    required this.key,
    required this.kind,
    this.name = '',
    this.hasProfile = false,
    this.presetId,
    this.current = false,
  });

  /// 기기 구분 열쇠 (종류 + 이름).
  final String key;

  /// `speaker` `wired` `bluetooth` `usb` 중 하나.
  final String kind;
  final String name;
  final bool hasProfile;

  /// 지정한 내 프리셋 (직접 만든 전용 값이면 null).
  final String? presetId;

  /// 지금 소리가 나가는 기기인지.
  final bool current;

  @override
  List<Object?> get props => [key, kind, name, hasProfile, presetId, current];
}

/// 이름을 붙여 만들어 둔 이퀄라이저 값 (내 프리셋). 기기에 지정해 쓴다.
class EqualizerUserPreset extends Equatable {
  const EqualizerUserPreset({
    required this.id,
    required this.name,
    required this.settings,
  });

  final String id;
  final String name;
  final EqualizerSettings settings;

  @override
  List<Object?> get props => [id, name, settings];
}

class EqualizerSetup extends Equatable {
  const EqualizerSetup({
    required this.info,
    required this.settings,
    this.device,
  });

  final EqualizerInfo? info;
  final EqualizerSettings settings;

  /// 지금 출력 기기 (알 수 없으면 null). [settings]는 이 기기 전용 값이 있으면 그 값이다.
  final EqualizerDevice? device;

  @override
  List<Object?> get props => [info, settings, device];
}
