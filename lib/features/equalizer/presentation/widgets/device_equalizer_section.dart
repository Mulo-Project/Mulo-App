import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/equalizer_settings.dart';
import '../bloc/equalizer_cubit.dart';
import '../bloc/equalizer_library_cubit.dart';

/// 설정의 "기기별 이퀄라이저": 연결된 적 있는 블루투스 · 이어폰 기기마다 만들어 둔 프리셋을 지정한다.
/// 그 기기가 연결되면 지정한 프리셋이 자동으로 적용된다. 이퀄라이저를 쓸 수 없는 환경에서는 숨긴다.
class DeviceEqualizerSection extends StatelessWidget {
  const DeviceEqualizerSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<EqualizerCubit>().state.supported) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final lib = context.watch<EqualizerLibraryCubit>().state;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: SectionCard(
        title: l10n.equalizerDevicesTitle,
        children: [
          if (lib.devices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(l10n.equalizerDevicesEmpty, style: text.bodyMedium),
            ),
          for (final device in lib.devices)
            SettingRow(
              title: deviceLabel(l10n, device),
              description: device.current ? l10n.equalizerDeviceCurrent : null,
              onTap: () => _pick(context, device),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lib.presetById(device.presetId)?.name ??
                        (device.hasProfile
                            ? l10n.equalizerDeviceCustom
                            : l10n.equalizerDeviceDefault),
                    style: text.bodySmall,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    AppIcons.chevronRight,
                    size: 18,
                    color: p.onSurfaceMuted,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context, EqualizerDevice device) {
    final library = context.read<EqualizerLibraryCubit>();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.surface,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.md)),
      ),
      builder: (sheet) {
        final l10n = sheet.l10n;
        final presets = library.state.presets;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.equalizerDevicePickTitle(deviceLabel(l10n, device)),
                  style: Theme.of(sheet).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                MenuRow(
                  icon: device.hasProfile ? AppIcons.equalizer : AppIcons.check,
                  label: l10n.equalizerDeviceDefault,
                  onTap: () {
                    library.assign(device.key, null);
                    Navigator.of(sheet).pop();
                  },
                ),
                for (final preset in presets) ...[
                  const SizedBox(height: AppSpacing.xs),
                  MenuRow(
                    icon: preset.id == device.presetId
                        ? AppIcons.check
                        : AppIcons.equalizer,
                    label: preset.name,
                    onTap: () {
                      library.assign(device.key, preset.id);
                      Navigator.of(sheet).pop();
                    },
                  ),
                ],
                if (presets.isEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.equalizerDeviceNoPresets,
                    style: Theme.of(sheet).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 기기 이름 (이름이 없으면 종류 이름).
String deviceLabel(AppLocalizations l10n, EqualizerDevice device) {
  if (device.name.isNotEmpty) return device.name;
  return switch (device.kind) {
    'wired' => l10n.outputWired,
    'bluetooth' => l10n.outputBluetooth,
    'usb' => l10n.outputUsb,
    _ => l10n.outputSpeaker,
  };
}
