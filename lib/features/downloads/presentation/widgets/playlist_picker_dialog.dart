import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../playlists/domain/entities/playlist.dart';
import '../../../playlists/presentation/widgets/playlist_card.dart';

/// 곡을 담을 재생목록을 여러 개 고르는 대화상자.
/// "선택 완료"를 누르면 고른 id 모음을, 바깥을 눌러 닫으면 null을 돌려준다.
Future<Set<String>?> showPlaylistPickerDialog(
  BuildContext context, {
  required List<Playlist> playlists,
  required Set<String> selected,
}) {
  return showDialog<Set<String>>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _PlaylistPicker(playlists: playlists, selected: selected),
  );
}

class _PlaylistPicker extends StatefulWidget {
  const _PlaylistPicker({required this.playlists, required this.selected});

  final List<Playlist> playlists;
  final Set<String> selected;

  @override
  State<_PlaylistPicker> createState() => _PlaylistPickerState();
}

class _PlaylistPickerState extends State<_PlaylistPicker> {
  late final Set<String> _selected = {...widget.selected};

  void _toggle(String id) => setState(() {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return AppDialog(
      title: l10n.downloadPlaylistsPickTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final pl in widget.playlists)
            SettingRow(
              title: playlistNameOf(l10n, pl),
              description: l10n.songCount(pl.trackCount),
              onTap: () => _toggle(pl.id),
              trailing: Icon(
                _selected.contains(pl.id)
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: _selected.contains(pl.id) ? p.accent : p.onSurfaceMuted,
              ),
            ),
          // 좋아요 말고 직접 만든 재생목록이 없을 때의 안내.
          if (widget.playlists.every((pl) => pl.isFavorites))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                l10n.downloadPlaylistsEmpty,
                style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
              ),
            ),
        ],
      ),
      actions: [
        PillButton(
          label: l10n.downloadPlaylistsDone,
          onPressed: () => Navigator.of(context).pop(_selected),
        ),
      ],
    );
  }
}
