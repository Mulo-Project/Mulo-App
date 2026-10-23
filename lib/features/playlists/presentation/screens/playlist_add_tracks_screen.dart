import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/presentation/bloc/library_cubit.dart';
import '../../../library/presentation/widgets/track_list_tile.dart'
    show genreOf;
import '../bloc/playlists_cubit.dart';

/// 재생목록에 곡 추가: 보관함의 곡 가운데 아직 담기지 않은 곡을 여러 개 골라 한꺼번에 담는다.
/// 위 검색창으로 좁히고, 줄을 눌러 고르고, 아래 "N곡 추가"를 누르면 담고 돌아간다.
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

  /// 아티스트 · 앨범 · 장르 필터 ([_all]이면 거르지 않는다). 모르는 값은 빈 문자열.
  static const _all = '';
  String _artist = _all;
  String _album = _all;
  String _genre = _all;

  void _toggle(String id) => setState(() {
    _picked.contains(id) ? _picked.remove(id) : _picked.add(id);
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
            (_artist == _all || t.artist == _artist) &&
            (_album == _all || t.album == _album) &&
            (_genre == _all || t.genre.trim() == _genre) &&
            (q.isEmpty ||
                t.title.toLowerCase().contains(q) ||
                t.artist.toLowerCase().contains(q) ||
                t.album.toLowerCase().contains(q)))
          t,
    ];
  }

  /// 필터 알약 하나: 고를 값이 둘 이상일 때만 보인다 ([_all] 다음에 이름순).
  Widget? _filter({
    required Set<String> options,
    required String selected,
    required String allLabel,
    required String Function(String) labelOf,
    required ValueChanged<String> onChanged,
  }) {
    if (options.length < 2) return null;
    final values = [_all, ...(options.toList()..sort())];
    return AppDropdown<String>(
      values: values,
      selected: values.contains(selected) ? selected : _all,
      labelOf: (v) => v == _all ? allLabel : labelOf(v),
      onChanged: (v) => setState(() => onChanged(v)),
    );
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
    // 필터 선택지는 아직 담기지 않은 곡에서 뽑는다.
    final pool = [
      for (final t in all)
        if (!already.contains(t.id)) t,
    ];
    final filters = <Widget>[
      ?_filter(
        options: {for (final t in pool) t.artist},
        selected: _artist,
        allLabel: l10n.filterAllArtists,
        labelOf: (v) => v.isEmpty ? l10n.unknownArtist : v,
        onChanged: (v) => _artist = v,
      ),
      ?_filter(
        options: {for (final t in pool) t.album},
        selected: _album,
        allLabel: l10n.filterAllAlbums,
        labelOf: (v) => v.isEmpty ? l10n.unknownAlbum : v,
        onChanged: (v) => _album = v,
      ),
      ?_filter(
        options: {for (final t in pool) t.genre.trim()},
        selected: _genre,
        allLabel: l10n.filterAllGenres,
        labelOf: (v) => genreOf(l10n, v),
        onChanged: (v) => _genre = v,
      ),
    ];
    final allPicked =
        tracks.isNotEmpty && tracks.every((t) => _picked.contains(t.id));

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
              Padding(
                padding: AppSpacing.screen,
                child: AppSearchField(
                  hint: l10n.librarySearchHint,
                  clearTooltip: l10n.actionClear,
                  onChanged: (q) => setState(() => _query = q),
                ),
              ),
              // 아티스트 · 앨범 · 장르로 좁히는 필터 (값이 둘 이상일 때만, 옆으로 밀 수 있다).
              if (filters.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < filters.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.sm),
                        filters[i],
                      ],
                    ],
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
                    : ListView.builder(
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
