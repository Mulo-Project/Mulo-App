import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/equalizer_settings.dart';
import '../bloc/equalizer_cubit.dart';

/// 이퀄라이저: 켜고 끄기 · 프리셋 · 대역별 조절 · 저음 강화. 바꾼 값은 바로 소리에 반영되고 저장된다.
class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: BlocBuilder<EqualizerCubit, EqualizerState>(
            builder: (context, state) {
              final cubit = context.read<EqualizerCubit>();
              final info = state.info;
              final s = state.settings;
              final on = s.enabled;
              return Column(
                children: [
                  AppTopBar(
                    title: l10n.equalizerTitle,
                    leading: CircleIconButton(
                      icon: AppIcons.back,
                      tooltip: l10n.actionBack,
                      onPressed: () => context.pop(),
                    ),
                  ),
                  Expanded(
                    child: info == null
                        ? Center(
                            child: Text(
                              l10n.equalizerUnsupported,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : ListView(
                            padding: AppSpacing.screen.copyWith(
                              bottom: AppSpacing.xl,
                            ),
                            children: [
                              SettingRow(
                                title: l10n.equalizerEnable,
                                description: l10n.equalizerEnableDesc,
                                trailing: AppSwitch(
                                  value: on,
                                  onChanged: cubit.setEnabled,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _Label(l10n.equalizerPreset),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  for (final preset in EqualizerPreset.values)
                                    if (preset != EqualizerPreset.custom ||
                                        s.preset == EqualizerPreset.custom)
                                      PillButton(
                                        compact: true,
                                        variant: PillVariant.tonal,
                                        selected: s.preset == preset,
                                        label: _presetLabel(l10n, preset),
                                        onPressed: on
                                            ? () => cubit.selectPreset(preset)
                                            : null,
                                      ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _Label(l10n.equalizerBands),
                              SizedBox(
                                height: 240,
                                child: Row(
                                  children: [
                                    for (var i = 0; i < info.bandHz.length; i++)
                                      Expanded(
                                        child: _Band(
                                          hz: info.bandHz[i],
                                          db: s.levels[i],
                                          min: info.minDb,
                                          max: info.maxDb,
                                          onChanged: on
                                              ? (v) =>
                                                    cubit.setBandPreview(i, v)
                                              : null,
                                          onChangeEnd: cubit.commit,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (info.bassBoostSupported) ...[
                                const SizedBox(height: AppSpacing.md),
                                SettingRow(
                                  title: l10n.equalizerBassBoost,
                                  description: l10n.equalizerBassBoostDesc,
                                  below: AppSlider(
                                    value: s.bassBoost,
                                    semanticLabel: l10n.equalizerBassBoost,
                                    onChanged: on
                                        ? cubit.setBassBoostPreview
                                        : null,
                                    onChangeEnd: cubit.commit,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: PillButton(
                                  compact: true,
                                  variant: PillVariant.tonal,
                                  label: l10n.equalizerReset,
                                  onPressed: on ? cubit.reset : null,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

String _presetLabel(AppLocalizations l10n, EqualizerPreset preset) =>
    switch (preset) {
      EqualizerPreset.flat => l10n.equalizerPresetFlat,
      EqualizerPreset.bass => l10n.equalizerPresetBass,
      EqualizerPreset.treble => l10n.equalizerPresetTreble,
      EqualizerPreset.vocal => l10n.equalizerPresetVocal,
      EqualizerPreset.rock => l10n.equalizerPresetRock,
      EqualizerPreset.pop => l10n.equalizerPresetPop,
      EqualizerPreset.jazz => l10n.equalizerPresetJazz,
      EqualizerPreset.classical => l10n.equalizerPresetClassical,
      EqualizerPreset.dance => l10n.equalizerPresetDance,
      EqualizerPreset.custom => l10n.equalizerPresetCustom,
    };

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}

/// 대역 하나: 위에 dB, 가운데 세로 슬라이더, 아래에 주파수.
class _Band extends StatelessWidget {
  const _Band({
    required this.hz,
    required this.db,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final int hz;
  final double db;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final VoidCallback onChangeEnd;

  static String _hz(int hz) => hz >= 1000
      ? '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}k'
      : '$hz';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sign = db > 0.05 ? '+' : '';
    return Column(
      children: [
        Text('$sign${db.toStringAsFixed(1)}', style: text.labelSmall),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: AppSlider(
            vertical: true,
            centered: true,
            min: min,
            max: max,
            value: db,
            semanticLabel: '${_hz(hz)} Hz',
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(_hz(hz), style: text.labelSmall),
      ],
    );
  }
}
