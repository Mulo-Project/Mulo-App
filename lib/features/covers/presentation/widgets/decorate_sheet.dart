import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/cover_color_cubit.dart';
import '../bloc/cover_cubit.dart';
import 'cover_editor_page.dart';
import 'cover_picker.dart';

/// 꾸미기 시트: 곡 · 앨범 · 아티스트 · 재생목록의 이미지와 색을 한 곳에서 바꾼다.
/// 미리보기를 보면서 사진을 고르거나 색을 고르면 바로 저장된다.
/// 이미지가 있으면 카드에는 이미지가 보이고, 색은 이미지를 지웠을 때 쓰인다.
/// [allowColor]가 false면 색 고르기를 숨긴다 (좋아요 목록).
Future<void> showDecorateSheet(
  BuildContext context, {
  required String coverKey,
  required String title,
  GlowTone tone = GlowTone.neutral,
  IconData icon = AppIcons.musicNote,
  bool allowColor = true,
}) {
  final covers = context.read<CoverCubit>();
  final colors = context.read<CoverColorCubit>();
  return showAppSheet<void>(
    context,
    isScrollControlled: true,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: covers),
        BlocProvider.value(value: colors),
      ],
      child: _DecorateSheet(
        coverKey: coverKey,
        title: title,
        tone: tone,
        icon: icon,
        allowColor: allowColor,
      ),
    ),
  );
}

class _DecorateSheet extends StatelessWidget {
  const _DecorateSheet({
    required this.coverKey,
    required this.title,
    required this.tone,
    required this.icon,
    required this.allowColor,
  });

  final String coverKey;
  final String title;
  final GlowTone tone;
  final IconData icon;
  final bool allowColor;

  /// 이미지를 고르고 확대 · 위치를 맞춘 뒤 저장한다.
  Future<void> _pick(BuildContext context, CoverCubit covers) async {
    final picked = await pickCoverArt(context, initialQuery: title);
    if (picked != null) await covers.setArt(coverKey, picked);
  }

  /// 이미 붙인 이미지의 확대 · 위치만 다시 맞춘다.
  Future<void> _adjust(
    BuildContext context,
    CoverCubit covers,
    CoverArt art,
  ) async {
    final edited = await showCoverEditor(context, art);
    if (edited != null) await covers.setTransform(coverKey, edited.transform);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final image = coverImageOf(context, coverKey);
    final art = context.select<CoverCubit, CoverArt?>((c) => c.state[coverKey]);
    final color = coverColorOf(context, coverKey);
    final covers = context.read<CoverCubit>();
    final colors = context.read<CoverColorCubit>();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: appSheetPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ArtworkBox(
                    image: image,
                    size: 72,
                    radius: AppRadii.sm,
                    tone: tone,
                    color: color,
                    icon: icon,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.decorateTitle, style: text.titleMedium),
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
              Text(l10n.decorateImage, style: text.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: l10n.coverPick,
                      icon: AppIcons.photoLibrary,
                      onPressed: () => _pick(context, covers),
                    ),
                  ),
                  if (image != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: PillButton(
                        label: l10n.coverReset,
                        icon: AppIcons.restart,
                        variant: PillVariant.tonal,
                        onPressed: () => covers.clear(coverKey),
                      ),
                    ),
                  ],
                ],
              ),
              if (art != null) ...[
                const SizedBox(height: AppSpacing.xs),
                PillButton(
                  label: l10n.coverAdjust,
                  icon: AppIcons.tune,
                  variant: PillVariant.tonal,
                  onPressed: () => _adjust(context, covers, art),
                ),
              ],
              if (allowColor) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.decorateColor, style: text.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                ColorPicker(
                  selected: color,
                  autoLabel: l10n.playlistColorAuto,
                  customLabel: l10n.colorCustom,
                  optionLabel: l10n.colorOption,
                  onChanged: (c) => c == null
                      ? colors.clear(coverKey)
                      : colors.setColor(coverKey, c),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
