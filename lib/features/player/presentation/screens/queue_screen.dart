import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../bloc/now_playing_cubit.dart';

/// 재생 대기열 화면. 곡을 누르면 그 곡부터 재생하고, 지금 재생 중인 곡은 강조한다.
class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final state = context.watch<NowPlayingCubit>().state;
    final vm = context.read<NowPlayingCubit>();

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.playerQueue,
                leading: CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: l10n.actionBack,
                  onPressed: () => context.pop(),
                ),
              ),
              Expanded(
                child: state.queue.isEmpty
                    ? Center(
                        child: Text(
                          l10n.playerQueueEmpty,
                          style: text.bodyMedium?.copyWith(
                            color: p.onSurfaceMuted,
                          ),
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.only(
                          bottom:
                              AppSpacing.lg +
                              MediaQuery.paddingOf(context).bottom,
                        ),
                        children: [
                          Padding(
                            padding: AppSpacing.screen.copyWith(
                              bottom: AppSpacing.xs,
                            ),
                            child: Text(
                              l10n.songCount(state.queue.length),
                              style: text.bodySmall?.copyWith(
                                color: p.onSurfaceMuted,
                              ),
                            ),
                          ),
                          for (var i = 0; i < state.queue.length; i++)
                            TrackTile(
                              title: state.queue[i].title,
                              subtitle: state.queue[i].artist,
                              tone: toneFor(state.queue[i].id),
                              color: coverColorOf(
                                context,
                                CoverKey.track(state.queue[i].id),
                              ),
                              artwork: coverImageOf(
                                context,
                                CoverKey.track(state.queue[i].id),
                              ),
                              active: i == state.index,
                              trailing: Text(
                                formatDuration(state.queue[i].duration),
                                style: text.bodySmall,
                              ),
                              onTap: () => vm.jumpTo(i),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
