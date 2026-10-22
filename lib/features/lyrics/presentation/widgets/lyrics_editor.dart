import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../bloc/lyrics_cubit.dart';
import '../screens/lyrics_web_screen.dart';
import '../../domain/entities/timed_lyrics_text.dart';
import 'lyrics_dialogs.dart';
import 'timed_lyrics_controller.dart';
import 'lyrics_edit_scaffold.dart';

/// 플레이어 가사 화면의 "가사 편집" 페이지: 직접 입력 · 붙여넣기 · 파일(.lrc · .txt) · 웹 검색(Android)에서 불러오기.
/// 저장하면 곡의 가사로 저장하고(비우면 지움) 안내를 띄운다.
Future<void> showLyricsEditor(BuildContext context, Track track) async {
  final l10n = context.l10n;
  final cubit = context.read<LyricsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final text = await Navigator.of(context, rootNavigator: true).push<String>(
    MaterialPageRoute(
      builder: (_) => _LyricsEditorScreen(track: track, cubit: cubit),
    ),
  );
  if (text == null) return;
  await cubit.save(track.id, text);
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        text.trim().isEmpty ? l10n.lyricsCleared : l10n.lyricsSaved,
      ),
    ),
  );
}

class _LyricsEditorScreen extends StatefulWidget {
  const _LyricsEditorScreen({required this.track, required this.cubit});

  final Track track;
  final LyricsCubit cubit;

  @override
  State<_LyricsEditorScreen> createState() => _LyricsEditorScreenState();
}

class _LyricsEditorScreenState extends State<_LyricsEditorScreen> {
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
    final current = await widget.cubit.currentText(widget.track);
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

  Future<void> _pickFile() async {
    final picked = await widget.cubit.pickFile();
    if (picked != null && mounted) await _apply(picked);
  }

  Future<void> _searchWeb() async {
    final picked = await showLyricsWeb(context, widget.track);
    if (picked != null && mounted) await _apply(picked);
  }

  /// 가져온 글을 넣는다. 가사가 이미 있으면 바꿀지 뒤에 붙일지 먼저 묻는다.
  Future<void> _apply(String imported) async {
    if (_text.text.trim().isEmpty) {
      setState(() => _load(imported));
      return;
    }
    final mode = await showLyricsImportMode(context);
    if (mode == null || !mounted) return;
    setState(() {
      if (mode == LyricsImportMode.replace) {
        _load(imported);
      } else {
        // 붙인 글은 시간 없는 줄로 뒤에 더한다.
        final extra = TimedLyricsText.parse(imported).text;
        _text.text = '${_text.text.trimRight()}\n$extra';
      }
    });
  }

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
      tools: [
        PlainButton(
          label: l10n.lyricsLoadFile,
          icon: AppIcons.fileOpen,
          onPressed: _pickFile,
        ),
        if (lyricsWebSupported)
          PlainButton(
            label: l10n.lyricsWebSearch,
            icon: AppIcons.explore,
            onPressed: _searchWeb,
          ),
      ],
      primaryLabel: l10n.lyricsSave,
      onPrimary: () => Navigator.of(context).pop(_compose()),
    );
  }
}
