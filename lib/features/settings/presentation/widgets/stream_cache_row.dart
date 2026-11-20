import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/format/format_bytes.dart';
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
  streamCacheUnlimited,
];

/// 한도 이름: 무제한이면 "무제한", 아니면 용량.
String streamCacheLimitLabel(AppLocalizations l10n, int limit) =>
    limit >= streamCacheUnlimited
        ? l10n.settingsStreamCacheUnlimited
        : formatBytes(limit);

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
          formatBytes(info.usedBytes + info.savedBytes),
          streamCacheLimitLabel(l10n, info.limitBytes),
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
              subtitle: info.unlimited
                  ? l10n.settingsStreamCacheUnlimitedHint(
                      formatBytes(info.usedBytes + info.savedBytes),
                    )
                  : l10n.settingsStreamCacheLimitHint(
                      formatBytes(info.usedBytes + info.savedBytes),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            // 용량은 가로로 스크롤되는 선택 버튼 줄이다.
            ChoiceChips(
              items: [
                for (final limit in streamCacheLimits)
                  ChoiceChipItem(
                    key: ValueKey('stream-cache-limit-$limit'),
                    label: streamCacheLimitLabel(l10n, limit),
                    selected: info.limitBytes == limit,
                    onTap: () => cubit.setLimit(limit),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
