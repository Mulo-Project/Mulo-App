import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../downloads/domain/usecases/download_usecases.dart';
import '../../../downloads/presentation/widgets/save_folder_dialog.dart';

/// 채널의 새 영상을 저장할 폴더: 폭을 가득 채운 한 줄(폴더 아이콘 · 지금 위치). 제목은 바깥 구역 제목이 맡는다.
/// 누르면 폴더를 고르고, 정해 둔 위치가 있으면 오른쪽 버튼으로 기본 저장 위치로 되돌린다.
/// 폴더를 고르면 [onChanged]에 경로를, 되돌리면 빈 문자열을 넘긴다.
class SavePathRow extends StatelessWidget {
  const SavePathRow({super.key, required this.path, required this.onChanged});

  final String path;
  final ValueChanged<String> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showSaveFolderDialog(
      context,
      current: path,
      pickOther: () => sl<PickSaveFolder>()(const NoParams()),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Material(
      color: p.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(color: p.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _pick(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                AppIcons.folder,
                size: AppSizes.iconLg,
                color: path.isEmpty ? p.onSurfaceMuted : p.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  path.isEmpty ? l10n.channelSaveFolderDefault : path,
                  style: text.bodyMedium?.copyWith(
                    color: path.isEmpty ? p.onSurfaceMuted : p.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (path.isEmpty)
                Icon(AppIcons.chevronRight, color: p.onSurfaceMuted)
              else
                RowIconButton(
                  icon: AppIcons.close,
                  tooltip: l10n.channelSaveFolderReset,
                  onPressed: () => onChanged(''),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
