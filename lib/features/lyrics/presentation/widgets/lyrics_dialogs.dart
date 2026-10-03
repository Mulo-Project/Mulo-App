import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';

/// 가져온 가사를 이미 있는 가사에 어떻게 넣을지.
enum LyricsImportMode { replace, append }

/// 가사가 이미 있을 때 가져온 글을 바꿀지 뒤에 붙일지 묻는다. 취소하면 null.
Future<LyricsImportMode?> showLyricsImportMode(BuildContext context) {
  final l10n = context.l10n;
  return showDialog<LyricsImportMode>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => _LyricsDialog(
      title: l10n.lyricsImportExistsTitle,
      body: l10n.lyricsImportExistsBody,
      actions: [
        PillButton(
          label: l10n.lyricsImportReplace,
          onPressed: () =>
              Navigator.of(dialogContext).pop(LyricsImportMode.replace),
        ),
        PillButton(
          label: l10n.lyricsImportAppend,
          variant: PillVariant.tonal,
          onPressed: () =>
              Navigator.of(dialogContext).pop(LyricsImportMode.append),
        ),
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}

/// 기본 줄 수를 바꾸면 직접 묶은 줄이 사라진다는 경고. 계속하면 true.
Future<bool> confirmLyricsGroupReset(BuildContext context) async {
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => _LyricsDialog(
      title: l10n.lyricsSyncResetTitle,
      body: l10n.lyricsSyncResetBody,
      actions: [
        PillButton(
          label: l10n.lyricsSyncResetConfirm,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
      ],
    ),
  );
  return ok == true;
}

/// 싱크를 처음 맞출 때 기본으로 한 번에 찍을 줄 수를 고른다. 밖을 누르면 null.
Future<int?> pickLyricsDefaultGroup(BuildContext context, {int initial = 1}) {
  return showDialog<int>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _GroupPickDialog(initial: initial),
  );
}

class _GroupPickDialog extends StatefulWidget {
  const _GroupPickDialog({required this.initial});

  final int initial;

  @override
  State<_GroupPickDialog> createState() => _GroupPickDialogState();
}

class _GroupPickDialogState extends State<_GroupPickDialog> {
  late var _group = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _LyricsDialog(
      title: l10n.lyricsSyncGroup,
      body: l10n.lyricsSyncGroupSetupBody,
      content: Center(
        child: SegmentedPills<int>(
          values: const [1, 2, 3, 4],
          selected: _group,
          labelOf: l10n.lyricsSyncGroupLines,
          onChanged: (v) => setState(() => _group = v),
        ),
      ),
      actions: [
        PillButton(
          label: l10n.lyricsSyncGroupOk,
          onPressed: () => Navigator.of(context).pop(_group),
        ),
      ],
    );
  }
}

class _LyricsDialog extends StatelessWidget {
  const _LyricsDialog({
    required this.title,
    required this.body,
    required this.actions,
    this.content,
  });

  final String title;
  final String body;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
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
            Text(title, style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: text.bodyMedium?.copyWith(
                color: context.palette.onSurfaceMuted,
              ),
            ),
            if (content != null) ...[
              const SizedBox(height: AppSpacing.md),
              content!,
            ],
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.xs),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }
}
