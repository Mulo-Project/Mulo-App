import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/loaded_folder.dart';
import '../../../library/presentation/bloc/save_locations_cubit.dart';

/// 저장 위치 고르기 바텀 시트: 저장 위치 목록에서 고르거나, "직접 선택"으로 폴더 선택기를 연다.
/// 목록은 불러오는 폴더와 따로 관리된다 (불러오는 폴더를 더하면 여기에도 더해지지만, 한쪽을 빼도 다른 쪽은 그대로).
/// [current]는 지금 정해진 위치(목록에 없어도 맨 위에 보인다). 고른 폴더를 돌려주고, 닫으면 null.
/// 직접 고른 폴더는 목록에 더한다. [pickOther]는 폴더 선택기 (취소하면 null).
/// [removable]이면 폴더마다 목록에서 빼는 ×가 붙는다 (설정에서 목록을 관리할 때).
Future<String?> showSaveFolderSheet(
  BuildContext context, {
  required String current,
  required Future<String?> Function() pickOther,
  bool removable = false,
}) => showAppSheet<String>(
  context,
  isScrollControlled: true,
  builder: (_) => BlocProvider(
    create: (_) => sl<SaveLocationsCubit>()..load(),
    child: _SaveFolderSheet(
      current: current,
      pickOther: pickOther,
      removable: removable,
    ),
  ),
);

class _SaveFolderSheet extends StatelessWidget {
  const _SaveFolderSheet({
    required this.current,
    required this.pickOther,
    required this.removable,
  });

  final String current;

  /// 목록에서 폴더를 뺄 수 있는지 (설정에서만. 받기 · 채널에서는 고르기만 한다).
  final bool removable;
  final Future<String?> Function() pickOther;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SaveLocationsCubit>();
    final locations = context.watch<SaveLocationsCubit>().state;
    final cur = normalizeFolderPath(current);
    // 지금 위치가 목록에 없으면(예전에 뺀 폴더 등) 맨 위에 따로 보인다.
    final listed = locations.any((p) => normalizeFolderPath(p) == cur);
    final paths = [if (cur.isNotEmpty && !listed) current.trim(), ...locations];
    // 목록의 첫 항목이 기본 저장 위치다.
    final defaultPath = locations.isEmpty
        ? ''
        : normalizeFolderPath(locations.first);

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
                              isDefault:
                                  normalizeFolderPath(path) == defaultPath,
                              selected: normalizeFolderPath(path) == cur,
                              onTap: () => Navigator.of(context).pop(path),
                              // 기본 위치 · 지금 위치 · 목록에 없는 위치는 뺄 수 없다.
                              // 여기서 빼도 불러오는 폴더와 보관함의 곡은 그대로다.
                              onRemove:
                                  !removable ||
                                      normalizeFolderPath(path) ==
                                          defaultPath ||
                                      normalizeFolderPath(path) == cur ||
                                      !locations.any(
                                        (p) =>
                                            normalizeFolderPath(p) ==
                                            normalizeFolderPath(path),
                                      )
                                  ? null
                                  : () => cubit.remove(path),
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
                  if (picked == null) return;
                  await cubit.add(picked);
                  nav.pop(picked);
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
