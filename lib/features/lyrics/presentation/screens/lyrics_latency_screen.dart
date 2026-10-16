import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/latency_calibration.dart';
import '../bloc/lyrics_settings_cubit.dart';
import '../bloc/lyrics_sync_cubit.dart';

/// 싱크 반응 시간 보정 페이지를 연다.
Future<void> showLyricsLatency(BuildContext context) => Navigator.of(
  context,
  rootNavigator: true,
).push<void>(MaterialPageRoute(builder: (_) => const LyricsLatencyScreen()));

/// `지금`을 누를 때 반응 시간만큼 앞당겨 찍는 값을 조정하고 시험해 보는 페이지.
/// 슬라이더로 직접 맞추거나, 박자 테스트 · 곡으로 확인으로 시험하며 맞춘다.
class LyricsLatencyScreen extends StatefulWidget {
  const LyricsLatencyScreen({super.key});

  @override
  State<LyricsLatencyScreen> createState() => _LyricsLatencyScreenState();
}

class _LyricsLatencyScreenState extends State<LyricsLatencyScreen> {
  static const _calibration = LatencyCalibration();
  static const _taps = 8;

  final _clock = Stopwatch();
  Timer? _timer;
  var _running = false;
  var _flash = false;
  final _offsets = <int>[];

  /// 곡으로 확인에서 마지막으로 찍어 본 위치.
  Duration? _tried;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _offsets.clear();
    _clock
      ..reset()
      ..start();
    setState(() => _running = true);
    _beat(0);
  }

  void _stop() {
    _timer?.cancel();
    _clock.stop();
    if (mounted) {
      setState(() {
        _running = false;
        _flash = false;
      });
    }
  }

  /// [n]번째 박자를 울리고 다음 박자를 박자 시계 기준으로 예약한다 (시간이 밀리지 않게).
  void _beat(int n) {
    if (!_running || !mounted) return;
    SystemSound.play(SystemSoundType.click);
    setState(() => _flash = true);
    Timer(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _flash = false);
    });
    final next = (n + 1) * _calibration.intervalMs;
    final wait = next - _clock.elapsedMilliseconds;
    _timer = Timer(
      Duration(milliseconds: wait < 0 ? 0 : wait),
      () => _beat(n + 1),
    );
  }

  void _tap() {
    if (!_running) return;
    _offsets.add(_calibration.offsetOf(_clock.elapsedMilliseconds));
    if (_offsets.length >= _taps) {
      _stop();
    } else {
      setState(() {});
    }
  }

  /// `01:02.30` 모양 (싱크 시간 표시에서 대괄호만 뺀 것).
  static String _clockOf(Duration d) {
    final s = SyncDraft.formatStamp(d);
    return s.substring(1, s.length - 1);
  }

  String _seconds(int ms) => (ms / 1000).toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final settings = context.watch<LyricsSettingsCubit>();
    final latency = settings.state.latencyMs;
    final recommended = _running
        ? null
        : LatencyCalibration.recommend(_offsets);
    final np = context.watch<NowPlayingCubit>();
    final stamped = _tried;

    Widget section(String title, String body) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(body, style: text.bodySmall?.copyWith(color: p.onSurfaceMuted)),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: l10n.lyricsLatencyTitle,
              leading: CircleIconButton(
                icon: AppIcons.back,
                tooltip: l10n.actionCancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  Text(
                    l10n.lyricsLatencyIntro,
                    style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: StatNumber(
                      l10n.lyricsLatencySeconds(_seconds(latency)),
                      size: 40,
                      color: p.accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      PlainButton(
                        label: '−0.01',
                        onPressed: () => settings.setLatency(latency - 10),
                      ),
                      Expanded(
                        child: AppSlider(
                          semanticLabel: l10n.lyricsLatencyTitle,
                          value: latency.toDouble(),
                          max: LyricsSettings.maxLatencyMs.toDouble(),
                          onChanged: (v) =>
                              settings.setLatency((v / 10).round() * 10),
                        ),
                      ),
                      PlainButton(
                        label: '+0.01',
                        onPressed: () => settings.setLatency(latency + 10),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: PlainButton(
                      label: l10n.lyricsLatencyReset,
                      onPressed: () =>
                          settings.setLatency(LyricsSettings.defaultLatencyMs),
                    ),
                  ),
                  Container(height: 1, color: p.outline),
                  section(l10n.lyricsBeatTitle, l10n.lyricsBeatBody),
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => _tap(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _flash
                              ? p.accent
                              : p.accent.withValues(alpha: .18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _running
                              ? l10n.lyricsBeatProgress(_offsets.length, _taps)
                              : l10n.lyricsBeatIdle,
                          style: text.titleMedium?.copyWith(
                            color: _flash ? p.background : p.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PillButton(
                        label: _running
                            ? l10n.lyricsBeatStop
                            : l10n.lyricsBeatStart,
                        icon: _running ? AppIcons.pause : AppIcons.play,
                        onPressed: _running ? _stop : _start,
                      ),
                    ],
                  ),
                  if (recommended != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Text(
                        l10n.lyricsBeatResult(_seconds(recommended)),
                        style: text.titleSmall?.copyWith(color: p.accent),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: PlainButton(
                        label: l10n.lyricsBeatApply,
                        accent: true,
                        onPressed: () => settings.setLatency(recommended),
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      l10n.lyricsBeatNote,
                      style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(height: 1, color: p.outline),
                  section(l10n.lyricsSongCheckTitle, l10n.lyricsSongCheckBody),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      PillButton(
                        label: np.state.isPlaying
                            ? l10n.lyricsSyncPause
                            : l10n.lyricsSyncPlay,
                        icon: np.state.isPlaying
                            ? AppIcons.pause
                            : AppIcons.play,
                        variant: PillVariant.tonal,
                        onPressed: np.togglePlay,
                      ),
                      PillButton(
                        label: l10n.lyricsSongTry,
                        icon: AppIcons.touch,
                        onPressed: () {
                          final at =
                              np.state.position -
                              Duration(milliseconds: latency);
                          setState(
                            () => _tried = at < Duration.zero
                                ? Duration.zero
                                : at,
                          );
                        },
                      ),
                    ],
                  ),
                  if (stamped != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Text(
                          l10n.lyricsSongTried(_clockOf(stamped)),
                          style: text.titleSmall,
                        ),
                        const Spacer(),
                        PlainButton(
                          label: l10n.lyricsSongListen,
                          icon: AppIcons.replay,
                          accent: true,
                          onPressed: () {
                            np.seekTo(stamped);
                            if (!np.state.isPlaying) np.togglePlay();
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
