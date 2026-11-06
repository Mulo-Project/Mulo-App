import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/search_source.dart';

/// 검색 대상 사이트 이름 (화면 문구).
String sourceLabel(BuildContext context, SearchSource s) {
  final l10n = context.l10n;
  return switch (s) {
    SearchSource.youtube => l10n.sourceYoutube,
    SearchSource.soundcloud => l10n.sourceSoundcloud,
  };
}

/// 사이트 표시 (유튜브는 로고, 나머지는 브랜드 색 동그라미).
Widget sourceMark(SearchSource s, double size) => switch (s) {
  SearchSource.youtube => YoutubeMark(size: size),
  SearchSource.soundcloud => SoundcloudMark(size: size),
};

/// 검색창 오른쪽 버튼: 어느 사이트에서 찾을지 고른다.
/// 검색창에는 고른 사이트의 아이콘만, 눌러서 열리는 메뉴에는 아이콘 + 이름을 보여 준다.
class SearchSourceMenu extends StatelessWidget {
  const SearchSourceMenu({
    super.key,
    required this.source,
    required this.onChanged,
  });

  final SearchSource source;
  final ValueChanged<SearchSource> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PopupMenuButton<SearchSource>(
      tooltip: context.l10n.searchSourceTooltip,
      initialValue: source,
      onSelected: onChanged,
      color: p.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        side: BorderSide(color: p.outline),
      ),
      itemBuilder: (_) => [
        for (final s in SearchSource.values)
          PopupMenuItem(
            value: s,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                sourceMark(s, 20),
                const SizedBox(width: AppSpacing.xs),
                Text(sourceLabel(context, s)),
              ],
            ),
          ),
      ],
      // 아이콘 옆 작은 ▾로 눌러서 바꿀 수 있다는 것을 보여 준다.
      child: SizedBox(
        width: 64,
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            sourceMark(source, 24),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              AppIcons.dropDown,
              size: AppSizes.iconSm,
              color: p.onSurfaceMuted,
            ),
          ],
        ),
      ),
    );
  }
}
