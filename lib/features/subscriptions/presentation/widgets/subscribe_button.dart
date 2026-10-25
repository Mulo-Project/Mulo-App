import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/usecases/subscription_usecases.dart';
import '../bloc/subscriptions_cubit.dart';

/// 영상 상세의 채널 줄에 붙는 구독 버튼. 유튜브 채널만 구독할 수 있다 (그 밖에는 아무것도 그리지 않는다).
class SubscribeButton extends StatelessWidget {
  const SubscribeButton({
    super.key,
    required this.channelUrl,
    required this.name,
    this.thumbnailUrl,
  });

  final String? channelUrl;
  final String name;
  final String? thumbnailUrl;

  static bool supports(String? url) {
    final host = Uri.tryParse(url ?? '')?.host ?? '';
    return host == 'youtube.com' || host.endsWith('.youtube.com');
  }

  @override
  Widget build(BuildContext context) {
    final url = channelUrl;
    if (url == null || !supports(url)) return const SizedBox.shrink();
    final cubit = sl<SubscriptionsCubit>()..load();
    final l10n = context.l10n;
    return BlocBuilder<SubscriptionsCubit, SubscriptionsState>(
      bloc: cubit,
      builder: (context, state) {
        final subscribed = state.isSubscribed(url);
        return PlainButton(
          label: subscribed ? l10n.subscribedAction : l10n.subscribeAction,
          icon: subscribed ? AppIcons.check : AppIcons.add,
          accent: !subscribed,
          onPressed: !state.loaded
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (subscribed) {
                    await cubit.unsubscribeByUrl(url);
                    return;
                  }
                  final result = await cubit.subscribe(
                    SubscribeParams(
                      channelUrl: url,
                      name: name,
                      thumbnailUrl: thumbnailUrl,
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
                },
        );
      },
    );
  }
}
