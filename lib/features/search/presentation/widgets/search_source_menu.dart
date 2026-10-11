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
    SearchSource.bilibili => l10n.sourceBilibili,
    SearchSource.niconico => l10n.sourceNiconico,
  };
}

/// 사이트 표시 (유튜브는 로고, 나머지는 브랜드 색 동그라미).
Widget sourceMark(SearchSource s, double size) => switch (s) {
  SearchSource.youtube => YoutubeMark(size: size),
  SearchSource.soundcloud => SiteMark(
    letter: 'S',
    color: AppPalette.soundcloudOrange,
    size: size,
  ),
  SearchSource.bilibili => SiteMark(
    letter: 'B',
    color: AppPalette.bilibiliPink,
    size: size,
  ),
  SearchSource.niconico => SiteMark(
    letter: 'N',
    color: AppPalette.niconicoGray,
    size: size,
  ),
};

/// 검색창 왼쪽 버튼: 어느 사이트에서 찾을지 고른다.
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
            child: Row(
              children: [
                sourceMark(s, 22),
                const SizedBox(width: AppSpacing.xs),
                Text(sourceLabel(context, s)),
              ],
            ),
          ),
      ],
      child: SizedBox(
        width: 44,
        height: 52,
        child: Center(child: sourceMark(source, 24)),
      ),
    );
  }
}
