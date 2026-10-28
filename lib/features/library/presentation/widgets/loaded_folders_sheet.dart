import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/loaded_folder.dart';
import '../../../downloads/presentation/widgets/playlist_picker_sheet.dart';
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

class LoadedFoldersSheet extends StatefulWidget {
  const LoadedFoldersSheet({super.key});

  @override
  State<LoadedFoldersSheet> createState() => _LoadedFoldersSheetState();
}

class _LoadedFoldersSheetState extends State<LoadedFoldersSheet> {
  /// 폴더를 추가할 때 새로 불러온 곡을 함께 담을 재생목록. 비어 있으면 담지 않는다.
  Set<String> _targets = {};

  Future<void> _pickTargets() async {
    final picked = await showPlaylistPickerSheet(
      context,
      playlists: context.read<PlaylistsCubit>(),
      selected: _targets,
    );
    if (picked != null && mounted) setState(() => _targets = picked);
  }

  /// 폴더를 고르고 불러온 뒤, 새로 들어온 곡 전부를 고른 재생목록에 한 번에 담는다.
  Future<void> _add() async {
    final l10n = context.l10n;
    final cubit = context.read<LoadedFoldersCubit>();
    final library = context.read<LibraryCubit>();
    final playlists = context.read<PlaylistsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final targets = {..._targets};
    final before = {for (final t in library.state.tracks) t.id};
    await cubit.add();
    if (targets.isEmpty) return;
    final added = {
      for (final t in library.state.tracks)
        if (!before.contains(t.id)) t.id,
    };
    if (added.isEmpty) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<LoadedFoldersCubit>().state;
    final cubit = context.read<LoadedFoldersCubit>();
    final player = context.read<NowPlayingCubit>();
    final playlists = context.watch<PlaylistsCubit>().state;
    final names = [
      for (final pl in playlists)
        if (_targets.contains(pl.id)) playlistNameOf(l10n, pl),
    ];

    // 폴더를 바꾸는 동안에는 뒤로가기 · 바깥 터치로 닫히지 않는다 (끝나면 다시 닫을 수 있다).
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
                SettingRow(
                  title: l10n.loadedFoldersToPlaylist,
                  description: switch (names.length) {
                    0 => l10n.loadedFoldersToPlaylistOff,
                    1 => names.first,
                    _ => l10n.loadedFoldersToPlaylistCount(names.length),
                  },
                  onTap: state.busy ? null : _pickTargets,
                  trailing: Icon(
                    AppIcons.chevronRight,
                    color: context.palette.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                PillButton(
                  label: l10n.loadedFoldersAdd,
                  icon: AppIcons.newFolder,
                  onPressed: state.busy ? null : _add,
                ),
              ],
            ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
          if (!folder.isDefault)
            RowIconButton(
              icon: AppIcons.close,
              tooltip: l10n.loadedFoldersRemove,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
