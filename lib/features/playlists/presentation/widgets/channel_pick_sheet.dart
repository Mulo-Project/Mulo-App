import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../subscriptions/domain/entities/subscribed_channel.dart';
import '../../../subscriptions/presentation/bloc/subscriptions_cubit.dart';

/// 구독한 채널을 골라 그 채널의 재생목록을 가져오는 바텀 시트.
/// 고른 채널을 돌려준다. 맨 아래 줄은 "내 YouTube 구독에서 채널 고르기" 화면으로 가서 구독을 더하는 길이다.
Future<SubscribedChannel?> showChannelPickSheet(BuildContext context) {
  final l10n = context.l10n;
  final subs = sl<SubscriptionsCubit>()..load();
  final router = GoRouter.of(context);
  return showAppSheet<SubscribedChannel>(
    context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheet).height * .7,
        ),
        child: Padding(
          padding: appSheetPadding,
          child: BlocBuilder<SubscriptionsCubit, SubscriptionsState>(
            bloc: subs,
            builder: (context, state) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSheetTitle(l10n.channelPickTitle),
                const SizedBox(height: AppSpacing.xs),
                Flexible(
                  child: !state.loaded
                      ? const LoadingState()
                      : state.channels.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Text(
                            l10n.channelPickEmpty,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: context.palette.onSurfaceMuted,
                                ),
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            for (final c in state.channels)
                              TrackTile(
                                title: c.name,
                                subtitle: '',
                                tone: toneFor(c.id),
                                artwork: c.thumbnailUrl == null
                                    ? null
                                    : NetworkImage(c.thumbnailUrl!),
                                horizontalPadding: 0,
                                trailing: Icon(
                                  AppIcons.chevronRight,
                                  color: context.palette.onSurfaceMuted,
                                ),
                                onTap: () => Navigator.of(sheet).pop(c),
                              ),
                          ],
                        ),
                ),
                MenuRow(
                  icon: AppIcons.add,
                  label: l10n.channelImportOpen,
                  onTap: () {
                    Navigator.of(sheet).pop();
                    router.push(Routes.channelImport);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
