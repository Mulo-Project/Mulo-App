import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/channel_details.dart';
import '../../domain/usecases/subscription_usecases.dart';
import '../bloc/subscriptions_cubit.dart';
import 'channel_header.dart';
import 'channel_settings_sections.dart';

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
            ChannelSettingsSections(
              categories: channel.categories,
              onToggleCategory: (name) => cubit.setCategories(
                channel.id,
                channel.categories.contains(name)
                    ? ({...channel.categories}..remove(name))
                    : {...channel.categories, name},
              ),
              onClearCategories: () =>
                  cubit.setCategories(channel.id, const {}),
              savePath: channel.savePath,
              onSavePath: (path) => cubit.setSavePath(channel.id, path),
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

/// 시트 맨 위: [ChannelHeader]. 배너 · 구독자 수 · 소개는 시트를 열 때 한 번 읽어 온다
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
  var _loading = true;

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
      // 배너 · 구독자 수 · 소개는 덤이라 못 읽어도 시트는 그대로 쓴다.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 읽는 동안 위에 얇은 막대로 알린다.
      LoadingBar(loading: _loading),
      const SizedBox(height: AppSpacing.sm),
      ChannelHeader(
        id: widget.channelId,
        name: widget.name,
        thumbnailUrl: widget.thumbnailUrl,
        bannerUrl: _details?.bannerUrl,
        subscriberCount: _details?.subscriberCount,
        description: _details?.description ?? '',
        // 이 시트는 구독한 채널의 옵션이라 늘 구독 중이다.
        subscribed: true,
      ),
    ],
  );
}
