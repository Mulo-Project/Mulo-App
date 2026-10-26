import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/presentation/widgets/rename_progress.dart';
import '../../../lyrics/presentation/bloc/lyrics_file_write_cubit.dart';
import 'settings_common.dart';

/// 재생 묶음의 한 줄: 앱에 저장한 가사를 음악 파일의 가사 태그로 한꺼번에 옮긴다.
/// 누르면 대상 곡 수 확인 → 진행 표시 → 결과(쓴 곡 · 건너뛴 곡 · 실패한 곡 수)를 알린다.
class SettingsLyricsFileRow extends StatefulWidget {
  const SettingsLyricsFileRow({super.key});

  @override
  State<SettingsLyricsFileRow> createState() => _SettingsLyricsFileRowState();
}

class _SettingsLyricsFileRowState extends State<SettingsLyricsFileRow> {
  late final LyricsFileWriteCubit _cubit = sl<LyricsFileWriteCubit>();

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _start() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final count = await _cubit.count();
    if (!mounted) return;
    if (count == 0) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.lyricsToFileNone)));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialog) => AppDialog(
        title: l10n.lyricsToFileTitle,
        body: l10n.lyricsToFileConfirm(count),
        actions: [
          PillButton(
            label: l10n.actionCancel,
            variant: PillVariant.tonal,
            onPressed: () => Navigator.of(dialog).pop(false),
          ),
          PillButton(
            label: l10n.lyricsToFileApply,
            onPressed: () => Navigator.of(dialog).pop(true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final result = await showProgressWhile(
      context,
      title: (l) => l.lyricsToFileProgressTitle,
      task: (report) => _cubit.run(onProgress: report),
    );
    if (result == null || !mounted) return;
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialog) {
        final l = dialog.l10n;
        final lines = result.nothingSupported
            ? [l.lyricsToFileUnsupported]
            : [
                if (result.written > 0) l.lyricsToFileWritten(result.written),
                if (result.alreadyThere > 0)
                  l.lyricsToFileAlready(result.alreadyThere),
                if (result.unsupported > 0)
                  l.lyricsToFileSkipped(result.unsupported),
                if (result.failed > 0) l.lyricsToFileFailed(result.failed),
              ];
        return AppDialog(
          title: l.lyricsToFileDoneTitle,
          body: lines.join('\n'),
          actions: [
            PillButton(
              label: l.lyricsToFileOk,
              onPressed: () => Navigator.of(dialog).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<LyricsFileWriteCubit, bool>(
      bloc: _cubit,
      builder: (context, running) => SettingRow(
        title: l10n.lyricsToFileTitle,
        description: l10n.lyricsToFileDesc,
        trailing: const SettingsChevron(),
        onTap: running ? null : _start,
      ),
    );
  }
}
