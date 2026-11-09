import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../search/domain/entities/stream_cache_info.dart';
import '../../../search/presentation/bloc/stream_cache_cubit.dart';

const _mb = 1024 * 1024;

/// 고를 수 있는 한도 (바이트). 0은 끔.
const streamCacheLimits = [0, 200 * _mb, 500 * _mb, 1024 * _mb, 2048 * _mb];

/// 바이트를 "120 MB" · "1.5 GB"처럼 짧게.
String formatBytes(int bytes) {
  if (bytes >= 1024 * _mb) return '${(bytes / (1024 * _mb)).toStringAsFixed(1)} GB';
  return '${(bytes / _mb).round()} MB';
}

String streamCacheLimitLabel(BuildContext context, int bytes) =>
    bytes <= 0 ? context.l10n.settingsStreamCacheOff : formatBytes(bytes);

/// 스트리밍 임시 저장소: 한도를 고르고 지금 비운다.
Future<void> showStreamCacheSheet(BuildContext context) {
  final cubit = context.read<StreamCacheCubit>();
  return showAppSheet<void>(
    context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _StreamCacheSheet(),
    ),
  );
}

class _StreamCacheSheet extends StatelessWidget {
  const _StreamCacheSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final info = context.watch<StreamCacheCubit>().state;
    return SafeArea(
      child: Padding(
        padding: appSheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetTitle(
              l10n.settingsStreamCache,
              subtitle: l10n.settingsStreamCacheHint,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final limit in streamCacheLimits)
              SettingRow(
                title: streamCacheLimitLabel(context, limit),
                trailing: limit == info.limitBytes
                    ? Icon(AppIcons.check, color: context.palette.primary)
                    : null,
                onTap: () => context.read<StreamCacheCubit>().setLimit(limit),
              ),
            SettingRow(
              title: l10n.settingsStreamCacheClear,
              description: formatBytes(info.usedBytes),
              onTap: info.usedBytes == 0
                  ? null
                  : () async {
                      await context.read<StreamCacheCubit>().clear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.settingsStreamCacheCleared)),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

/// 설정 줄에 쓸 한 줄 요약.
String streamCacheSummary(BuildContext context, StreamCacheInfo info) =>
    info.enabled
    ? context.l10n.settingsStreamCacheDesc(
        formatBytes(info.usedBytes),
        formatBytes(info.limitBytes),
      )
    : context.l10n.settingsStreamCacheOff;
