import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../account/domain/entities/google_account.dart';
import '../../../account/presentation/widgets/sign_in_flow.dart';
import '../../../library/presentation/widgets/library_selection.dart'
    show LibrarySelectionBottomBar;
import '../../domain/entities/channel_hit.dart';
import '../../domain/usecases/subscription_usecases.dart';
import '../bloc/my_subscriptions_cubit.dart';
import '../bloc/subscriptions_cubit.dart';

/// 내 YouTube 구독 채널 가져오기: 구글 계정이 구독한 채널 목록에서 채널을 골라(전체를 한꺼번에 가져오지 않는다)
/// 앱의 구독 채널로 추가한다. 이미 구독한 채널은 "구독 중"으로 보이고 고를 수 없다.
class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

enum _Action { subscribe, selectNew }

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

  Set<String> get _subscribedIds => {
    for (final c in _subs.state.channels) c.id,
  };

  Future<void> _actions() async {
    final l10n = context.l10n;
    final ids = _subscribedIds;
    final count = _cubit.pickedChannels(ids).length;
    final action = await showAppSheet<_Action>(
      context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: appSheetPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSheetTitle(l10n.channelImportSelectCount(count)),
              const SizedBox(height: AppSpacing.xs),
              MenuRow(
                icon: AppIcons.add,
                label: l10n.channelImportSubscribe,
                onTap: () => Navigator.of(sheet).pop(_Action.subscribe),
              ),
              MenuRow(
                icon: AppIcons.checkCircle,
                label: l10n.channelImportSelectNew,
                onTap: () => Navigator.of(sheet).pop(_Action.selectNew),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _Action.selectNew:
        _cubit.pickAllNew(ids);
      case _Action.subscribe:
        await _subscribe();
    }
  }

  Future<void> _subscribe() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final picked = _cubit.pickedChannels(_subscribedIds);
    if (picked.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialog) => AppDialog(
        title: l10n.channelImportConfirmTitle,
        body: l10n.channelImportConfirmBody(picked.length),
        actions: [
          PillButton(
            label: l10n.actionCancel,
            variant: PillVariant.tonal,
            onPressed: () => Navigator.of(dialog).pop(false),
          ),
          PillButton(
            label: l10n.selectConfirmApply,
            onPressed: () => Navigator.of(dialog).pop(true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final added = await _subs.subscribeAll([
      for (final c in picked) SubscribeParams.fromHit(c),
    ]);
    _cubit.clearPicked();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          added == 0 ? l10n.subscribeFailed : l10n.channelImportDone(added),
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
                  builder: (context, state) => Stack(
                    children: [
                      Column(
                        children: [
                          AppTopBar(
                            title: l10n.channelImportTitle,
                            leading: const AppBackButton(),
                          ),
                          Expanded(child: _body(context, state, subs)),
                        ],
                      ),
                      if (state.picked.isNotEmpty)
                        Positioned(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          bottom:
                              AppSpacing.sm +
                              MediaQuery.paddingOf(context).bottom,
                          child: LibrarySelectionBottomBar(
                            count: state.picked.length,
                            countLabel: l10n.channelImportSelectCount(
                              state.picked.length,
                            ),
                            onClose: _cubit.clearPicked,
                            onActions: _actions,
                          ),
                        ),
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
          padding: EdgeInsets.only(
            bottom: AppSpacing.lg + (state.picked.isEmpty ? 0 : 72),
          ),
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
              picked: state.picked.contains(c.id),
              onTap: () => _cubit.toggle(c.id),
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
    required this.picked,
    required this.onTap,
  });

  final ChannelHit hit;
  final bool subscribed;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final thumb = hit.thumbnailUrl;
    return Opacity(
      opacity: subscribed ? .5 : 1,
      child: TrackTile(
        title: hit.name,
        subtitle: subscribed ? l10n.channelImportAlready : hit.description,
        tone: toneFor(hit.id),
        artwork: thumb == null ? null : NetworkImage(thumb),
        trailing: subscribed
            ? Icon(AppIcons.check, color: p.onSurfaceMuted)
            : Icon(
                picked ? AppIcons.checkCircle : AppIcons.radioOff,
                color: picked ? p.accent : p.onSurfaceMuted,
              ),
        onTap: subscribed ? null : onTap,
      ),
    );
  }
}
