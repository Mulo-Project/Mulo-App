import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../search/domain/entities/stream_cache_info.dart';
import '../../../search/presentation/bloc/stream_cache_cubit.dart';
import '../../../search/presentation/widgets/video_quality_sheet.dart'
    show ChoiceChipItem, ChoiceChips;
import 'settings_common.dart';

const _mb = 1024 * 1024;

/// 고를 수 있는 임시 저장 용량.
const streamCacheLimits = [
  250 * _mb,
  500 * _mb,
  1024 * _mb,
  2048 * _mb,
];

/// 바이트를 "120 MB" · "1.5 GB"처럼 짧게.
String formatBytes(int bytes) {
  if (bytes >= 1024 * _mb) {
    final gb = bytes / (1024 * _mb);
    return '${gb == gb.roundToDouble() ? gb.round() : gb.toStringAsFixed(1)} GB';
  }
  return '${(bytes / _mb).round()} MB';
}

/// 스트리밍 임시 저장소: 사용량 · 용량 한도를 보여 주고, 누르면 한도를 고르거나 비우는 시트가 열린다.
class StreamCacheRow extends StatelessWidget {
  const StreamCacheRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<StreamCacheCubit, StreamCacheInfo>(
      builder: (context, info) => SettingRow(
        title: l10n.settingsStreamCache,
        description: l10n.settingsStreamCacheDesc(
          formatBytes(info.usedBytes),
          formatBytes(info.limitBytes),
        ),
        trailing: const SettingsChevron(),
        onTap: () => _showSheet(context),
      ),
    );
  }

  Future<void> _showSheet(BuildContext context) {
    final cubit = context.read<StreamCacheCubit>();
    return showAppSheet<void>(
      context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const _StreamCacheSheet(),
      ),
    );
  }
}

class _StreamCacheSheet extends StatelessWidget {
  const _StreamCacheSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final info = context.watch<StreamCacheCubit>().state;
    final cubit = context.read<StreamCacheCubit>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: appSheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetTitle(
              l10n.settingsStreamCache,
              subtitle: l10n.settingsStreamCacheLimitHint(
                formatBytes(info.usedBytes),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // 용량은 가로로 스크롤되는 선택 버튼 줄이다.
            ChoiceChips(
              items: [
                for (final limit in streamCacheLimits)
                  ChoiceChipItem(
                    key: ValueKey('stream-cache-limit-$limit'),
                    label: formatBytes(limit),
                    selected: info.limitBytes == limit,
                    onTap: () => cubit.setLimit(limit),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: PillButton(
                key: const ValueKey('stream-cache-clear'),
                label: l10n.settingsStreamCacheClear,
                variant: PillVariant.tonal,
                compact: true,
                onPressed: info.usedBytes == 0
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final cleared = l10n.settingsStreamCacheCleared;
                        await cubit.clear();
                        messenger.showSnackBar(
                          SnackBar(content: Text(cleared)),
                        );
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
