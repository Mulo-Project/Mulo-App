import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/presentation/widgets/library_selection.dart';
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

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with TrackPicker<_Body> {
  // 읽기 전용 목록: 재생목록 추가만 둔다.
  @override
  bool get pickerEditable => false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<HomeBloc>().state;
    final top = state.summary.topTracks;
    final tracks = [for (final t in top) t.track];
    final player = context.read<NowPlayingCubit>();

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              bottom:
                  AppSpacing.lg +
                  MediaQuery.paddingOf(context).bottom +
                  selectionBottomGap,
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
                    selection: selectionFor(tracks[i]),
                  ),
              ],
            ],
          ),
          ?selectionBar(tracks, tracks),
        ],
      ),
    );
  }
}
