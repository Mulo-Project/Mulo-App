import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/app_lock_settings.dart';
import '../bloc/app_lock_cubit.dart';

enum PinEntryMode {
  /// 새 PIN을 정하고(두 번 입력) 앱 잠금을 켠다.
  create,

  /// 현재 PIN(또는 생체 인증)을 확인한 뒤 앱 잠금을 끈다.
  disable,

  /// 현재 PIN(또는 생체 인증)을 확인한 뒤 새 PIN으로 바꾼다.
  change,
}

/// 입력 단계.
enum _Stage {
  /// 현재 PIN(또는 생체 인증) 확인.
  current,

  /// 새 PIN 입력.
  fresh,

  /// 새 PIN 한 번 더.
  confirm,
}

/// 설정에서 여는 PIN 입력 화면. 끝나면 성공 여부(true/false)로 닫힌다.
class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key, required this.mode});

  final PinEntryMode mode;

  /// 화면을 열고 끝날 때까지 기다린다. 성공하면 true.
  /// 최상위 내비게이터에서 열어 하단 탭 · 미니 플레이어를 가린다.
  static Future<bool> open(BuildContext context, PinEntryMode mode) async {
    final done = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<bool>(MaterialPageRoute(builder: (_) => PinEntryScreen(mode: mode)));
    return done ?? false;
  }

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  late _Stage _stage = widget.mode == PinEntryMode.create
      ? _Stage.fresh
      : _Stage.current;
  String _pin = '';

  /// 새 PIN 첫 입력값 (확인 단계에서 비교).
  String? _first;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // 생체 인증을 켜 둔 상태면 열자마자 한 번 묻는다 (PIN 대신 확인).
    if (_stage == _Stage.current) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  void _digit(int d) {
    if (_pin.length >= AppLockSettings.pinMaxLength) return;
    setState(() {
      _pin += '$d';
      _error = null;
    });
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _tryBiometric() async {
    if (!mounted || _stage != _Stage.current || _busy) return;
    final cubit = context.read<AppLockCubit>();
    await cubit.refreshBiometric();
    if (!mounted || !cubit.state.biometricEnabled) return;
    final ok = await cubit.confirmWithBiometric(context.l10n.biometricReason);
    if (ok && mounted) await _currentConfirmed();
  }

  /// 현재 PIN(또는 생체 인증) 확인을 마쳤을 때.
  Future<void> _currentConfirmed() async {
    final cubit = context.read<AppLockCubit>();
    final navigator = Navigator.of(context);
    if (widget.mode == PinEntryMode.disable) {
      await cubit.turnOffLock();
      if (mounted) navigator.pop(true);
    } else {
      setState(() {
        _stage = _Stage.fresh;
        _pin = '';
        _error = null;
        _busy = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_busy || _pin.length < AppLockSettings.pinMinLength) return;
    final l10n = context.l10n;
    final cubit = context.read<AppLockCubit>();
    final navigator = Navigator.of(context);
    setState(() => _busy = true);

    switch (_stage) {
      case _Stage.current:
        if (await cubit.checkPin(_pin)) {
          await _currentConfirmed();
        } else if (mounted) {
          setState(() {
            _pin = '';
            _error = l10n.pinWrong;
            _busy = false;
          });
        }
      case _Stage.fresh:
        setState(() {
          _first = _pin;
          _pin = '';
          _stage = _Stage.confirm;
          _busy = false;
        });
      case _Stage.confirm:
        if (_first == _pin) {
          // 만들기는 잠금을 켜고, 바꾸기는 PIN만 교체한다.
          if (widget.mode == PinEntryMode.create) {
            await cubit.enableLock(_pin);
          } else {
            await cubit.changePin(_pin);
          }
          if (mounted) navigator.pop(true);
        } else {
          setState(() {
            _first = null;
            _pin = '';
            _stage = _Stage.fresh;
            _error = l10n.pinMismatch;
            _busy = false;
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bio = context.select((AppLockCubit c) => c.state.biometricEnabled);

    final (title, hint) = switch (_stage) {
      _Stage.fresh => (l10n.pinCreateTitle, l10n.pinCreateHint),
      _Stage.confirm => (l10n.pinConfirmTitle, l10n.pinConfirmHint),
      _Stage.current => (
        l10n.pinCurrentTitle,
        switch ((widget.mode, bio)) {
          (_, true) => l10n.pinCurrentHintBiometric,
          (PinEntryMode.change, false) => l10n.pinCurrentHintChange,
          _ => l10n.pinCurrentHint,
        },
      ),
    };

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: title,
                leading: CircleIconButton(
                  icon: AppIcons.back,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: AppSpacing.screen,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error ?? hint,
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: _error != null
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
                          error: _error != null,
                          leading: _stage == _Stage.current && bio
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
                                  !_busy
                              ? _submit
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
