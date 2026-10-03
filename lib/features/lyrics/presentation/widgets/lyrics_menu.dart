import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../bloc/lyrics_cubit.dart';
import '../screens/lyrics_sync_screen.dart';
import '../screens/lyrics_web_screen.dart';
import 'lyrics_editor.dart';

enum _LyricsAction { edit, web, sync }

/// 플레이어 가사 화면의 작은 편집 버튼. 누르면 [showLyricsMenu]가 열린다.
class LyricsMenuButton extends StatelessWidget {
  const LyricsMenuButton({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (context) => IconButton(
      tooltip: context.l10n.lyricsMenuTooltip,
      onPressed: () => showLyricsMenu(context, track),
      icon: Icon(
        Icons.edit_note_rounded,
        color: context.palette.onSurfaceMuted,
      ),
    ),
  );
}

/// 가사 메뉴: 가사 편집 · 웹에서 가져오기(Android) · 싱크 맞추기.
/// 웹에서 가져온 글은 편집기에 채워 열어 검토 후 저장하게 한다.
Future<void> showLyricsMenu(BuildContext context, Track track) async {
  final l10n = context.l10n;
  final action = await showAppMenu<_LyricsAction>(
    context,
    items: [
      AppMenuItem(
        value: _LyricsAction.edit,
        icon: Icons.edit_rounded,
        label: l10n.lyricsMenuEdit,
      ),
      if (lyricsWebSupported)
        AppMenuItem(
          value: _LyricsAction.web,
          icon: Icons.travel_explore_rounded,
          label: l10n.lyricsMenuWeb,
        ),
      AppMenuItem(
        value: _LyricsAction.sync,
        icon: Icons.av_timer_rounded,
        label: l10n.lyricsSyncTitle,
      ),
    ],
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _LyricsAction.edit:
      await showLyricsEditor(context, track);
    case _LyricsAction.web:
      final picked = await showLyricsWeb(context, track);
      if (picked == null || !context.mounted) return;
      await showLyricsEditor(context, track, initialText: picked);
    case _LyricsAction.sync:
      await startLyricsSync(context, track);
  }
}

/// 저장된 가사로 싱크 맞추기 화면을 열고, 저장하면 곡의 가사로 저장한다.
Future<void> startLyricsSync(BuildContext context, Track track) async {
  final l10n = context.l10n;
  final cubit = context.read<LyricsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final current = await cubit.currentText(track);
  if (!context.mounted) return;
  if (current.trim().isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.lyricsSyncEmpty)));
    return;
  }
  final synced = await showLyricsSync(context, track, current);
  if (synced == null) return;
  await cubit.save(track.id, synced);
  messenger.showSnackBar(SnackBar(content: Text(l10n.lyricsSaved)));
}
