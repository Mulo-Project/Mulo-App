import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../bloc/lyrics_cubit.dart';
import '../../domain/entities/timed_lyrics_text.dart';
import 'lyrics_import_bar.dart';
import 'lyrics_tag_notice.dart';
import 'timed_lyrics_controller.dart';
import 'lyrics_edit_scaffold.dart';

/// 플레이어 가사 화면의 "가사 편집" 페이지: 직접 입력 · 붙여넣기 · 파일(.lrc · .txt) · 웹 검색(Android)에서 불러오기.
/// 저장하면 곡의 가사로 저장한다(비우면 지움). 화면이 닫히고 가사가 바뀌므로 따로 안내하지 않는다.
Future<void> showLyricsEditor(BuildContext context, Track track) async {
  final cubit = context.read<LyricsCubit>();
  final text = await Navigator.of(context, rootNavigator: true).push<String>(
    MaterialPageRoute(
      builder: (_) => LyricsEditorPage(
        track: track,
        loadInitial: () => cubit.currentText(track),
      ),
    ),
  );
  if (text == null) return;
  final tag = await cubit.save(track, text);
  if (context.mounted) showLyricsTagNotice(context, tag);
}

/// "가사 설정" 페이지. 플레이어의 가사 설정과 받기 창의 가사 설정이 함께 쓴다.
/// [loadInitial]이 처음 보여 줄 글을 돌려주고, "저장"을 누르면 고친 글(싱크는 `[mm:ss.xx]` 포함)을 돌려준다.
/// [track]은 제목 표시와 웹 검색어로 쓰는 곡이다.
class LyricsEditorPage extends StatefulWidget {
  const LyricsEditorPage({
    super.key,
    required this.track,
    required this.loadInitial,
  });

  final Track track;
  final Future<String> Function() loadInitial;

  @override
  State<LyricsEditorPage> createState() => _LyricsEditorPageState();
}

class _LyricsEditorPageState extends State<LyricsEditorPage> {
  final _text = TimedLyricsController();

  // 싱크 가사는 시간을 글과 따로 두고 줄 번호로 짝짓는다 (줄을 끼우거나 지우면 시간은 그 자리에 남는다).
  // 싱크 가사를 불러왔는가 (줄마다 시간 칸을 보인다).
  var _synced = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final current = await widget.loadInitial();
    // 불러오는 사이에 사용자가 이미 쓰기 시작했으면 덮어쓰지 않는다.
    if (mounted && _text.text.isEmpty) setState(() => _load(current));
  }

  /// [raw]를 편집 칸에 채운다: 싱크 가사면 시간 표시를 빼 글만 넣고 시간은 따로 둔다.
  void _load(String raw) {
    final split = TimedLyricsText.parse(raw);
    _synced = split.isSynced;
    _text.load(split);
  }

  /// 저장할 글: 줄 번호에 맞는 시간을 `[mm:ss.xx]`로 다시 붙인다.
  String _compose() => _text.compose();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LyricsEditScaffold(
      title: l10n.lyricsEditTitle,
      subtitle: widget.track.title,
      controller: _text,
      showTimes: _synced,
      notice: _synced ? l10n.lyricsEditSyncedHint : null,
      fieldHint: l10n.lyricsEditHint,
      // 파일 · 웹에서 불러오기와 불러온 가사 메모는 받기 전 가사 상세와 같은 줄을 쓴다.
      top: LyricsImportBar(
        controller: _text,
        track: widget.track,
        onReplace: (raw) => setState(() => _load(raw)),
      ),
      primaryLabel: l10n.lyricsSave,
      onPrimary: () => Navigator.of(context).pop(_compose()),
    );
  }
}
