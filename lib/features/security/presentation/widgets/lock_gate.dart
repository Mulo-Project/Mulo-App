import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/app_lock_settings.dart';
import '../bloc/app_lock_cubit.dart';

/// 앱 위에 덮는 잠금. 앱 잠금이 켜져 있으면 PIN(또는 생체 인증)을 풀 때까지
/// 내용을 가린다. 설정을 불러오는 동안에도 가려서 잠깐 보이는 일이 없게 한다.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 백그라운드에서 돌아올 때(알림을 눌러 들어온 경우 포함) 잠금을 다시 건다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cubit = context.read<AppLockCubit>();
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        cubit.appLeft();
      case AppLifecycleState.resumed:
        cubit.appReturned();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppLockCubit, AppLockState>(
      buildWhen: (a, b) => a.loaded != b.loaded || a.locked != b.locked,
      builder: (context, s) {
        final covered = !s.loaded || s.locked;
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (covered)
              Positioned.fill(
                child: s.loaded ? const LockScreen() : const _LockCover(),
              ),
          ],
        );
      },
    );
  }
}

/// 설정을 불러오는 동안 내용을 가리는 빈 배경.
class _LockCover extends StatelessWidget {
  const _LockCover();

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: context.palette.background);
}

/// 잠금 화면: PIN 입력 + (켜져 있으면) 생체 인증 버튼.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  bool _wrong = false;
  bool _checking = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 생체 인증이 켜져 있으면 열자마자 한 번 묻는다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    if (!mounted) return;
    final cubit = context.read<AppLockCubit>();
    if (!cubit.state.biometricEnabled) return;
    await cubit.unlockWithBiometric(context.l10n.biometricReason);
  }

  void _digit(int d) {
    if (_pin.length >= AppLockSettings.pinMaxLength) return;
    setState(() {
      _pin += '$d';
      _wrong = false;
    });
    if (_pin.length == AppLockSettings.pinMaxLength) _submit();
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _wrong = false;
    });
  }

  Future<void> _submit() async {
    if (_checking || _pin.length < AppLockSettings.pinMinLength) return;
    final cubit = context.read<AppLockCubit>();
    _checking = true;
    final ok = await cubit.unlock(_pin);
    _checking = false;
    if (!mounted || ok) return;
    setState(() {
      _pin = '';
      _wrong = true;
    });
    if (cubit.inCooldown) {
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        if (!cubit.inCooldown) _ticker?.cancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<AppLockCubit>();
    final s = context.watch<AppLockCubit>().state;

    final until = s.cooldownUntil;
    final remaining = cubit.inCooldown
        ? until!.difference(DateTime.now()).inSeconds + 1
        : 0;
    final message = remaining > 0
        ? l10n.pinCooldown(remaining)
        : _wrong
        ? l10n.pinWrong
        : l10n.lockHint;

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.screen,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.lock, size: 36, color: p.accent),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.lockTitle, style: text.headlineMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    message,
                    style: text.bodyMedium?.copyWith(
                      color: _wrong || remaining > 0
                          ? Theme.of(context).colorScheme.error
                          : p.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PinPad(
                    length: _pin.length,
                    maxLength: AppLockSettings.pinMaxLength,
                    onDigit: _digit,
                    onBackspace: _backspace,
                    backspaceLabel: l10n.pinBackspace,
                    enabled: remaining == 0,
                    error: _wrong,
                    leading: s.biometricEnabled
                        // 잠금은 Navigator 위에 떠 있어 Tooltip(Overlay)을 못 쓴다.
                        ? Semantics(
                            button: true,
                            label: l10n.pinUseBiometric,
                            excludeSemantics: true,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _tryBiometric,
                              child: const Icon(AppIcons.fingerprint),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PillButton(
                    label: l10n.pinSubmit,
                    onPressed:
                        _pin.length >= AppLockSettings.pinMinLength &&
                            remaining == 0
                        ? _submit
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
