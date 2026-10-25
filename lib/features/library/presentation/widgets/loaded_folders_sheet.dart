import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/loaded_folder.dart';
import '../bloc/loaded_folders_cubit.dart';

/// 음악을 불러오는 폴더 목록: 확인 · 추가 · 삭제 (바텀 시트).
Future<void> showLoadedFoldersSheet(BuildContext context) {
  final cubit = context.read<LoadedFoldersCubit>();
  return showAppSheet<void>(
    context,
    isScrollControlled: true,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const LoadedFoldersSheet()),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<LoadedFoldersCubit>().state;
    final cubit = context.read<LoadedFoldersCubit>();

    return SafeArea(
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
              AppSheetTitle(
                l10n.settingsLoadedFolders,
                subtitle: state.busy
                    ? l10n.loadedFoldersScanning
                    : l10n.loadedFoldersHint,
              ),
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
                                  await cubit.remove(folder.path);
                                }
                              },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PillButton(
                label: l10n.loadedFoldersAdd,
                icon: AppIcons.newFolder,
                onPressed: state.busy ? null : cubit.add,
              ),
            ],
          ),
        ),
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
