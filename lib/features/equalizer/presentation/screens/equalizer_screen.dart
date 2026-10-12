import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/equalizer_settings.dart';
import '../bloc/equalizer_cubit.dart';
import '../bloc/equalizer_library_cubit.dart';
import '../widgets/device_equalizer_section.dart';

/// 이퀄라이저: 켜고 끄기 · 프리셋 · 대역별 조절 · 효과. 손대는 즉시 소리에 반영되고,
/// "저장"을 눌러야 저장된다 (저장하지 않고 나가면 저장된 값으로 되돌아간다).
class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  late final EqualizerCubit _cubit = context.read<EqualizerCubit>();

  @override
  void dispose() {
    _cubit.discard();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: BlocBuilder<EqualizerCubit, EqualizerState>(
            builder: (context, state) {
              final info = state.info;
              final s = state.settings;
              final on = s.enabled;
              final cubit = _cubit;

              Widget gap([double h = AppSpacing.lg]) => SizedBox(height: h);
              Widget divider() => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(height: 1, thickness: 1, color: p.outline),
              );
              Widget padded(Widget child) =>
                  Padding(padding: AppSpacing.screen, child: child);

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
                              style: text.bodyMedium,
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.lg,
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
                              if (state.device case final device?) ...[
                                SettingRow(
                                  title: l10n.equalizerDeviceProfile,
                                  description: l10n.equalizerDeviceProfileDesc(
                                    deviceLabel(l10n, device),
                                  ),
                                  trailing: AppSwitch(
                                    value: device.hasProfile,
                                    onChanged: cubit.setDeviceProfile,
                                  ),
                                ),
                              ],
                              divider(),
                              gap(AppSpacing.sm),
                              padded(_Label(l10n.equalizerPreset)),
                              padded(
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
                              ),
                              gap(),
                              padded(_Label(l10n.equalizerMyPresets)),
                              padded(
                                BlocBuilder<
                                  EqualizerLibraryCubit,
                                  EqualizerLibraryState
                                >(
                                  builder: (context, lib) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: AppSpacing.xs,
                                        runSpacing: AppSpacing.xs,
                                        children: [
                                          for (final preset in lib.presets)
                                            GestureDetector(
                                              onLongPress: () => _confirmDelete(
                                                context,
                                                preset,
                                              ),
                                              child: PillButton(
                                                compact: true,
                                                variant: PillVariant.tonal,
                                                label: preset.name,
                                                onPressed: on
                                                    ? () =>
                                                          cubit.applyUserPreset(
                                                            preset.settings,
                                                          )
                                                    : null,
                                              ),
                                            ),
                                          PillButton(
                                            compact: true,
                                            icon: AppIcons.add,
                                            label: l10n.equalizerPresetSaveNew,
                                            onPressed: () => _askName(
                                              context,
                                              state.settings,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (lib.presets.isNotEmpty) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          l10n.equalizerMyPresetsHint,
                                          style: text.bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              gap(),
                              padded(_Label(l10n.equalizerBands)),
                              padded(
                                SizedBox(
                                  height: 240,
                                  child: Row(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < info.bandHz.length;
                                        i++
                                      )
                                        Expanded(
                                          child: _Band(
                                            hz: info.bandHz[i],
                                            db: s.levels[i],
                                            min: info.minDb,
                                            max: info.maxDb,
                                            onChanged: on
                                                ? (v) => cubit.setBand(i, v)
                                                : null,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              divider(),
                              if (info.bassBoostSupported)
                                SettingRow(
                                  title: l10n.equalizerBassBoost,
                                  description: l10n.equalizerBassBoostDesc,
                                  below: AppSlider(
                                    value: s.bassBoost,
                                    semanticLabel: l10n.equalizerBassBoost,
                                    onChanged: on ? cubit.setBassBoost : null,
                                  ),
                                ),
                              if (info.virtualizerSupported)
                                SettingRow(
                                  title: l10n.equalizerVirtualizer,
                                  description: l10n.equalizerVirtualizerDesc,
                                  below: AppSlider(
                                    value: s.virtualizer,
                                    semanticLabel: l10n.equalizerVirtualizer,
                                    onChanged: on ? cubit.setVirtualizer : null,
                                  ),
                                ),
                              if (info.reverbSupported)
                                SettingRow(
                                  title: l10n.equalizerReverb,
                                  description: l10n.equalizerReverbDesc,
                                  below: Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: AppSpacing.xs,
                                    children: [
                                      for (final r in EqualizerReverb.values)
                                        PillButton(
                                          compact: true,
                                          variant: PillVariant.tonal,
                                          selected: s.reverb == r,
                                          label: _reverbLabel(l10n, r),
                                          onPressed: on
                                              ? () => cubit.selectReverb(r)
                                              : null,
                                        ),
                                    ],
                                  ),
                                ),
                              if (info.limiterSupported)
                                SettingRow(
                                  title: l10n.equalizerLimiter,
                                  description: l10n.equalizerLimiterDesc,
                                  trailing: AppSwitch(
                                    value: s.limiter,
                                    onChanged: on ? cubit.setLimiter : null,
                                  ),
                                ),
                            ],
                          ),
                  ),
                  if (info != null)
                    Padding(
                      padding: AppSpacing.screen.copyWith(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: PillButton(
                              variant: PillVariant.tonal,
                              label: l10n.equalizerReset,
                              onPressed: on ? cubit.reset : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: PillButton(
                              icon: AppIcons.check,
                              label: l10n.equalizerSave,
                              onPressed: on && state.dirty ? cubit.save : null,
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

String _reverbLabel(AppLocalizations l10n, EqualizerReverb r) => switch (r) {
  EqualizerReverb.none => l10n.equalizerReverbNone,
  EqualizerReverb.smallRoom => l10n.equalizerReverbSmallRoom,
  EqualizerReverb.mediumRoom => l10n.equalizerReverbMediumRoom,
  EqualizerReverb.largeRoom => l10n.equalizerReverbLargeRoom,
  EqualizerReverb.mediumHall => l10n.equalizerReverbMediumHall,
  EqualizerReverb.largeHall => l10n.equalizerReverbLargeHall,
  EqualizerReverb.plate => l10n.equalizerReverbPlate,
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
  });

  final int hz;
  final double db;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

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
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(_hz(hz), style: text.labelSmall),
      ],
    );
  }
}

/// 지금 값을 새 프리셋으로 저장하려고 이름을 묻는다.
Future<void> _askName(BuildContext context, EqualizerSettings settings) async {
  final library = context.read<EqualizerLibraryCubit>();
  final name = await showDialog<String>(
    context: context,
    builder: (_) => const _NameDialog(),
  );
  if (name != null) await library.saveNew(name, settings);
}

Future<void> _confirmDelete(
  BuildContext context,
  EqualizerUserPreset preset,
) async {
  final library = context.read<EqualizerLibraryCubit>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = context.l10n;
      return AppDialog(
        title: l10n.equalizerPresetDeleteTitle,
        body: l10n.equalizerPresetDeleteBody(preset.name),
        actions: [
          PillButton(
            label: l10n.actionCancel,
            variant: PillVariant.tonal,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          PillButton(
            label: l10n.equalizerPresetDeleteTitle,
            icon: AppIcons.delete,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  );
  if (ok == true) await library.delete(preset.id);
}

class _NameDialog extends StatefulWidget {
  const _NameDialog();

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(_name.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialog(
      title: l10n.equalizerPresetNameTitle,
      content: AppTextField(
        label: l10n.equalizerPresetNameHint,
        controller: _name,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(context).pop(),
        ),
        PillButton(label: l10n.equalizerPresetSave, onPressed: _save),
      ],
    );
  }
}
