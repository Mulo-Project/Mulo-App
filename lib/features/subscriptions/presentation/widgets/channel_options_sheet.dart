import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/channel_details.dart';
import '../../domain/usecases/subscription_usecases.dart';
import '../bloc/subscriptions_cubit.dart';
import 'category_choices.dart';
import 'channel_info_sheet.dart' show ChannelBanner;
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
            _ChannelHeader(
              channelId: channel.id,
              name: channel.name,
              thumbnailUrl: thumb,
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionTitle(l10n.subscriptionsCategories, padded: false),
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

/// 시트 맨 위: 채널 배너 · 이미지 · 이름 · 구독자 수. 배너 · 구독자 수는 시트를 열 때 한 번 읽어 온다
/// (못 읽으면 이미지와 이름만 보인다).
class _ChannelHeader extends StatefulWidget {
  const _ChannelHeader({
    required this.channelId,
    required this.name,
    required this.thumbnailUrl,
  });

  final String channelId;
  final String name;
  final String? thumbnailUrl;

  @override
  State<_ChannelHeader> createState() => _ChannelHeaderState();
}

class _ChannelHeaderState extends State<_ChannelHeader> {
  ChannelDetails? _details;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await sl<FetchChannelDetails>()(widget.channelId);
      if (mounted) setState(() => _details = d);
    } on Object {
      // 배너 · 구독자 수는 덤이라 못 읽어도 시트는 그대로 쓴다.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final thumb = widget.thumbnailUrl;
    final banner = _details?.bannerUrl;
    final subscribers = _details?.subscriberCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (banner != null) ...[
          ChannelBanner(url: banner),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: [
            ArtworkBox(
              image: thumb == null ? null : NetworkImage(thumb),
              size: 48,
              radius: 24,
              tone: toneFor(widget.channelId),
              icon: AppIcons.person,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: text.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subscribers != null)
                    Text(
                      l10n.mediaDetailSubscribers(
                        NumberFormat.compact(locale: locale)
                            .format(subscribers),
                      ),
                      style: text.bodyMedium?.copyWith(
                        color: context.palette.onSurfaceMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
