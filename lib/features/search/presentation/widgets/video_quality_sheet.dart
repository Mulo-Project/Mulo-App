import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/video_quality.dart';
import '../bloc/video_quality_cubit.dart';

/// 화질의 이름 (설정 줄 · 시트에서 같이 쓴다).
String videoQualityLabel(BuildContext context, VideoQuality quality) {
  final l10n = context.l10n;
  return switch (quality) {
    VideoQuality.low => l10n.videoQualityLow,
    VideoQuality.standard => l10n.videoQualityStandard,
    VideoQuality.medium => l10n.videoQualityMedium,
    VideoQuality.high => l10n.videoQualityHigh,
    VideoQuality.full => l10n.videoQualityFull,
  };
}

/// "영상 화질" 시트: 고르면 바로 저장되고 다음 미리 듣기부터 적용된다.
Future<void> showVideoQualitySheet(BuildContext context) {
  final cubit = context.read<VideoQualityCubit>();
  return showAppSheet<void>(
    context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _VideoQualitySheet(),
    ),
  );
}

class _VideoQualitySheet extends StatelessWidget {
  const _VideoQualitySheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final current = context.watch<VideoQualityCubit>().state;
    return SafeArea(
      child: Padding(
        padding: appSheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetTitle(
              l10n.videoQualityTitle,
              subtitle: l10n.videoQualityHint,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final quality in VideoQuality.values)
              InkWell(
                key: ValueKey('video-quality-${quality.name}'),
                onTap: () {
                  context.read<VideoQualityCubit>().set(quality);
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm + AppSpacing.xxs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          videoQualityLabel(context, quality),
                          style: text.bodyLarge?.copyWith(
                            color: quality == current
                                ? p.accent
                                : p.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
