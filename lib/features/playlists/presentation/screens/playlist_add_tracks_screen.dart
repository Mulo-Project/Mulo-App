import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/library_sort.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/presentation/bloc/library_cubit.dart';
import '../../../library/presentation/screens/library_screen.dart'
    show LibraryTab;
import '../../../library/presentation/widgets/track_list_tile.dart'
    show albumOf, artistOf, genreOf;
import '../bloc/playlists_cubit.dart';

/// 재생목록에 곡 추가: 보관함의 곡 가운데 아직 담기지 않은 곡을 여러 개 골라 한꺼번에 담는다.
/// 보관함과 같은 탭(곡 · 아티스트 · 앨범 · 장르)으로 나눠 보고, 아티스트 · 앨범 · 장르 줄을 누르면
/// 그 묶음의 곡을 모두 고르거나 푼다. 위 검색창으로 좁히고, 아래 "N곡 추가"를 누르면 담고 돌아간다.
class PlaylistAddTracksScreen extends StatefulWidget {
  const PlaylistAddTracksScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  State<PlaylistAddTracksScreen> createState() =>
      _PlaylistAddTracksScreenState();
}

class _PlaylistAddTracksScreenState extends State<PlaylistAddTracksScreen> {
  final _picked = <String>{};
  String _query = '';
  LibraryTab _tab = LibraryTab.songs;

  void _toggle(String id) => setState(() {
    _picked.contains(id) ? _picked.remove(id) : _picked.add(id);
  });

  /// 묶음의 곡이 모두 골라져 있으면 모두 풀고, 아니면 모두 고른다.
  void _toggleGroup(List<Track> tracks) => setState(() {
    final ids = tracks.map((t) => t.id);
    if (ids.every(_picked.contains)) {
      _picked.removeAll(ids);
    } else {
      _picked.addAll(ids);
    }
  });

  Future<void> _add() async {
    final cubit = context.read<PlaylistsCubit>();
    final router = GoRouter.of(context);
    await cubit.addTracks({..._picked}, widget.playlistId);
    router.pop();
  }

  List<Track> _candidates(List<Track> all, Set<String> already) {
    final q = _query.trim().toLowerCase();
    return [
      for (final t in all)
        if (!already.contains(t.id) &&
            (q.isEmpty ||
                t.title.toLowerCase().contains(q) ||
                t.artist.toLowerCase().contains(q) ||
                t.album.toLowerCase().contains(q) ||
                t.genre.toLowerCase().contains(q)))
          t,
    ];
  }

