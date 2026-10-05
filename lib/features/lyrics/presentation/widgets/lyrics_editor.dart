import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../bloc/lyrics_cubit.dart';
import '../screens/lyrics_web_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final current = await widget.cubit.currentText(widget.track);
    // 불러오는 사이에 사용자가 이미 쓰기 시작했으면 덮어쓰지 않는다.
    if (mounted && _text.text.isEmpty) _text.text = current;
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
    final current = _text.text;
    if (current.trim().isEmpty) {
      _text.text = imported;
      return;
    }
    final mode = await showLyricsImportMode(context);
    if (mode == null || !mounted) return;
    _text.text = switch (mode) {
      LyricsImportMode.replace => imported,
      LyricsImportMode.append => '${current.trimRight()}\n$imported',
    };
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
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
              child: Padding(
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
                      onPressed: () => Navigator.of(context).pop(_text.text),
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
