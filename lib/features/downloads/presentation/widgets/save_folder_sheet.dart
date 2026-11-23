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
///
/// [onFixedChanged]를 주면 "고정" 모드다 (설정): 체크한 폴더가 받을 때 항상 쓰는 기본 위치이고,
/// 누를 때마다 체크가 켜지고 꺼지며 시트는 닫히지 않는다. 체크를 모두 풀면(null) 마지막에 받은 폴더가 기준이다.
/// 이때 [current]는 고정한 폴더(없으면 빈 문자열)이다.
Future<String?> showSaveFolderSheet(
  BuildContext context, {
  required String current,
  required Future<String?> Function() pickOther,
  bool removable = false,
  Future<void> Function(String? path)? onFixedChanged,
  List<String>? only,
}) => showAppSheet<String>(
  context,
  isScrollControlled: true,
  builder: (_) => BlocProvider(
    create: (_) => sl<SaveLocationsCubit>()..load(),
    child: _SaveFolderSheet(
      current: current,
      pickOther: pickOther,
      removable: removable,
      onFixedChanged: onFixedChanged,
      only: only,
    ),
  ),
);

class _SaveFolderSheet extends StatefulWidget {
  const _SaveFolderSheet({
    required this.current,
    required this.pickOther,
    required this.removable,
    this.onFixedChanged,
    this.only,
  });

  final String current;

  /// 주면 이 폴더들 중에서만 고른다 (영상 저장: Movies · Download). 직접 선택은 숨긴다.
  final List<String>? only;

  /// 고정 모드의 변경 알림 (고정하면 경로, 풀면 null). 주면 고정 모드다.
  final Future<void> Function(String? path)? onFixedChanged;

  /// 목록에서 폴더를 뺄 수 있는지 (설정에서만. 받기 · 채널에서는 고르기만 한다).
  final bool removable;
  final Future<String?> Function() pickOther;

  @override
  State<_SaveFolderSheet> createState() => _SaveFolderSheetState();
}

class _SaveFolderSheetState extends State<_SaveFolderSheet> {
  /// 고정 모드에서 지금 체크된 폴더 (빈 문자열이면 체크 없음). 시트가 열려 있는 동안 여기서 바로 바뀐다.
  late String _fixed = widget.current;

  bool get _fixedMode => widget.onFixedChanged != null;

  Future<void> _toggle(String path) async {
    final same = normalizeFolderPath(path) == normalizeFolderPath(_fixed);
    setState(() => _fixed = same ? '' : path);
    await widget.onFixedChanged!(same ? null : path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SaveLocationsCubit>();
    final locations = widget.only ?? context.watch<SaveLocationsCubit>().state;
    final current = _fixedMode ? _fixed : widget.current;
    final removable = widget.removable;
    final pickOther = widget.pickOther;
    final cur = normalizeFolderPath(current);
    // 지금 위치가 목록에 없으면(예전에 뺀 폴더 등) 맨 위에 따로 보인다.
    final listed = locations.any((p) => normalizeFolderPath(p) == cur);
    final paths = [if (cur.isNotEmpty && !listed) current.trim(), ...locations];
    // 고정 모드에서는 체크한 폴더가, 아니면 목록의 첫 항목이 기본 저장 위치다.
    final defaultPath = _fixedMode
        ? cur
        : locations.isEmpty
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
              AppSheetTitle(
                l10n.saveFolderTitle,
                subtitle: _fixedMode ? l10n.saveFolderFixedHint : null,
              ),
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
                              onTap: _fixedMode
                                  ? () => _toggle(path)
                                  : () => Navigator.of(context).pop(path),
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
              if (widget.only == null) ...[
              const SizedBox(height: AppSpacing.md),
              PillButton(
                label: l10n.saveFolderPickOther,
                icon: AppIcons.folder,
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final picked = await pickOther();
                  if (picked == null) return;
                  await cubit.add(picked);
                  if (_fixedMode) {
                    // 새로 고른 폴더를 고정하고 시트는 열어 둔다.
                    if (!mounted) return;
                    setState(() => _fixed = picked);
                    await widget.onFixedChanged!(picked);
                    return;
                  }
                  nav.pop(picked);
                },
              ),
              ],
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
            // 오른쪽 끝 칸은 고정 크기: 체크(선택됨)와 ×(빼기)가 같은 자리 · 같은 크기에 놓인다.
            SizedBox(
              width: AppSizes.rowButton,
              height: AppSizes.rowButton,
              child: selected
                  ? Center(
                      child: Icon(
                        AppIcons.check,
                        size: AppSizes.rowButton * .56,
                        color: p.accent,
                      ),
                    )
                  : onRemove != null
                  ? RowIconButton(
                      icon: AppIcons.close,
                      tooltip: context.l10n.loadedFoldersRemove,
                      onPressed: onRemove,
                    )
                  : null,
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
