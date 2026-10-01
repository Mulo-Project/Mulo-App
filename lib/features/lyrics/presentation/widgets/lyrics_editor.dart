import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../bloc/lyrics_cubit.dart';

/// 곡 메뉴의 "가사 설정": 직접 입력 · 붙여넣기 · 파일(.lrc · .txt)에서 불러오기.
/// 저장하면 곡의 가사로 저장하고(비우면 지움) 안내를 띄운다.
Future<void> showLyricsEditor(BuildContext context, Track track) async {
  final l10n = context.l10n;
  final cubit = context.read<LyricsCubit>();
  final text = await showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _LyricsEditorDialog(track: track, cubit: cubit),
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
  const _LyricsEditorDialog({required this.track, required this.cubit});

  final Track track;
  final LyricsCubit cubit;

  @override
  State<_LyricsEditorDialog> createState() => _LyricsEditorDialogState();
}

class _LyricsEditorDialogState extends State<_LyricsEditorDialog> {
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
    if (picked != null && mounted) _text.text = picked;
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
            PillButton(
              label: l10n.lyricsLoadFile,
              icon: Icons.file_open_rounded,
              variant: PillVariant.tonal,
              onPressed: _pickFile,
            ),
            const SizedBox(height: AppSpacing.xs),
            PillButton(
              label: l10n.lyricsSave,
              onPressed: () => Navigator.of(context).pop(_text.text),
            ),
            const SizedBox(height: AppSpacing.xs),
            PillButton(
              label: l10n.actionCancel,
              variant: PillVariant.tonal,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
