import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../bloc/lyrics_cubit.dart';
import '../screens/lyrics_sync_screen.dart';

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
