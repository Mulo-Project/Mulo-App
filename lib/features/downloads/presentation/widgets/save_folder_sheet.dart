import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/loaded_folder.dart';
import '../../../library/presentation/bloc/loaded_folders_cubit.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../library/presentation/widgets/loaded_folders_sheet.dart';

/// 저장 위치 고르기 바텀 시트: 불러오는 폴더 목록에서 고르거나, "직접 선택"으로 폴더 선택기를 연다.
/// [current]는 지금 정해진 위치(목록에 없어도 맨 위에 보인다). 고른 폴더를 돌려주고, 닫으면 null.
/// [pickOther]는 폴더 선택기 (취소하면 null).
Future<String?> showSaveFolderSheet(
  BuildContext context, {
  required String current,
  required Future<String?> Function() pickOther,
}) => showAppSheet<String>(
  context,
  isScrollControlled: true,
  builder: (_) => BlocProvider(
    create: (_) => sl<LoadedFoldersCubit>()..load(),
    child: _SaveFolderSheet(current: current, pickOther: pickOther),
  ),
);

class _SaveFolderSheet extends StatelessWidget {
  const _SaveFolderSheet({required this.current, required this.pickOther});

  final String current;
  final Future<String?> Function() pickOther;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.watch<LoadedFoldersCubit>();
    final player = context.read<NowPlayingCubit>();
    final folders = cubit.state.folders;
    final cur = current.trim();
    // 지금 위치가 목록에 없으면(직접 고른 폴더) 맨 위에 따로 보인다.
    final listed = folders.any(
      (f) => normalizeFolderPath(f.path) == normalizeFolderPath(cur),
    );
    final paths = [
      if (cur.isNotEmpty && !listed) cur,
      for (final f in folders) f.path,
    ];
    final listedPaths = {for (final f in folders) normalizeFolderPath(f.path)};
    final defaults = {
      for (final f in folders)
        if (f.isDefault) normalizeFolderPath(f.path),
    };

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
              AppSheetTitle(l10n.saveFolderTitle),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: paths.isEmpty
                    ? EmptyState(title: l10n.saveFolderEmpty)
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final path in paths)
                            _FolderOption(
                              path: path,
                              isDefault: defaults.contains(
                                normalizeFolderPath(path),
                              ),
                              selected:
                                  normalizeFolderPath(path) ==
                                  normalizeFolderPath(cur),
                              onTap: () => Navigator.of(context).pop(path),
                              // 기본 위치 · 지금 위치 · 목록에 없는 위치는 뺄 수 없다.
                              onRemove:
                                  cubit.state.busy ||
                                      defaults.contains(
                                        normalizeFolderPath(path),
                                      ) ||
                                      normalizeFolderPath(path) ==
                                          normalizeFolderPath(cur) ||
                                      !listedPaths.contains(
                                        normalizeFolderPath(path),
                                      )
                                  ? null
                                  : () async {
                                      final folder = folders.firstWhere(
                                        (f) =>
                                            normalizeFolderPath(f.path) ==
                                            normalizeFolderPath(path),
                                      );
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
              PillButton(
                label: l10n.saveFolderPickOther,
                icon: AppIcons.folder,
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final picked = await pickOther();
                  if (picked != null) nav.pop(picked);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderOption extends StatelessWidget {
  const _FolderOption({
    required this.path,
    required this.selected,
    required this.isDefault,
    required this.onTap,
    this.onRemove,
  });

  final String path;
  final bool selected;

  /// 앱 기본 저장 위치인지 (이름 옆에 작게 표시).
  final bool isDefault;
  final VoidCallback onTap;

  /// 목록에서 빼기 (뺄 수 없는 위치면 null이라 버튼이 없다).
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              AppIcons.folder,
              color: selected ? p.accent : p.onSurfaceMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 폴더 이름을 크게, 전체 경로는 작고 흐리게.
                  Text(
                    _nameOf(path) +
                        (isDefault
                            ? ' · ${context.l10n.loadedFoldersDefault}'
                            : ''),
                    style: text.titleSmall?.copyWith(
                      color: selected ? p.accent : p.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    path,
                    style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(AppIcons.check, size: AppSizes.iconSm, color: p.accent),
            if (onRemove != null)
              RowIconButton(
                icon: AppIcons.close,
                tooltip: context.l10n.loadedFoldersRemove,
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}

/// 경로의 마지막 폴더 이름 (비면 경로 그대로).
String _nameOf(String path) {
  final parts = normalizeFolderPath(path).split('/').where((e) => e.isNotEmpty);
  return parts.isEmpty ? path : parts.last;
}
