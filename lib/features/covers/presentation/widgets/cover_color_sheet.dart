import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/cover_color_cubit.dart';

/// 커버 색 바꾸기 시트: 미리보기 + 색 견본 · 색상 막대. 고르는 즉시 저장된다.
/// 이미지가 있으면 카드에는 이미지가 보이고, 색은 이미지를 지웠을 때 쓰인다.
Future<void> showCoverColorSheet(
  BuildContext context, {
  required String colorKey,
  required String title,
  GlowTone tone = GlowTone.primary,
}) {
  final colors = context.read<CoverColorCubit>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.palette.surface,
    showDragHandle: true,
    isScrollControlled: true,
    // 탭 틀(미니 플레이어 · 탭 바) 위에 뜨도록 최상위 내비게이터에서 연다.
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.md)),
    ),
    builder: (_) => BlocProvider.value(
      value: colors,
      child: _CoverColorSheet(colorKey: colorKey, title: title, tone: tone),
    ),
  );
}

class _CoverColorSheet extends StatelessWidget {
  const _CoverColorSheet({
    required this.colorKey,
    required this.title,
    required this.tone,
  });

  final String colorKey;
  final String title;
  final GlowTone tone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final color = coverColorOf(context, colorKey);
    final colors = context.read<CoverColorCubit>();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ArtworkBox(
                    size: 56,
                    radius: AppRadii.sm,
                    tone: tone,
                    color: color,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.colorSheetTitle, style: text.titleMedium),
                        Text(
                          title,
                          style: text.bodySmall?.copyWith(
                            color: context.palette.onSurfaceMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ColorPicker(
                selected: color,
                autoLabel: l10n.playlistColorAuto,
                customLabel: l10n.colorCustom,
                optionLabel: l10n.colorOption,
                onChanged: (c) => c == null
                    ? colors.clear(colorKey)
                    : colors.setColor(colorKey, c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
