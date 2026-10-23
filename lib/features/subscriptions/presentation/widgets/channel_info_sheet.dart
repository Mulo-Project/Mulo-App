import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/channel_hit.dart';
import '../../domain/usecases/subscription_usecases.dart';
import '../bloc/channel_info_cubit.dart';
import '../bloc/subscriptions_cubit.dart';
import 'category_choices.dart';
import 'channel_header.dart';
import 'save_path_row.dart';

/// 채널 검색 결과를 눌렀을 때 뜨는 간단한 채널 정보 시트: 이미지 · 이름 · 구독자 수 · 소개,
/// 알림 받을 분류 · 저장 위치 고르기, 구독 · 구독 해제.
Future<void> showChannelInfoSheet(BuildContext context, ChannelHit hit) =>
    showAppSheet<void>(
      context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ChannelInfoSheet(hit: hit),
    );

class _ChannelInfoSheet extends StatefulWidget {
  const _ChannelInfoSheet({required this.hit});

  final ChannelHit hit;

  @override
  State<_ChannelInfoSheet> createState() => _ChannelInfoSheetState();
}

class _ChannelInfoSheetState extends State<_ChannelInfoSheet> {
  late final ChannelInfoCubit _info = sl<ChannelInfoCubit>();
  late final SubscriptionsCubit _subs = sl<SubscriptionsCubit>();

  @override
  void initState() {
    super.initState();
    _subs.load().then((_) {
      final existing = _subs.state.channels
          .where((c) => c.id == widget.hit.id)
          .firstOrNull;
      _info.load(
        widget.hit.id,
        categories: existing?.categories ?? const {},
        savePath: existing?.savePath ?? '',
      );
    });
  }

  @override
  void dispose() {
    _info.close();
    super.dispose();
  }

  /// 이미 구독 중이면 고른 분류 · 저장 위치를 바로 저장한다.
  void _changed() {
    final id = widget.hit.id;
    if (!_subs.state.isSubscribedId(id)) return;
    _subs.setCategories(id, _info.state.categories);
    _subs.setSavePath(id, _info.state.savePath);
  }

  Future<void> _toggleSubscription() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (_subs.state.isSubscribedId(widget.hit.id)) {
      await _subs.unsubscribe(widget.hit.id);
      messenger.showSnackBar(SnackBar(content: Text(l10n.unsubscribed)));
      return;
    }
    final result = await _subs.subscribe(
      SubscribeParams.fromHit(
        widget.hit,
        categories: _info.state.categories,
        savePath: _info.state.savePath,
      ),
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result == SubscribeResult.failed
              ? l10n.subscribeFailed
              : l10n.subscribeAdded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final hit = widget.hit;
    return SingleChildScrollView(
      padding: appSheetPadding,
      child: BlocBuilder<ChannelInfoCubit, ChannelInfoState>(
        bloc: _info,
        builder: (context, info) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChannelHeader(
              id: hit.id,
              name: hit.name,
              thumbnailUrl: hit.thumbnailUrl,
              bannerUrl: info.bannerUrl,
              subscriberCount: info.subscriberCount,
              videoCount: hit.videoCount,
              // 소개는 읽어 온 전체를 먼저 쓰고, 아직이거나 못 읽었으면 검색 결과의 한 토막.
              description: info.description ?? hit.description,
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionTitle(l10n.subscriptionsCategories, padded: false),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.subscriptionsCategoriesDesc,
              style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            CategoryChoices(
              selected: info.categories,
              onToggle: (name) {
                _info.toggleCategory(name);
                _changed();
              },
              onClear: () {
                _info.clearCategories();
                _changed();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            SavePathRow(
              path: info.savePath,
              onChanged: (path) {
                _info.setSavePath(path);
                _changed();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            BlocBuilder<SubscriptionsCubit, SubscriptionsState>(
              bloc: _subs,
              builder: (context, subs) {
                final subscribed = subs.isSubscribedId(hit.id);
                return SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    label: subscribed
                        ? l10n.subscriptionsUnsubscribe
                        : l10n.subscribeAction,
                    icon: subscribed ? AppIcons.delete : AppIcons.add,
                    variant: subscribed
                        ? PillVariant.tonal
                        : PillVariant.accent,
                    onPressed: subs.loaded ? _toggleSubscription : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
