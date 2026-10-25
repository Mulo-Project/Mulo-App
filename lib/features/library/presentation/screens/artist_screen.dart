import 'package:flutter/widgets.dart';

import 'track_group_screen.dart';

/// 아티스트 화면: 아티스트의 곡 목록과 전체 재생 ([TrackGroupScreen]).
/// [artist]는 곡에 저장된 아티스트 이름 그대로이고, 빈 문자열이면 "알 수 없는 아티스트"이다.
class ArtistScreen extends StatelessWidget {
  const ArtistScreen({super.key, required this.artist});

  final String artist;

  @override
  Widget build(BuildContext context) =>
      TrackGroupScreen(kind: TrackGroupKind.artist, name: artist);
}
