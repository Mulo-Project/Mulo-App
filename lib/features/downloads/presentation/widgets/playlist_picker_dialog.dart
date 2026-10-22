import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../../../playlists/presentation/widgets/playlist_card.dart';

/// 곡을 담을 재생목록을 여러 개 고르는 대화상자.
/// 목록 아래에서 새 재생목록을 바로 만들 수 있고, 만들면 자동으로 골라진다.
/// "선택 완료"를 누르면 고른 id 모음을, 바깥을 눌러 닫으면 null을 돌려준다.
Future<Set<String>?> showPlaylistPickerDialog(
  BuildContext context, {
  required PlaylistsCubit playlists,
  required Set<String> selected,
}) {
  return showDialog<Set<String>>(
    context: context,
    useRootNavigator: true,
    builder: (_) => BlocProvider.value(
      value: playlists,
      child: _PlaylistPicker(selected: selected),
    ),
  );
}

class _PlaylistPicker extends StatefulWidget {
  const _PlaylistPicker({required this.selected});

  final Set<String> selected;

  @override
  State<_PlaylistPicker> createState() => _PlaylistPickerState();
}

class _PlaylistPickerState extends State<_PlaylistPicker> {
  late final Set<String> _selected = {...widget.selected};
  final _newPlaylist = TextEditingController();

  @override
  void dispose() {
    _newPlaylist.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final made = await context.read<PlaylistsCubit>().create(_newPlaylist.text);
    if (made == null || !mounted) return;
    setState(() {
      _newPlaylist.clear();
      _selected.add(made.id);
    });
  }

  void _toggle(String id) => setState(() {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final playlists = context.watch<PlaylistsCubit>().state;

    return AppDialog(
      title: l10n.downloadPlaylistsPickTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final pl in playlists)
            SettingRow(
              title: playlistNameOf(l10n, pl),
              description: l10n.songCount(pl.trackCount),
              onTap: () => _toggle(pl.id),
              trailing: Icon(
                _selected.contains(pl.id)
                    ? AppIcons.checkCircle
                    : AppIcons.radioOff,
                color: _selected.contains(pl.id) ? p.accent : p.onSurfaceMuted,
              ),
            ),
          // 좋아요 말고 직접 만든 재생목록이 없을 때의 안내.
          if (playlists.every((pl) => pl.isFavorites))
            EmptyState(title: l10n.downloadPlaylistsEmpty, compact: true),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppTextField(
                  label: l10n.downloadNewPlaylist,
                  controller: _newPlaylist,
                  hint: l10n.downloadNewPlaylistHint,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _create(),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              CircleIconButton(
                icon: AppIcons.add,
                tooltip: l10n.playlistsNew,
                onPressed: _create,
              ),
            ],
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
