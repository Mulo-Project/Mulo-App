import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/subscribed_channel.dart';
import '../bloc/subscriptions_cubit.dart';

/// 구독한 채널 목록: 채널별 켜고 끄기 · 음악만 · 구독 해제. 위에서 새 영상 목록으로 간다.
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  late final SubscriptionsCubit _cubit = sl<SubscriptionsCubit>()..load();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: BlocBuilder<SubscriptionsCubit, SubscriptionsState>(
            bloc: _cubit,
            builder: (context, state) => Column(
              children: [
                AppTopBar(
                  title: l10n.subscriptionsTitle,
                  leading: CircleIconButton(
                    icon: AppIcons.back,
                    tooltip: l10n.actionBack,
                    onPressed: () => context.pop(),
                  ),
                ),
                if (state.channels.isNotEmpty)
                  Padding(
                    padding: AppSpacing.screen.copyWith(bottom: AppSpacing.xs),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: PillButton(
                        label: l10n.subscriptionsNewVideos,
                        icon: AppIcons.download,
                        variant: PillVariant.tonal,
                        onPressed: () => context.push(Routes.newVideos),
                      ),
                    ),
                  ),
                Expanded(
                  child: state.channels.isEmpty
                      ? Center(
                          child: Padding(
                            padding: AppSpacing.screen,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.subscriptionsEmptyTitle,
                                  style: text.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n.subscriptionsEmptyBody,
                                  style: text.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          children: [
                            for (final c in state.channels)
                              _ChannelRow(channel: c, cubit: _cubit),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.channel, required this.cubit});

  final SubscribedChannel channel;
  final SubscriptionsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final thumb = channel.thumbnailUrl;
    return Padding(
      padding: AppSpacing.screen.copyWith(
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        children: [
          ArtworkBox(
            image: thumb == null ? null : NetworkImage(thumb),
            size: 44,
            radius: 22,
            tone: toneFor(channel.id),
            icon: AppIcons.person,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.name,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PlainButton(
                    label: l10n.subscriptionsMusicOnly,
                    icon: channel.musicOnly
                        ? AppIcons.checkCircle
                        : AppIcons.radioOff,
                    accent: channel.musicOnly,
                    onPressed: () =>
                        cubit.setMusicOnly(channel.id, !channel.musicOnly),
                  ),
                ),
              ],
            ),
          ),
          AppSwitch(
            value: channel.enabled,
            onChanged: (v) => cubit.setEnabled(channel.id, v),
          ),
          RowIconButton(
            icon: AppIcons.delete,
            tooltip: l10n.subscriptionsUnsubscribe,
            onPressed: () => cubit.unsubscribe(channel.id),
          ),
        ],
      ),
    );
  }
}
