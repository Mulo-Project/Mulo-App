import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/cover_color_cubit.dart';
import '../bloc/cover_cubit.dart';
import 'cover_editor_page.dart';
import 'cover_entry.dart';

/// 꾸미기 시트: 곡 · 앨범 · 아티스트 · 재생목록의 이미지와 색을 한 곳에서 바꾼다.
/// 이미지는 줄을 눌러 이미지 페이지([showCoverEditor])에서 고르고 · 맞추고 · 기본으로 되돌린다
/// (시트에는 그 모든 버튼을 따로 두지 않는다). 색을 고르면 바로 저장된다.
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

  /// 이미지 페이지를 열어 (지금 이미지가 있으면 그것을 불러온 채로) 결과를 저장한다.
  Future<void> _edit(
    BuildContext context,
    CoverCubit covers,
    CoverArt? art,
  ) async {
    final result = await showCoverEditor(
      context,
      art,
      initialQuery: title,
      canRevert: art != null,
    );
    if (result == null) return;
    if (result.reverted) {
      await covers.clear(coverKey);
    } else if (result.art != null) {
      await covers.setArt(coverKey, result.art!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              AppSheetTitle(l10n.decorateTitle, subtitle: title),
              const SizedBox(height: AppSpacing.lg),
              CoverEntry(
                image: image,
                label: l10n.decorateImage,
                tone: tone,
                color: color,
                icon: icon,
                onTap: () => _edit(context, covers, art),
              ),
              if (allowColor) ...[
                const SizedBox(height: AppSpacing.lg),
                const AppDivider(),
                const SizedBox(height: AppSpacing.md),
                SectionTitle(l10n.decorateColor, padded: false),
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
