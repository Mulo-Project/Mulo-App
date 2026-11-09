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
    VideoQuality.standard => l10n.videoQualityStandard,
    VideoQuality.high => l10n.videoQualityHigh,
  };
}

/// "영상 화질" 시트: 고르면 바로 저장되고, [onChanged]가 있으면 (듣는 중인 영상을 새 화질로 다시 틀 때) 불린다.
/// 이 화질은 다음 미리 듣기에도 쓰인다. 영상 화면에 붙어 쓰는 공통 시트라 다른 영상(저장해 둔 영상 등)에도 쓸 수 있다.
Future<void> showVideoQualitySheet(
  BuildContext context, {
  ValueChanged<VideoQuality>? onChanged,
}) {
  final cubit = context.read<VideoQualityCubit>();
  return showAppSheet<void>(
    context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _VideoQualitySheet(onChanged: onChanged),
    ),
  );
}

class _VideoQualitySheet extends StatelessWidget {
  const _VideoQualitySheet({this.onChanged});

  final ValueChanged<VideoQuality>? onChanged;

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
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final changed = quality != current;
                  await context.read<VideoQualityCubit>().set(quality);
                  navigator.pop();
                  if (changed) onChanged?.call(quality);
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
