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
import 'save_path_row.dart';
import 'subscription_sheet.dart';

/// 채널 검색 결과를 눌렀을 때 뜨는 간단한 채널 정보 시트: 이미지 · 이름 · 구독자 수 · 소개,
/// 알림 받을 분류 · 저장 위치 고르기, 구독 · 구독 해제.
Future<void> showChannelInfoSheet(BuildContext context, ChannelHit hit) =>
    showSubscriptionSheet<void>(
      context,
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
    final locale = Localizations.localeOf(context).toString();
    final thumb = hit.thumbnailUrl;
    return SingleChildScrollView(
      padding: sheetPadding,
      child: BlocBuilder<ChannelInfoCubit, ChannelInfoState>(
        bloc: _info,
        builder: (context, info) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info.bannerUrl != null) ...[
              _Banner(url: info.bannerUrl!),
              const SizedBox(height: AppSpacing.md),
            ],
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
                        style: text.bodyMedium?.copyWith(
                          color: p.onSurfaceMuted,
                        ),
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
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.subscriptionsCategories, style: text.titleMedium),
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

/// 채널 배너: 가로로 긴 이미지를 둥근 모서리로 보여 준다. 못 불러오면 자리를 비운다.
class _Banner extends StatelessWidget {
  const _Banner({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadii.md),
    child: AspectRatio(
      aspectRatio: 16 / 5,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
        frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
          opacity: frame == null && !sync ? 0 : 1,
          duration: AppMotion.medium,
          child: child,
        ),
      ),
    ),
  );
}
