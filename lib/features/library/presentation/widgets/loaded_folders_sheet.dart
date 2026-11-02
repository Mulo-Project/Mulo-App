import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/loaded_folder.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../../../playlists/presentation/widgets/playlist_card.dart';
import '../bloc/library_cubit.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../bloc/loaded_folders_cubit.dart';

/// 음악을 불러오는 폴더 목록: 확인 · 추가 · 삭제 (바텀 시트).
Future<void> showLoadedFoldersSheet(BuildContext context) {
  final cubit = context.read<LoadedFoldersCubit>();
  return showAppSheet<void>(
    context,
    isScrollControlled: true,
    // 진행 중에는 내려서 닫을 수 없게 한다 (끌어내리기는 PopScope를 거치지 않아 끈다).
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => BlocProvider.value(
      value: cubit,
      // 내장 커버는 DB에 직접 저장되므로 커버가 새로 붙으면 메모리의 커버 목록을 다시 읽는다.
      child: BlocListener<LoadedFoldersCubit, LoadedFoldersState>(
        listenWhen: (a, b) => a.coversSeq != b.coversSeq,
        listener: (context, _) => context.read<CoverCubit>().load(),
        child: const LoadedFoldersSheet(),
      ),
    ),
  );
}

/// 폴더를 뺄지 묻는다: 보관함에서 사라질 곡 수를 알리고, 파일은 지워지지 않는다고 알린다.
Future<bool> confirmRemoveLoadedFolder(
  BuildContext context,
  LoadedFolder folder,
) {
  final l10n = context.l10n;
  return showConfirmDialog(
    context,
    title: l10n.loadedFoldersRemoveTitle,
    body: folder.trackCount == 0
        ? l10n.loadedFoldersRemoveBodyEmpty(folder.path)
        : l10n.loadedFoldersRemoveBody(folder.path, folder.trackCount),
    confirmLabel: l10n.loadedFoldersRemove,
    cancelLabel: l10n.actionCancel,
  );
}

class LoadedFoldersSheet extends StatelessWidget {
  const LoadedFoldersSheet({super.key});

