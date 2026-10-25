import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import 'category_choices.dart';
import 'save_path_row.dart';

/// 채널 시트 아래쪽 설정 구역 둘: 알림 받을 분류(표) · 새 영상 저장 위치.
/// 머리 · 각 구역 · 구독 버튼 사이를 가는 선과 제목으로 나눈다. 채널 정보 시트와 구독 채널 옵션 시트가 같이 쓴다.
class ChannelSettingsSections extends StatelessWidget {
  const ChannelSettingsSections({
    super.key,
    required this.categories,
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.savePath,
    required this.onSavePath,
  });

  final Set<String> categories;
  final ValueChanged<String> onToggleCategory;
  final VoidCallback onClearCategories;
  final String savePath;
  final ValueChanged<String> onSavePath;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        const AppDivider(),
        const SizedBox(height: AppSpacing.md),
        SectionTitle(l10n.subscriptionsCategories, padded: false),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          l10n.subscriptionsCategoriesDesc,
          style: text.bodyMedium?.copyWith(
            color: context.palette.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CategoryChoices(
          selected: categories,
          onToggle: onToggleCategory,
          onClear: onClearCategories,
        ),
        const SizedBox(height: AppSpacing.md),
        const AppDivider(),
        const SizedBox(height: AppSpacing.md),
        SectionTitle(l10n.channelSaveFolder, padded: false),
        const SizedBox(height: AppSpacing.sm),
        SavePathRow(path: savePath, onChanged: onSavePath),
      ],
    );
  }
}
