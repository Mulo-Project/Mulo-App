import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/loaded_folder.dart';
import '../../../library/presentation/bloc/loaded_folders_cubit.dart';

/// 저장 위치 고르기 대화상자: 불러오는 폴더 목록에서 고르거나, "직접 선택"으로 폴더 선택기를 연다.
/// [current]는 지금 정해진 위치(목록에 없어도 맨 위에 보인다). 고른 폴더를 돌려주고, 닫으면 null.
/// [pickOther]는 폴더 선택기 (취소하면 null).
Future<String?> showSaveFolderDialog(
  BuildContext context, {
  required String current,
  required Future<String?> Function() pickOther,
}) => showDialog<String>(
  context: context,
  useRootNavigator: true,
  builder: (_) => BlocProvider(
    create: (_) => sl<LoadedFoldersCubit>()..load(),
    child: _SaveFolderDialog(current: current, pickOther: pickOther),
  ),
);

class _SaveFolderDialog extends StatelessWidget {
  const _SaveFolderDialog({required this.current, required this.pickOther});

  final String current;
  final Future<String?> Function() pickOther;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final folders = context.watch<LoadedFoldersCubit>().state.folders;
    final cur = current.trim();
    // 지금 위치가 목록에 없으면(직접 고른 폴더) 맨 위에 따로 보인다.
    final listed = folders.any(
      (f) => normalizeFolderPath(f.path) == normalizeFolderPath(cur),
    );
    final paths = [
      if (cur.isNotEmpty && !listed) cur,
      for (final f in folders) f.path,
    ];

    return AppDialog(
      title: l10n.saveFolderTitle,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .45,
        ),
        child: paths.isEmpty
            ? Text(
                l10n.saveFolderEmpty,
                style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final path in paths)
                    _FolderOption(
                      path: path,
                      selected:
                          normalizeFolderPath(path) == normalizeFolderPath(cur),
                      onTap: () => Navigator.of(context).pop(path),
                    ),
                ],
              ),
      ),
      actions: [
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(context).pop(),
        ),
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
    );
  }
}

class _FolderOption extends StatelessWidget {
  const _FolderOption({
    required this.path,
    required this.selected,
    required this.onTap,
  });

  final String path;
  final bool selected;
  final VoidCallback onTap;

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
              child: Text(
                path,
                style: text.titleSmall?.copyWith(
                  color: selected ? p.accent : p.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected) Icon(AppIcons.check, size: 18, color: p.accent),
          ],
        ),
      ),
    );
  }
}
