import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../account/domain/entities/google_account.dart';
import '../../../account/presentation/widgets/sign_in_flow.dart';
import '../../domain/entities/channel_hit.dart';
import '../../domain/usecases/subscription_usecases.dart';
import '../bloc/my_subscriptions_cubit.dart';
import '../bloc/subscriptions_cubit.dart';
import '../widgets/channel_info_sheet.dart';

/// 내 YouTube 구독 채널 가져오기: 구글 계정이 구독한 채널 목록에서 채널 검색처럼
/// 행마다 구독 버튼으로 앱의 구독 채널에 추가하거나 해제한다.
class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  late final MySubscriptionsCubit _cubit = sl<MySubscriptionsCubit>();
  late final SubscriptionsCubit _subs = sl<SubscriptionsCubit>()..load();

  /// 로그인 확인에서 멈췄는지 (안내 화면에서 다시 시작하게 한다).
  bool _signInNeeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  /// 로그인을 확인하고 목록을 읽는다. 로그인을 하지 않았으면 안내 화면에서 다시 시작할 수 있다.
  Future<void> _open() async {
    if (!mounted) return;
    if (!await ensureGoogleSignIn(context) || !mounted) {
      if (mounted) setState(() => _signInNeeded = true);
      return;
    }
    setState(() => _signInNeeded = false);
    await _cubit.load();
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
          child: BlocBuilder<SubscriptionsCubit, SubscriptionsState>(
            bloc: _subs,
            builder: (context, subs) =>
                BlocBuilder<MySubscriptionsCubit, MySubscriptionsState>(
                  bloc: _cubit,
                  builder: (context, state) => Column(
                    children: [
                      AppTopBar(
                        title: l10n.channelImportTitle,
                        leading: const AppBackButton(),
                      ),
                      Expanded(child: _body(context, state, subs)),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    MySubscriptionsState state,
    SubscriptionsState subs,
  ) {
    final l10n = context.l10n;
    if (_signInNeeded && state.status == MySubscriptionsStatus.idle) {
      return EmptyState.signIn(
        body: l10n.channelImportSignInBody,
        onSignIn: _open,
      );
    }
    switch (state.status) {
      case MySubscriptionsStatus.idle:
      case MySubscriptionsStatus.loading:
        return LoadingState(
          label: state.loaded == 0
              ? null
              : l10n.channelImportLoading(state.loaded),
        );
      case MySubscriptionsStatus.failed:
        return switch (state.failure) {
          AccountFailure.unauthorized => EmptyState.signIn(
            body: l10n.playlistImportLoginExpiredBody,
            onSignIn: _open,
          ),
          AccountFailure.network => EmptyState.network(onRetry: _open),
          AccountFailure.timeout => EmptyState.timeout(onRetry: _open),
          AccountFailure.noChannel => EmptyState(
            icon: AppIcons.person,
            title: l10n.playlistImportNoChannelTitle,
            body: l10n.playlistImportNoChannelBody,
          ),
          _ => EmptyState(
            icon: AppIcons.hourglassEmpty,
            title: l10n.searchErrorTitle,
            body: state.detail.isEmpty
                ? l10n.searchErrorBody
                : '${l10n.searchErrorBody}\n(${state.detail})',
            action: PillButton(
              label: l10n.actionRetry,
              icon: AppIcons.refresh,
              compact: true,
              onPressed: _open,
            ),
          ),
        };
      case MySubscriptionsStatus.done:
        if (state.channels.isEmpty) {
          return EmptyState(
            icon: AppIcons.person,
            title: l10n.channelImportEmptyTitle,
            body: l10n.channelImportEmptyBody,
          );
        }
        // 구독이 수백~수천 개일 수 있어 보이는 행만 만든다.
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          itemCount: state.channels.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: AppSpacing.screen.copyWith(bottom: AppSpacing.xs),
                child: Text(
                  l10n.channelImportHint,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.palette.onSurfaceMuted),
                ),
              );
            }
            final c = state.channels[i - 1];
            return _Row(
              key: ValueKey(c.id),
              hit: c,
              subscribed: subs.isSubscribedId(c.id),
              onToggle: () => _toggle(c),
              onOpen: () => showChannelInfoSheet(context, c),
            );
          },
        );
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
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
