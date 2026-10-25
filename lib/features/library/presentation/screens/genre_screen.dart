import 'package:flutter/widgets.dart';

import 'track_group_screen.dart';

/// 장르 화면: 장르에 속한 곡 목록과 재생 · 셔플 ([TrackGroupScreen]).
/// [genre]는 곡에 저장된 장르 그대로이고, 빈 문자열이면 "알 수 없는 장르"이다.
class GenreScreen extends StatelessWidget {
  const GenreScreen({super.key, required this.genre});

  final String genre;

  @override
  Widget build(BuildContext context) =>
      TrackGroupScreen(kind: TrackGroupKind.genre, name: genre);
}