  /// 폴더를 고르고 불러온다. 다 끝난 뒤 새로 들어온 곡이 있으면 재생목록에 담을지 작은 팝업으로 묻는다.
  Future<void> _add(BuildContext context) async {
    final cubit = context.read<LoadedFoldersCubit>();
    final library = context.read<LibraryCubit>();
    final playlists = context.read<PlaylistsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final before = {for (final t in library.state.tracks) t.id};
    if (!await cubit.add()) return;
    final added = {
      for (final t in library.state.tracks)
        if (!before.contains(t.id)) t.id,
    };
    if (added.isEmpty || !context.mounted) return;
    final targets = await _askPlaylists(context, added.length);
    if (targets == null || targets.isEmpty) return;
    for (final id in targets) {
      await playlists.addTracks(added, id);
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.loadedFoldersAddedToPlaylists(added.length, targets.length),
        ),
      ),
    );
  }

  Future<Set<String>?> _askPlaylists(BuildContext context, int count) =>
      showDialog<Set<String>>(
        context: context,
        useRootNavigator: true,
        builder: (_) => BlocProvider.value(
          value: context.read<PlaylistsCubit>(),
          child: _PlaylistDialog(count: count),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<LoadedFoldersCubit>().state;
    final cubit = context.read<LoadedFoldersCubit>();
    final player = context.read<NowPlayingCubit>();

    // 폴더를 바꾸는 동안에는 뒤로가기 · 바깥 터치로 닫히지 않는다 (멈추기를 누르거나 끝나면 닫을 수 있다).
    return PopScope(
      canPop: !state.busy,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .8,
          ),
          child: Padding(
            padding: appSheetPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                AppSheetTitle(
                  l10n.settingsLoadedFolders,
                  subtitle: state.busy ? null : l10n.loadedFoldersHint,
                ),
                // 폴더를 바꾼 뒤 곡을 찾고 · 정보를 읽고 · 이미지를 가져오는 동안의 진행.
                if (state.busy) _Progress(state: state),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final folder in state.folders)
                        _FolderRow(
                          folder: folder,
                          onRemove: state.busy
                              ? null
                              : () async {
                                  if (await confirmRemoveLoadedFolder(
                                    context,
                                    folder,
                                  )) {
                                    final removed = await cubit.remove(
                                      folder.path,
                                    );
                                    player.removeFromQueueByIds(removed);
                                  }
                                },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (state.busy)
                  PillButton(
                    label: l10n.actionCancel,
                    variant: PillVariant.tonal,
                    onPressed: cubit.cancel,
                  )
                else
                  PillButton(
                    label: l10n.loadedFoldersAdd,
                    icon: AppIcons.newFolder,
                    onPressed: state.busy ? null : () => _add(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 불러오기가 끝난 뒤 새로 들어온 곡을 담을 재생목록을 고르는 작은 팝업.
class _PlaylistDialog extends StatefulWidget {
  const _PlaylistDialog({required this.count});

  final int count;

  @override
  State<_PlaylistDialog> createState() => _PlaylistDialogState();
}

class _PlaylistDialogState extends State<_PlaylistDialog> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final playlists = context.watch<PlaylistsCubit>().state;
    return AppDialog(
      title: l10n.loadedFoldersPlaylistTitle(widget.count),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .4,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final pl in playlists)
              SettingRow(
                title: playlistNameOf(l10n, pl),
                description: l10n.songCount(pl.trackCount),
                onTap: () => setState(() {
                  _selected.contains(pl.id)
                      ? _selected.remove(pl.id)
                      : _selected.add(pl.id);
                }),
                trailing: Icon(
                  _selected.contains(pl.id)
                      ? AppIcons.checkCircle
                      : AppIcons.radioOff,
                  color: _selected.contains(pl.id)
                      ? p.accent
                      : p.onSurfaceMuted,
                ),
              ),
          ],
        ),
      ),
      actions: [
        PillButton(
          label: l10n.loadedFoldersPlaylistSkip,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(context).pop(),
        ),
        PillButton(
          label: l10n.loadedFoldersPlaylistAdd,
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selected),
        ),
      ],
    );
  }
}

/// 폴더를 바꾼 뒤 보관함을 채우는 진행: 단계 이름 · 끝낸 수 / 전체, 그 아래 진행 막대.
class _Progress extends StatelessWidget {
  const _Progress({required this.state});

  final LoadedFoldersState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final label = switch (state.stage) {
      LoadStage.reading => l10n.loadedFoldersReading,
      LoadStage.covers => l10n.loadedFoldersCovers,
      LoadStage.removing => l10n.loadedFoldersRemoving,
      _ => l10n.loadedFoldersScanning,
    };
    final counted = state.total > 0;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.bodyMedium?.copyWith(
                    color: context.palette.onSurfaceMuted,
                  ),
                ),
              ),
              if (counted)
                Text(
                  l10n.renameProgressCount(state.done, state.total),
                  style: text.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ProgressLine(
            value: counted ? state.done / state.total : 0,
            height: 6,
          ),
        ],
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({required this.folder, this.onRemove});

  final LoadedFolder folder;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return Padding(
      // 저장 위치 시트와 같은 여백 · 오른쪽 끝 칸으로 아이콘 자리를 맞춘다.
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(AppIcons.folder, color: p.onSurfaceMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder.path,
                  style: text.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.hair),
                Text(
                  folder.isDefault
                      ? '${l10n.loadedFoldersDefault} · ${l10n.loadedFoldersTrackCount(folder.trackCount)}'
                      : l10n.loadedFoldersTrackCount(folder.trackCount),
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          SizedBox(
            width: AppSizes.rowButton,
            height: AppSizes.rowButton,
            child: folder.isDefault
                ? null
                : RowIconButton(
                    icon: AppIcons.close,
                    tooltip: l10n.loadedFoldersRemove,
                    onPressed: onRemove,
                  ),
          ),
        ],
      ),
    );
  }
}
