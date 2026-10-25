import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/playlists_cubit.dart';
import '../widgets/new_playlist_sheet.dart';
import '../widgets/playlist_card.dart';
import '../widgets/playlist_grid.dart';

/// 곡을 담을 재생목록 고르기. 곡 메뉴의 "재생목록에 추가"가 팝업 대신 이 화면으로 온다.
/// 재생목록 카드를 눌러 여러 개 고르고 "완료"를 누르면 [trackIds]를 담고 돌아간다.
class PlaylistPickScreen extends StatefulWidget {
  const PlaylistPickScreen({super.key, required this.trackIds});

  final Set<String> trackIds;

  @override
  State<PlaylistPickScreen> createState() => _PlaylistPickScreenState();
}

class _PlaylistPickScreenState extends State<PlaylistPickScreen> {
  final _picked = <String>{};

  void _toggle(String id) => setState(() {
    _picked.contains(id) ? _picked.remove(id) : _picked.add(id);
  });

  Future<void> _new() async {
    final id = await showNewPlaylistSheet(context);
    if (id != null && mounted) setState(() => _picked.add(id));
  }

  Future<void> _done() async {
    final l10n = context.l10n;
    final cubit = context.read<PlaylistsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final picked = {..._picked};
    for (final id in picked) {
      await cubit.addTracks(widget.trackIds, id);
    }
    router.pop();
    if (picked.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.trackMenuAddedToPlaylists(picked.length))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final lists = context.watch<PlaylistsCubit>().state;

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.playlistPickTitle,
                leading: const AppBackButton(),
                actions: [
                  CircleIconButton(
                    icon: AppIcons.add,
                    tooltip: l10n.playlistsNew,
                    emphasized: true,
                    onPressed: _new,
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: AppSpacing.screen.copyWith(
                    top: AppSpacing.xs,
                    bottom: AppSpacing.md,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        l10n.playlistPickHint,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: p.onSurfaceMuted),
                      ),
                    ),
                    PlaylistGrid(
                      lists: lists,
                      cardBuilder: (context, pl) {
                        // 담으려는 곡이 이미 모두 들어 있으면 고를 필요가 없다.
                        final already = widget.trackIds.every(
                          pl.trackIds.contains,
                        );
                        return PlaylistCard(
                          playlist: pl,
                          selected: already || _picked.contains(pl.id),
                          already: already,
                          onTap: already ? () {} : () => _toggle(pl.id),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    label: l10n.playlistPickDone,
                    icon: AppIcons.check,
                    onPressed: _done,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
