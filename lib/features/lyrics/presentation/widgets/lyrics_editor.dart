import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../bloc/lyrics_cubit.dart';
import '../screens/lyrics_web_screen.dart';
import 'lyric_line_row.dart';
import 'lyrics_dialogs.dart';

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
  final _text = TextEditingController();

  // 싱크 가사는 시간을 글과 따로 두고, 줄 번호에 맞춰 붙인다 (줄을 끼우거나 지우면 시간은 그 자리에 남는다).
  var _rowsMode = false;
  var _times = <Duration>[];
  var _rows = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final current = await widget.cubit.currentText(widget.track);
    // 불러오는 사이에 사용자가 이미 쓰기 시작했으면 덮어쓰지 않는다.
    if (mounted && _isEmpty) setState(() => _load(current));
  }

  bool get _isEmpty => _rowsMode
      ? _rows.every((c) => c.text.trim().isEmpty)
      : _text.text.trim().isEmpty;

  /// [raw]를 편집 칸에 채운다: 싱크 가사면 시간과 글을 나눠 줄 칸으로, 아니면 글 한 덩어리로.
  void _load(String raw) {
    final lyrics = Lyrics.parse(raw);
    for (final c in _rows) {
      c.dispose();
    }
    if (lyrics != null && lyrics.isSynced) {
      _rowsMode = true;
      _times = [for (final l in lyrics.lines) l.time];
      _rows = [
        for (final l in lyrics.lines) TextEditingController(text: l.text),
        for (final t in lyrics.pending) TextEditingController(text: t),
      ];
      _text.clear();
    } else {
      _rowsMode = false;
      _times = [];
      _rows = [];
      _text.text = raw;
    }
  }

  /// 저장할 글: 줄 칸이면 줄 번호에 맞는 시간을 `[mm:ss.xx]`로 다시 붙인다.
  String _compose() {
    if (!_rowsMode) return _text.text;
    final b = StringBuffer();
    for (var i = 0; i < _rows.length; i++) {
      final text = _rows[i].text.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim();
      if (i < _times.length) {
        b.writeln('[${lyricTimeLabel(_times[i])}]$text');
      } else {
        b.writeln(text);
      }
    }
    return b.toString().trimRight();
  }

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
    if (_isEmpty) {
      setState(() => _load(imported));
      return;
    }
    final mode = await showLyricsImportMode(context);
    if (mode == null || !mounted) return;
    setState(() {
      if (mode == LyricsImportMode.replace) {
        _load(imported);
      } else if (_rowsMode) {
        // 붙인 글은 시간 없는 줄로 뒤에 더한다.
        final extra = Lyrics.parse(imported)?.plain ?? imported;
        for (final line in extra.split('\n')) {
          if (line.trim().isNotEmpty) {
            _rows.add(TextEditingController(text: line.trim()));
          }
        }
      } else {
        _text.text = '${_text.text.trimRight()}\n$imported';
      }
    });
  }

  @override
  void dispose() {
    _text.dispose();
    for (final c in _rows) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _buildRows(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _rows.length + 2,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.lyricsEditSyncedHint,
              style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
            ),
          );
        }
        if (i == _rows.length + 1) {
          return Align(
            alignment: Alignment.centerLeft,
            child: PlainButton(
              label: l10n.lyricsAddLine,
              icon: AppIcons.add,
              onPressed: () =>
                  setState(() => _rows.add(TextEditingController())),
            ),
          );
        }
        final index = i - 1;
        return LyricLineRow(
          key: ObjectKey(_rows[index]),
          time: index < _times.length ? _times[index] : null,
          controller: _rows[index],
          deleteTooltip: l10n.lyricsDeleteLine,
          onDelete: () => setState(() => _rows.removeAt(index).dispose()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: l10n.lyricsEditTitle,
              leading: CircleIconButton(
                icon: AppIcons.close,
                tooltip: l10n.actionCancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.track.title,
                  style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              child: _rowsMode
                  ? _buildRows(context)
                  : Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: AppTextField(
                        label: l10n.lyricsEditLabel,
                        controller: _text,
                        hint: l10n.lyricsEditHint,
                        expands: true,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
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
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: l10n.actionCancel,
                      variant: PillVariant.tonal,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PillButton(
                      label: l10n.lyricsSave,
                      icon: AppIcons.check,
                      onPressed: () => Navigator.of(context).pop(_compose()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
