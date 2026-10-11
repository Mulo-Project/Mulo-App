import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../downloads/domain/usecases/download_usecases.dart';
import '../../../downloads/presentation/widgets/save_folder_dialog.dart';

/// 채널의 새 영상을 저장할 폴더 한 줄: 지금 위치(비어 있으면 기본 저장 위치)와 변경 · 기본으로.
/// 폴더를 고르면 [onChanged]에 경로를, 기본으로 되돌리면 빈 문자열을 넘긴다.
class SavePathRow extends StatelessWidget {
  const SavePathRow({super.key, required this.path, required this.onChanged});

  final String path;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.channelSaveFolder, style: text.titleSmall),
        const SizedBox(height: 2),
        Text(
          path.isEmpty ? l10n.channelSaveFolderDefault : path,
          style: text.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        // 글자 왼쪽 끝을 위 글과 맞추려고 버튼 안쪽 여백만큼 당긴다.
        Transform.translate(
          offset: const Offset(-AppSpacing.sm, 0),
          child: Wrap(
            children: [
              PlainButton(
                label: l10n.channelSaveFolderChange,
                icon: AppIcons.edit,
                accent: true,
                onPressed: () async {
                  final picked = await showSaveFolderDialog(
                    context,
                    current: path,
                    pickOther: () => sl<PickSaveFolder>()(const NoParams()),
                  );
                  if (picked != null) onChanged(picked);
                },
              ),
              if (path.isNotEmpty)
                PlainButton(
                  label: l10n.channelSaveFolderReset,
                  onPressed: () => onChanged(''),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
