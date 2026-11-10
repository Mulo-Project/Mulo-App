import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/video_quality.dart';
import '../bloc/preview_cubit.dart';
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
Future<({VideoQuality? quality})?> pickSaveQuality(
  BuildContext context, {
  VideoQuality? initial,
}) {
  return showAppSheet<({VideoQuality? quality})>(
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
  /// null이면 '소리만' 저장한다.
  late VideoQuality? _selected = widget.initial;

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
            ChoiceChips(
              items: [
                // 소리만: 영상은 받지 않아 용량이 훨씬 작다.
                ChoiceChipItem(
                  key: const ValueKey('save-quality-audio'),
                  label: l10n.savedVideosAudioOnly,
                  selected: _selected == null,
                  onTap: () => setState(() => _selected = null),
                ),
                for (final quality in VideoQuality.values)
                  ChoiceChipItem(
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
                onPressed: () => Navigator.of(context).pop((quality: _selected)),
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
    final preview = context.read<PreviewCubit>();
    final auto = preview.autoQuality.value;
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
            // 자동: 낮은 화질로 빠르게 시작해 잠시 뒤 높인다 (영상 안의 옵션에는 없고 여기서만 정한다).
            InkWell(
                key: const ValueKey('video-quality-auto'),
                onTap: () {
                  preview.autoQuality.value = true;
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm + AppSpacing.xxs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.videoQualityAuto,
                        style: text.bodyLarge?.copyWith(
                          color: auto ? p.accent : p.onSurface,
                        ),
                      ),
                      Text(
                        l10n.videoQualityAutoHint,
                        style: text.bodySmall?.copyWith(
                          color: p.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            for (final quality in VideoQuality.values)
              InkWell(
                key: ValueKey('video-quality-${quality.name}'),
                onTap: () {
                  preview.autoQuality.value = false;
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
                            color: !auto && quality == current
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

/// [ChoiceChips]의 선택 버튼 하나.
class ChoiceChipItem {
  const ChoiceChipItem({
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

/// 하나를 고르는 선택 버튼 줄 (화질 · 용량 등): 가로로 스크롤된다.
class ChoiceChips extends StatelessWidget {
  const ChoiceChips({super.key, required this.items});

  final List<ChoiceChipItem> items;

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
