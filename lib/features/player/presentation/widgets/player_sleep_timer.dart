import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/now_playing_cubit.dart';
import 'player_common.dart';

// 수면 타이머 버튼 · 시간 고르는 대화상자 (player_common에서 나눔).

/// 수면 타이머: 시계 휠 대화상자에서 정한 시간 뒤에 재생을 멈춘다.
class SleepTimerButton extends StatelessWidget {
  const SleepTimerButton({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final on = data.state.sleepMinutes != null;
    return Builder(
      builder: (btn) => IconButton(
        tooltip: l10n.playerSleepTimer,
        onPressed: () => showSleepTimerPicker(btn, data.vm),
        icon: on
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.sleep, color: p.accent),
                  const SizedBox(width: AppSpacing.xs),
                  _SleepRemaining(endsAt: data.state.sleepEndsAt),
                ],
              )
            : Icon(AppIcons.sleepOutline, color: p.onSurfaceMuted),
      ),
    );
  }
}

/// 수면 타이머 시간 고르기: 대화상자에서 정한 시간 뒤에 재생을 멈춘다 (0이면 끈다).
/// 플레이어 화면과 설정 화면에서 같이 쓴다.
Future<void> showSleepTimerPicker(BuildContext context, NowPlayingCubit vm) async {
  final picked = await showDialog<int>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _SleepTimerDialog(
      current: _remainingMinutes(vm.state.sleepEndsAt),
    ),
  );
  if (picked == null || !context.mounted) return;
  // 타이머 상태가 화면에 보이므로 따로 안내하지 않는다.
  vm.setSleepTimer(picked == 0 ? null : picked);
}

/// 남은 시간을 올림한 분 (꺼져 있으면 null).
int? _remainingMinutes(DateTime? endsAt) {
  if (endsAt == null) return null;
  final left = endsAt.difference(DateTime.now());
  return left.isNegative ? null : (left.inSeconds / 60).ceil();
}

/// 수면 타이머가 켜져 있을 때 버튼 옆에 보이는 남은 시간 (`1:05:00` / `12:30`).
class _SleepRemaining extends StatefulWidget {
  const _SleepRemaining({required this.endsAt});

  final DateTime? endsAt;

  @override
  State<_SleepRemaining> createState() => _SleepRemainingState();
}

class _SleepRemainingState extends State<_SleepRemaining> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final end = widget.endsAt;
    if (end == null) return const SizedBox.shrink();
    final left = end.difference(DateTime.now());
    final s = left.isNegative ? 0 : left.inSeconds;
    String two(int n) => n.toString().padLeft(2, '0');
    final label = s >= 3600
        ? '${s ~/ 3600}:${two(s % 3600 ~/ 60)}:${two(s % 60)}'
        : '${two(s ~/ 60)}:${two(s % 60)}';
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: context.palette.accent,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// 휠 옆에 고정된 단위 글자 (시간 · 분).
class _WheelUnit extends StatelessWidget {
  const _WheelUnit(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: AppSpacing.xs),
    child: Text(
      label,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: context.palette.onSurfaceMuted),
    ),
  );
}

/// 수면 타이머 시간 고르기: 시간 · 분 휠을 돌려 정한다. 시작하면 총 분, 끄기는 0으로 닫는다.
class _SleepTimerDialog extends StatefulWidget {
  const _SleepTimerDialog({required this.current});

  final int? current;

  @override
  State<_SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<_SleepTimerDialog> {
  late int _hours = (widget.current ?? 30) ~/ 60;
  late int _minutes = (widget.current ?? 30) % 60;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = _hours * 60 + _minutes;
    return AppDialog(
      title: l10n.playerSleepTimer,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WheelPicker(
            count: 24,
            value: _hours,
            onChanged: (v) => setState(() => _hours = v),
          ),
          _WheelUnit(l10n.playerSleepTimerUnitHour),
          const SizedBox(width: AppSpacing.md),
          WheelPicker(
            count: 60,
            value: _minutes,
            onChanged: (v) => setState(() => _minutes = v),
          ),
          _WheelUnit(l10n.playerSleepTimerUnitMinute),
        ],
      ),
      actions: [
        if (widget.current != null)
          PillButton(
            label: l10n.playerSleepTimerOff,
            variant: PillVariant.tonal,
            onPressed: () => Navigator.of(context).pop(0),
          )
        else
          PillButton(
            label: l10n.actionCancel,
            variant: PillVariant.tonal,
            onPressed: () => Navigator.of(context).pop(),
          ),
        PillButton(
          label: l10n.playerSleepTimerStart,
          onPressed: total == 0 ? null : () => Navigator.of(context).pop(total),
        ),
      ],
    );
  }
}
