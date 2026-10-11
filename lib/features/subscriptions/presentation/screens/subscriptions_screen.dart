import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/subscribed_channel.dart';
import '../bloc/new_videos_cubit.dart';
import '../bloc/subscriptions_cubit.dart';
import '../widgets/category_choices.dart';
import '../widgets/channel_options_sheet.dart';
import '../widgets/new_videos_sheet.dart';

/// 구독한 채널 목록: 채널별 켜고 끄기, 줄을 누르면 알림 분류 · 저장 위치 · 구독 해제 옵션.
/// 위에서 채널 검색과 새 영상 목록(바텀시트)으로 간다.
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
                Padding(
                  padding: AppSpacing.screen.copyWith(
                    top: AppSpacing.xs,
                    bottom: AppSpacing.sm,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        PillButton(
                          label: l10n.channelSearchTitle,
                          icon: AppIcons.search,
                          onPressed: () => context.push(Routes.channelSearch),
                        ),
                        if (state.channels.isNotEmpty)
                          PillButton(
                            label: l10n.subscriptionsNewVideos,
                            icon: AppIcons.download,
                            variant: PillVariant.tonal,
                            onPressed: () => showNewVideosSheet(context),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: state.channels.isEmpty
                      // 구독이 없으면 안내를 남은 자리 한가운데에 둔다.
                      ? const Center(child: _Empty())
                      : ListView(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          children: [
                            for (final c in state.channels)
                              _ChannelRow(channel: c, cubit: _cubit),
                          ],
                        ),
                ),
                _TestButtons(
                  onNotification: _cubit.showTestNotification,
                  onNewVideos: () {
                    sl<NewVideosCubit>().showSample();
                    showNewVideosSheet(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
    );
  }
}

/// 채널 한 줄: 이미지 · 이름 · 분류와 저장 위치 요약, 오른쪽에 켜고 끄기. 줄을 누르면 옵션 시트.
class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.channel, required this.cubit});

  final SubscribedChannel channel;
  final SubscriptionsCubit cubit;

  /// 폴더 경로의 마지막 이름 (요약에 짧게 보이려고).
  static String _folderName(String path) {
    final parts = path.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty);
    return parts.isEmpty ? path : parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final thumb = channel.thumbnailUrl;
    return Opacity(
      opacity: channel.enabled ? 1 : .5,
      child: TrackTile(
        title: channel.name,
        subtitle: [
          categorySummary(context, channel.categories),
          if (channel.savePath.isNotEmpty) _folderName(channel.savePath),
        ].join(' · '),
        leading: ArtworkBox(
          image: thumb == null ? null : NetworkImage(thumb),
          radius: 24,
          tone: toneFor(channel.id),
          icon: AppIcons.person,
        ),
        trailing: AppSwitch(
          value: channel.enabled,
          onChanged: (v) => cubit.setEnabled(channel.id, v),
        ),
        onTap: () => showChannelOptionsSheet(context, cubit, channel.id),
      ),
    );
  }
}

/// 임시: 알림과 새 영상 목록이 어떻게 보이는지 확인하는 버튼 (확인이 끝나면 지운다).
class _TestButtons extends StatelessWidget {
  const _TestButtons({required this.onNotification, required this.onNewVideos});

  final VoidCallback onNotification;
  final VoidCallback onNewVideos;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: p.outline),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.subscriptionsTestTitle,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          // 글자 왼쪽 끝을 위 글과 맞추려고 버튼 안쪽 여백만큼 당긴다.
          Transform.translate(
            offset: const Offset(-AppSpacing.sm, 0),
            child: Wrap(
              children: [
                PlainButton(
                  label: l10n.subscriptionsTestNotification,
                  icon: AppIcons.sparkle,
                  onPressed: onNotification,
                ),
                PlainButton(
                  label: l10n.subscriptionsTestNewVideos,
                  icon: AppIcons.sparkle,
                  onPressed: onNewVideos,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
