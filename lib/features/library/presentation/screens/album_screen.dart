import 'package:flutter/widgets.dart';

import 'track_group_screen.dart';

/// 앨범 화면: 앨범에 속한 곡 목록과 전체 재생 ([TrackGroupScreen]).
/// [album]은 곡에 저장된 앨범 이름 그대로이고, 빈 문자열이면 "알 수 없는 앨범"이다.
class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key, required this.album});

  final String album;

  @override
  Widget build(BuildContext context) =>
      TrackGroupScreen(kind: TrackGroupKind.album, name: album);
}
