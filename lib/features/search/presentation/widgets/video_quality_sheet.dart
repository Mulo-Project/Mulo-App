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

/// 저장할 영상 화질을 고르는 시트. 항목은 고르기만 하고, 아래 `담기`를 눌러야 그 화질을 돌려준다.
/// 그냥 닫으면 null (저장하지 않는다).
Future<VideoQuality?> pickSaveQuality(
  BuildContext context, {
  VideoQuality? initial,
}) {
  return showAppSheet<VideoQuality>(
    context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SaveQualitySheet(initial: initial ?? VideoQuality.standard),
  );
}

class _SaveQualitySheet extends StatefulWidget {
  const _SaveQualitySheet({required this.initial});

  final VideoQuality initial;

  @override
  State<_SaveQualitySheet> createState() => _SaveQualitySheetState();
}

class _SaveQualitySheetState extends State<_SaveQualitySheet> {
  late VideoQuality _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: appSheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetTitle(
              l10n.savedVideosQualityTitle,
              subtitle: l10n.savedVideosQualityHint,
            ),
            const SizedBox(height: AppSpacing.sm),
            // 화질은 가로로 스크롤되는 선택 버튼 줄이다.
            QualityChips(
              items: [
                for (final quality in VideoQuality.values)
                  QualityChip(
                    key: ValueKey('save-quality-${quality.name}'),
                    label: videoQualityLabel(context, quality),
                    selected: quality == _selected,
                    onTap: () => setState(() => _selected = quality),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: PillButton(
                key: const ValueKey('save-quality-confirm'),
                label: l10n.savedVideosConfirm,
                onPressed: () => Navigator.of(context).pop(_selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

/// [QualityChips]의 선택 버튼 하나.
class QualityChip {
  const QualityChip({
    this.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key? key;
  final String label;
  final bool selected;
  final VoidCallback onTap;
}

/// 화질을 고르는 선택 버튼 줄: 가로로 스크롤된다.
class QualityChips extends StatelessWidget {
  const QualityChips({super.key, required this.items});

  final List<QualityChip> items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            PillButton(
              key: items[i].key,
              label: items[i].label,
              compact: true,
              variant: PillVariant.tonal,
              selected: items[i].selected,
              onPressed: items[i].onTap,
            ),
          ],
        ],
      ),
    );
  }
}
