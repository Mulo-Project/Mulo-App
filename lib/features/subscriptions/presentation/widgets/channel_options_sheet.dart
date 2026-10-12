import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/subscriptions_cubit.dart';
import 'category_choices.dart';
import 'save_path_row.dart';

/// 구독한 채널의 옵션 시트: 알림 받을 분류 · 저장 위치를 바꾸거나 구독을 해제한다.
/// 고를 때마다 바로 저장한다.
Future<void> showChannelOptionsSheet(
  BuildContext context,
  SubscriptionsCubit cubit,
  String channelId,
) => showAppSheet<void>(
  context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => BlocBuilder<SubscriptionsCubit, SubscriptionsState>(
    bloc: cubit,
    builder: (sheetContext, state) {
      final channel = state.channels
          .where((c) => c.id == channelId)
          .firstOrNull;
      if (channel == null) return const SizedBox.shrink();
      final l10n = sheetContext.l10n;
      final text = Theme.of(sheetContext).textTheme;
      final thumb = channel.thumbnailUrl;
      return SingleChildScrollView(
        padding: appSheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ArtworkBox(
                  image: thumb == null ? null : NetworkImage(thumb),
                  size: 48,
                  radius: 24,
                  tone: toneFor(channel.id),
                  icon: AppIcons.person,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    channel.name,
                    style: text.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.subscriptionsCategories, style: text.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.subscriptionsCategoriesDesc,
              style: text.bodyMedium?.copyWith(
                color: sheetContext.palette.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            CategoryChoices(
              selected: channel.categories,
              onToggle: (name) => cubit.setCategories(
                channel.id,
                channel.categories.contains(name)
                    ? ({...channel.categories}..remove(name))
                    : {...channel.categories, name},
              ),
              onClear: () => cubit.setCategories(channel.id, const {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            SavePathRow(
              path: channel.savePath,
              onChanged: (path) => cubit.setSavePath(channel.id, path),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: PillButton(
                label: l10n.subscriptionsUnsubscribe,
                icon: AppIcons.delete,
                variant: PillVariant.tonal,
                onPressed: () {
                  cubit.unsubscribe(channel.id);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
          ],
        ),
      );
    },
  ),
);
