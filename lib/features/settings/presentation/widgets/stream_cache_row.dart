import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../search/domain/entities/stream_cache_info.dart';
import '../../../search/presentation/bloc/stream_cache_cubit.dart';

const _mb = 1024 * 1024;

/// 바이트를 "120 MB" · "1.5 GB"처럼 짧게.
String formatBytes(int bytes) {
  if (bytes >= 1024 * _mb) {
    return '${(bytes / (1024 * _mb)).toStringAsFixed(1)} GB';
  }
  return '${(bytes / _mb).round()} MB';
}

/// 스트리밍 임시 저장소: 사용량을 보여 주고, 누르면 비운다 (한도는 고정이라 고르지 않는다).
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
        trailing: Text(
          l10n.settingsStreamCacheClear,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: info.usedBytes == 0
                ? context.palette.onSurfaceMuted
                : context.palette.accent,
          ),
        ),
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
    );
  }
}
