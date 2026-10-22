import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/home_bloc.dart';
import '../widgets/rank_tile.dart';

/// 많이 들은 곡 상세 화면 경로 (홈 탭 안).
const topTracksLocation = '/home/top-tracks';

/// 많이 들은 곡 상세: 전체 기간 TOP 100. 전체를 재생목록처럼 재생할 수 있다.
class TopTracksScreen extends StatelessWidget {
  const TopTracksScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<HomeBloc>()..add(const HomeStarted()),
    child: const _Body(),
  );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<HomeBloc>().state;
    final top = state.summary.topTracks;
    final tracks = [for (final t in top) t.track];
    final player = context.read<NowPlayingCubit>();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AppTopBar(
            title: l10n.homeTopTracksTitle,
            leading: const AppBackButton(),
          ),
          if (state.loaded && tracks.isEmpty)
            Padding(
              padding: AppSpacing.screen,
              child: Text(
                l10n.homeNoPlays,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else ...[
            Padding(
              padding: AppSpacing.screen,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PillButton(
                  icon: AppIcons.play,
                  label: l10n.actionPlayAll,
                  onPressed: tracks.isEmpty
                      ? null
                      : () => player.playQueue(tracks),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < top.length; i++)
              RankTile(
                rank: i + 1,
                item: top[i],
                onTap: () => player.playQueue(tracks, index: i),
              ),
          ],
        ],
      ),
    );
  }
}