  Map<String, List<Track>> _groups(List<Track> tracks) {
    final map = <String, List<Track>>{};
    for (final t in tracks) {
      final key = switch (_tab) {
        LibraryTab.artists => t.artist,
        LibraryTab.albums => t.album,
        _ => t.genre.trim(),
      };
      map.putIfAbsent(key, () => []).add(t);
    }
    return sortGroups(map, LibrarySort.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final all = context.select((LibraryCubit c) => c.state).tracks;
    final already = context.select<PlaylistsCubit, Set<String>>(
      (c) =>
          c.state
              .where((e) => e.id == widget.playlistId)
              .firstOrNull
              ?.trackIds ??
          const {},
    );
    final tracks = _candidates(all, already);
    final allPicked =
        tracks.isNotEmpty && tracks.every((t) => _picked.contains(t.id));
    final groups = _tab == LibraryTab.songs
        ? const <String, List<Track>>{}
        : _groups(tracks);

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.playlistAddTracksTitle,
                leading: const AppBackButton(),
              ),
              // 보관함과 같은 탭.
              Padding(
                padding: AppSpacing.screen,
                child: SegmentedPills<LibraryTab>(
                  expand: true,
                  values: LibraryTab.values,
                  selected: _tab,
                  labelOf: (t) => switch (t) {
                    LibraryTab.songs => l10n.librarySongs,
                    LibraryTab.artists => l10n.libraryArtists,
                    LibraryTab.albums => l10n.libraryAlbums,
                    LibraryTab.genres => l10n.libraryGenres,
                  },
                  onChanged: (t) => setState(() => _tab = t),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: AppSpacing.screen,
                child: AppSearchField(
                  hint: l10n.librarySearchHint,
                  clearTooltip: l10n.actionClear,
                  onChanged: (q) => setState(() => _query = q),
                ),
              ),
              if (tracks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.xs,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PlainButton(
                      label: allPicked
                          ? l10n.newVideosSelectNone
                          : l10n.newVideosSelectAll,
                      accent: true,
                      onPressed: () => setState(() {
                        if (allPicked) {
                          _picked.removeAll(tracks.map((t) => t.id));
                        } else {
                          _picked.addAll(tracks.map((t) => t.id));
                        }
                      }),
                    ),
                  ),
                ),
              Expanded(
                child: tracks.isEmpty
                    ? EmptyState(
                        icon: AppIcons.library,
                        title: l10n.playlistAddTracksEmptyTitle,
                        body: l10n.playlistAddTracksEmptyBody,
                      )
                    : _tab == LibraryTab.songs
                    ? ListView.builder(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        itemCount: tracks.length,
                        // 줄마다 커버 상태를 구독하므로 Builder로 줄 안에서만 다시 그린다.
                        itemBuilder: (context, i) => Builder(
                          builder: (context) {
                            final t = tracks[i];
                            final on = _picked.contains(t.id);
                            return TrackTile(
                              title: t.title,
                              subtitle: t.artist,
                              tone: toneFor(t.id),
                              artwork: coverImageOf(
                                context,
                                CoverKey.track(t.id),
                              ),
                              trailing: Icon(
                                on ? AppIcons.checkCircle : AppIcons.radioOff,
                                color: on ? p.accent : p.onSurfaceMuted,
                              ),
                              onTap: () => _toggle(t.id),
                            );
                          },
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        children: [
                          for (final e in groups.entries)
                            _GroupRow(
                              tab: _tab,
                              name: e.key,
                              tracks: e.value,
                              picked: _picked,
                              onTap: () => _toggleGroup(e.value),
                            ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    label: l10n.playlistAddTracksStart(_picked.length),
                    icon: AppIcons.add,
                    onPressed: _picked.isEmpty ? null : _add,
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

/// 아티스트 · 앨범 · 장르 한 줄: 이름 · 곡 수, 오른쪽에 고른 상태(모두 / 일부 "고른 수/전체" / 없음).
/// 누르면 그 묶음의 곡을 모두 고르거나 푼다.
class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.tab,
    required this.name,
    required this.tracks,
    required this.picked,
    required this.onTap,
  });

  final LibraryTab tab;
  final String name;
  final List<Track> tracks;
  final Set<String> picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final first = tracks.first;
    final label = switch (tab) {
      LibraryTab.artists => artistOf(l10n, first),
      LibraryTab.albums => albumOf(l10n, first),
      _ => genreOf(l10n, name),
    };
    final chosen = tracks.where((t) => picked.contains(t.id)).length;
    final all = chosen == tracks.length;
    final key = switch (tab) {
      LibraryTab.artists => CoverKey.artist(first.artist),
      LibraryTab.albums => CoverKey.album(first.album),
      _ => CoverKey.genre(name),
    };
    return Builder(
      builder: (context) => TrackTile(
        title: label,
        subtitle: l10n.songCount(tracks.length),
        tone: toneFor(name),
        leading: ArtworkBox(
          image: tab == LibraryTab.genres ? null : coverImageOf(context, key),
          tone: toneFor(name),
          color: coverColorOf(context, key),
          radius: tab == LibraryTab.artists ? 24 : 12,
          icon: switch (tab) {
            LibraryTab.artists => AppIcons.person,
            LibraryTab.albums => AppIcons.album,
            _ => AppIcons.category,
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 일부만 골랐으면 "고른 수 / 전체"를 보여 준다.
            if (chosen > 0 && !all)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Text(
                  '$chosen/${tracks.length}',
                  style: text.labelMedium?.copyWith(color: p.accent),
                ),
              ),
            Icon(
              all ? AppIcons.checkCircle : AppIcons.radioOff,
              color: chosen > 0 ? p.accent : p.onSurfaceMuted,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
