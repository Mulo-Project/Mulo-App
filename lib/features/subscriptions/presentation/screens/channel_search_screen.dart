import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/channel_hit.dart';
import '../../domain/usecases/subscription_usecases.dart';
import '../bloc/channel_search_cubit.dart';
import '../bloc/subscriptions_cubit.dart';
import '../widgets/channel_info_sheet.dart';

/// 채널 검색: 키워드로 채널을 찾아 구독한다.
class ChannelSearchScreen extends StatefulWidget {
  const ChannelSearchScreen({super.key});

  @override
  State<ChannelSearchScreen> createState() => _ChannelSearchScreenState();
}

class _ChannelSearchScreenState extends State<ChannelSearchScreen> {
  final _controller = TextEditingController();
  late final ChannelSearchCubit _cubit = sl<ChannelSearchCubit>();
  late final SubscriptionsCubit _subs = sl<SubscriptionsCubit>()..load();

  @override
  void dispose() {
    _controller.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _toggle(ChannelHit hit) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (_subs.state.isSubscribedId(hit.id)) {
      await _subs.unsubscribe(hit.id);
      return;
    }
    final result = await _subs.subscribe(SubscribeParams.fromHit(hit));
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
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.channelSearchTitle,
                leading: const AppBackButton(),
              ),
              Padding(
                padding: AppSpacing.screen,
                child: AppSearchField(
                  controller: _controller,
                  hint: l10n.channelSearchHint,
                  clearTooltip: l10n.actionClear,
                  autofocus: true,
                  onSubmitted: _cubit.search,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: BlocBuilder<ChannelSearchCubit, ChannelSearchState>(
                  bloc: _cubit,
                  builder: (context, state) {
                    Widget message(String title) => EmptyState(title: title);
                    return switch (state.status) {
                      ChannelSearchStatus.idle => message(
                        l10n.channelSearchIdle,
                      ),
                      ChannelSearchStatus.loading => LoadingState(
                        label: l10n.channelSearchLoading,
                      ),
                      ChannelSearchStatus.failed => message(
                        l10n.channelSearchFailed,
                      ),
                      ChannelSearchStatus.done =>
                        state.results.isEmpty
                            ? message(l10n.channelSearchEmpty)
                            : BlocBuilder<
                                SubscriptionsCubit,
                                SubscriptionsState
                              >(
                                bloc: _subs,
                                builder: (context, subs) => ListView(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.lg,
                                  ),
                                  children: [
                                    for (final hit in state.results)
                                      _Row(
                                        hit: hit,
                                        subscribed: subs.isSubscribedId(hit.id),
                                        onToggle: () => _toggle(hit),
                                        onOpen: () =>
                                            showChannelInfoSheet(context, hit),
                                      ),
                                  ],
                                ),
                              ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.hit,
    required this.subscribed,
    required this.onToggle,
    required this.onOpen,
  });

  final ChannelHit hit;
  final bool subscribed;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final thumb = hit.thumbnailUrl;
    return TrackTile(
      title: hit.name,
      subtitle: hit.description,
      tone: toneFor(hit.id),
      artwork: thumb == null ? null : NetworkImage(thumb),
      // 버튼 안쪽 여백만큼 밀어 글자 오른쪽 끝을 검색창 · 다른 줄의 오른쪽 끝과 맞춘다.
      trailing: Transform.translate(
        offset: const Offset(AppSpacing.sm, 0),
        child: PlainButton(
          label: subscribed ? l10n.subscribedAction : l10n.subscribeAction,
          icon: subscribed ? AppIcons.check : AppIcons.add,
          accent: !subscribed,
          onPressed: onToggle,
        ),
      ),
      onTap: onOpen,
    );
  }
}
