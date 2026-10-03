import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../bloc/lyrics_cubit.dart';
import '../screens/lyrics_sync_screen.dart';
import '../screens/lyrics_web_screen.dart';

/// 플레이어 가사 화면의 "가사 편집": 직접 입력 · 붙여넣기 · 파일(.lrc · .txt) · 웹 검색(Android)에서 불러오기.
/// 저장하면 곡의 가사로 저장하고(비우면 지움) 안내를 띄운다.
///
/// [initialText]가 있으면 저장된 가사 대신 그 글로 시작한다 (웹에서 가져온 글 검토용).
Future<void> showLyricsEditor(
  BuildContext context,
  Track track, {
  String? initialText,
}) async {
  final l10n = context.l10n;
  final cubit = context.read<LyricsCubit>();
  final text = await showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _LyricsEditorDialog(
      track: track,
      cubit: cubit,
      initialText: initialText,
    ),
  );
  if (text == null) return;
  await cubit.save(track.id, text);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text.trim().isEmpty ? l10n.lyricsCleared : l10n.lyricsSaved,
      ),
    ),
  );
}

class _LyricsEditorDialog extends StatefulWidget {
  const _LyricsEditorDialog({
    required this.track,
    required this.cubit,
    this.initialText,
  });

  final Track track;
  final LyricsCubit cubit;
  final String? initialText;

  @override
  State<_LyricsEditorDialog> createState() => _LyricsEditorDialogState();
}

class _LyricsEditorDialogState extends State<_LyricsEditorDialog> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialText;
    if (initial != null) {
      _text.text = initial;
    } else {
      _loadCurrent();
    }
  }

  Future<void> _loadCurrent() async {
    final current = await widget.cubit.currentText(widget.track);
    // 불러오는 사이에 사용자가 이미 쓰기 시작했으면 덮어쓰지 않는다.
    if (mounted && _text.text.isEmpty) _text.text = current;
  }

  Future<void> _pickFile() async {
    final picked = await widget.cubit.pickFile();
    if (picked != null && mounted) _text.text = picked;
  }

  Future<void> _searchWeb() async {
    final picked = await showLyricsWeb(context, widget.track);
    if (picked != null && mounted) _text.text = picked;
  }

  /// 지금 글을 곡에 맞춰 싱크한다. 저장하면 이 창도 닫으며 그 LRC로 저장한다.
  Future<void> _sync() async {
    final synced = await showLyricsSync(context, widget.track, _text.text);
    if (synced != null && mounted) Navigator.of(context).pop(synced);
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
    return Dialog(
      backgroundColor: context.palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.lyricsEditTitle, style: text.titleLarge),
            Text(
              widget.track.title,
              style: text.bodyMedium?.copyWith(
                color: context.palette.onSurfaceMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.lyricsEditLabel,
              controller: _text,
              hint: l10n.lyricsEditHint,
              maxLines: 10,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                PlainButton(
                  label: l10n.lyricsLoadFile,
                  icon: Icons.file_open_rounded,
                  onPressed: _pickFile,
                ),
                if (lyricsWebSupported)
                  PlainButton(
                    label: l10n.lyricsWebSearch,
                    icon: Icons.travel_explore_rounded,
                    onPressed: _searchWeb,
                  ),
                PlainButton(
                  label: l10n.lyricsSyncOpen,
                  icon: Icons.av_timer_rounded,
                  onPressed: _sync,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PlainButton(
                  label: l10n.actionCancel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppSpacing.xs),
                PlainButton(
                  label: l10n.lyricsSave,
                  accent: true,
                  onPressed: () => Navigator.of(context).pop(_text.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
