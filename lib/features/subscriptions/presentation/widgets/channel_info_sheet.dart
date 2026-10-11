import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/channel_hit.dart';
import '../../domain/usecases/subscription_usecases.dart';
import '../bloc/channel_info_cubit.dart';
import '../bloc/subscriptions_cubit.dart';
import 'category_choices.dart';

/// 채널 검색 결과를 눌렀을 때 뜨는 간단한 채널 정보 시트: 이미지 · 이름 · 구독자 수 · 소개,
/// 알림 받을 분류 고르기, 구독 · 구독 해제.
Future<void> showChannelInfoSheet(BuildContext context, ChannelHit hit) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.md)),
      ),
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
      _info.load(widget.hit.url, existing?.categories ?? const {});
    });
  }

  @override
  void dispose() {
    _info.close();
    super.dispose();
  }

  /// 이미 구독 중이면 고른 분류를 바로 저장한다.
  void _changed() {
    if (_subs.state.isSubscribedId(widget.hit.id)) {
      _subs.setCategories(widget.hit.id, _info.state.categories);
    }
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
      SubscribeParams.fromHit(widget.hit, categories: _info.state.categories),
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
    final locale = Localizations.localeOf(context).toString();
    final thumb = hit.thumbnailUrl;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: BlocBuilder<ChannelInfoCubit, ChannelInfoState>(
          bloc: _info,
          builder: (context, info) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ArtworkBox(
                    image: thumb == null ? null : NetworkImage(thumb),
                    size: 64,
                    radius: 32,
                    tone: toneFor(hit.id),
                    icon: AppIcons.person,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hit.name, style: text.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (info.subscriberCount != null)
                              l10n.mediaDetailSubscribers(
                                NumberFormat.compact(locale: locale)
                                    .format(info.subscriberCount),
                              ),
                            if (hit.videoCount != null && hit.videoCount! > 0)
                              l10n.channelInfoVideoCount(hit.videoCount!),
                          ].join(' · '),
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hit.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  hit.description,
                  style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.subscriptionsCategories, style: text.titleSmall),
              const SizedBox(height: 2),
              Text(l10n.subscriptionsCategoriesDesc, style: text.bodySmall),
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
      ),
    );
  }
}
