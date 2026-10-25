import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/entities/library_sort.dart';
import '../../domain/entities/track.dart';
import '../bloc/library_cubit.dart';
import '../bloc/library_import_cubit.dart';
import '../widgets/track_list_tile.dart';

enum LibraryTab { songs, artists, albums, genres }

/// 보관함 (상세 기능: 곡 목록 보기 #10, 정렬·검색 #12, 기기 음악 불러오기 #11).
/// 곡은 보관함 DB(drift)에서 읽는다.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryTab _tab = LibraryTab.songs;

  /// 탭마다 고른 정렬. 탭에 맞는 기준만 고를 수 있다 ([_sortOptions]).
  final _sorts = <LibraryTab, LibrarySort>{};

  /// 탭마다 고른 방향(true 오름차순). 비어 있으면 그 기준의 기본 방향 ([defaultAscending]).
  final _ascending = <LibraryTab, bool>{};
  String _query = '';

  static const _songSorts = [
    LibrarySort.name,
    LibrarySort.added,
    LibrarySort.artist,
  ];
  static const _groupSorts = [
    LibrarySort.name,
    LibrarySort.count,
    LibrarySort.added,
  ];

  List<LibrarySort> get _sortOptions =>
      _tab == LibraryTab.songs ? _songSorts : _groupSorts;

  LibrarySort get _sort =>
      _sorts[_tab] ??
      (_tab == LibraryTab.songs ? LibrarySort.added : LibrarySort.name);

  bool get _asc => _ascending[_tab] ?? defaultAscending(_sort);

  // 거르기 · 정렬 결과 기억: 곡 목록 · 검색어 · 탭 · 정렬이 같으면 다시 계산하지 않는다.
  List<Track>? _memoAll;
  (String, LibraryTab, LibrarySort, bool)? _memoKey;
  List<Track> _memoTracks = const [];

  List<Track> _filtered(List<Track> all, AppLocalizations l10n) {
    final key = (_query, _tab, _sort, _asc);
    if (identical(_memoAll, all) && _memoKey == key) return _memoTracks;
    _memoAll = all;
    _memoKey = key;
    return _memoTracks = _filteredNow(all);
  }

  List<Track> _filteredNow(List<Track> all) {
    final q = _query.trim().toLowerCase();
    final list = all
        .where(
          (t) =>
              q.isEmpty ||
              t.title.toLowerCase().contains(q) ||
              t.artist.toLowerCase().contains(q) ||
              t.album.toLowerCase().contains(q) ||
              t.genre.toLowerCase().contains(q),
        )
        .toList();
    return _tab == LibraryTab.songs
        ? sortTracks(list, _sort, ascending: _asc)
        : list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // 곡 목록 대신 상태를 고른다: 목록끼리 비교하면 곡 정보를 고친 것을 못 알아챈다.
    final all = context.select((LibraryCubit c) => c.state).tracks;
    final importing = context.select((LibraryImportCubit c) => c.state.running);
    final tracks = _filtered(all, l10n);
    final vm = context.read<NowPlayingCubit>();

    // 모든 탭은 보이는 줄만 만든다 (곡 · 앨범 · 아티스트가 수천 개여도 탭 전환이 느려지지 않게).
    // 그룹 탭은 줄을 만드는 함수만 모아 두고, 아래 SliverList.builder가 필요할 때 부른다.
    final lazySongs = _tab == LibraryTab.songs;
    final items = switch (_tab) {
      LibraryTab.songs => <Widget Function(BuildContext)>[],
      LibraryTab.artists => [
        for (final e in sortGroups(
          _groupBy(tracks, (t) => artistOf(l10n, t)),
          _sort,
          ascending: _asc,
        ).entries)
          (BuildContext context) => TrackTile(
            key: ValueKey(e.key),
            title: e.key,
            subtitle: l10n.songCount(e.value.length),
            tone: toneFor(e.key),
            leading: ArtworkBox(
              image: coverImageOf(
                context,
                CoverKey.artist(e.value.first.artist),
              ),
              tone: toneFor(e.key),
              color: coverColorOf(
                context,
                CoverKey.artist(e.value.first.artist),
              ),
              radius: 24,
              icon: AppIcons.person,
            ),
            trailing: const _Chevron(),
            onTap: () => context.push(Routes.artist(e.value.first.artist)),
          ),
      ],
      LibraryTab.albums => [
        for (final e in sortGroups(
          _groupBy(tracks, (t) => albumOf(l10n, t)),
          _sort,
          ascending: _asc,
        ).entries)
          (BuildContext context) => TrackTile(
            key: ValueKey(e.key),
            title: e.key,
            subtitle:
                '${artistOf(l10n, e.value.first)} · ${l10n.songCount(e.value.length)}',
            tone: toneFor(e.key),
            leading: ArtworkBox(
              image: coverImageOf(context, CoverKey.album(e.value.first.album)),
              tone: toneFor(e.key),
              color: coverColorOf(context, CoverKey.album(e.value.first.album)),
              icon: AppIcons.album,
            ),
            trailing: const _Chevron(),
            onTap: () => context.push(Routes.album(e.value.first.album)),
          ),
      ],
      LibraryTab.genres => [
        for (final e in sortGroups(
          groupByGenre(tracks),
          _sort,
          ascending: _asc,
        ).entries)
          (BuildContext context) => TrackTile(
            key: ValueKey(e.key),
            title: genreOf(l10n, e.key),
            subtitle: l10n.songCount(e.value.length),
            tone: toneFor(e.key),
            leading: ArtworkBox(
              tone: toneFor(e.key),
              color: coverColorOf(context, CoverKey.genre(e.key)),
              icon: AppIcons.category,
            ),
            trailing: const _Chevron(),
            onTap: () => context.push(Routes.genre(e.key)),
          ),
      ],
    };

    return MultiBlocListener(
      listeners: [
        BlocListener<LibraryImportCubit, LibraryImportState>(
          listenWhen: (a, b) => a.seq != b.seq,
          listener: _showOutcome,
        ),
        // 내장 커버는 DB에 직접 저장되므로 메모리의 커버 목록을 다시 읽는다.
        BlocListener<LibraryImportCubit, LibraryImportState>(
          listenWhen: (a, b) => a.coversSeq != b.coversSeq,
          listener: (context, _) => context.read<CoverCubit>().load(),
        ),
      ],
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                AppTopBar(
                  large: true,
                  title: l10n.navLibrary,
                  subtitle: l10n.librarySubtitle,
                  actions: [
                    CircleIconButton(
                      icon: importing
                          ? AppIcons.hourglassTop
                          : AppIcons.folderUpload,
                      tooltip: l10n.libraryImport,
                      onPressed: importing ? null : _import,
                    ),
                  ],
                ),
                if (all.isNotEmpty) ...[
                  Padding(
                    padding: AppSpacing.screen,
                    child: _LibraryHero(
                      count: all.length,
                      downloaded: all
                          .where((t) => t.source == TrackSource.download)
                          .length,
                      onPlayAll: () => vm.playQueue(tracks),
                      onShuffle: () => vm.playShuffled(tracks),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: AppSpacing.screen,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppDropdown<LibrarySort>(
                        values: _sortOptions,
                        selected: _sort,
                        tooltip: l10n.sortLabel,
                        icon: AppIcons.sort,
                        labelOf: (s) => switch (s) {
                          LibrarySort.name => l10n.sortName,
                          LibrarySort.added => l10n.sortAdded,
                          LibrarySort.artist => l10n.sortArtist,
                          LibrarySort.count => l10n.sortCount,
                        },
                        // 기준을 바꾸면 그 기준의 기본 방향으로 돌아간다.
                        onChanged: (s) => setState(() {
                          _sorts[_tab] = s;
                          _ascending.remove(_tab);
                        }),
                        ascending: _asc,
                        directionTooltip: _asc
                            ? l10n.sortAscending
                            : l10n.sortDescending,
                        onToggleDirection: () =>
                            setState(() => _ascending[_tab] = !_asc),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (items.isEmpty && !(lazySongs && tracks.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text(
                          l10n.libraryNoMatch,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                ],
              ]),
            ),
            // 보관함이 비었으면 안내를 머리 아래 남은 자리 가운데에 둔다.
            if (all.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: AppSpacing.screen,
                  child: _EmptyLibrary(importing: importing, onImport: _import),
                ),
              )
            else if (lazySongs)
              SliverList.builder(
                itemCount: tracks.length,
                itemBuilder: (context, i) =>
                    _songTile(context, tracks[i], i, tracks),
              )
            else if (items.isNotEmpty)
              SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, i) =>
                    Builder(builder: (context) => items[i](context)),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _songTile(BuildContext context, Track t, int i, List<Track> queue) =>
      TrackListTile(key: ValueKey(t.id), track: t, queue: queue, index: i);

  void _import() => context.read<LibraryImportCubit>().importDeviceMusic();

  /// 불러오기가 끝날 때마다(seq 증가) 결과를 한 번 안내한다.
  void _showOutcome(BuildContext context, LibraryImportState state) {
    final l10n = context.l10n;
    final message = switch (state.outcome) {
      null || ImportCancelled() => null,
      ImportAdded(:final count) when count > 0 => l10n.importAdded(count),
      ImportAdded() => l10n.importNothingNew,
      ImportDenied() => l10n.importDenied,
      ImportFailed() => l10n.importFailed,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  static Map<String, List<Track>> _groupBy(
    List<Track> tracks,
    String Function(Track) key,
  ) {
    final map = <String, List<Track>>{};
    for (final t in tracks) {
      map.putIfAbsent(key(t), () => []).add(t);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
}

class _LibraryHero extends StatelessWidget {
  const _LibraryHero({
    required this.count,
    required this.downloaded,
    required this.onPlayAll,
    required this.onShuffle,
  });

  final int count;
  final int downloaded;

  final VoidCallback onPlayAll;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    // 지금 재생 중인 곡 (없으면 null). 있으면 오른쪽에 그 곡의 이미지를 보여 준다.
    // 여기서 지켜보므로 곡이 바뀌어도 이 머리만 다시 그려진다.
    final now = context.select((NowPlayingCubit c) => c.state.track);
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatNumber('$count', size: 44),
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(l10n.unitSongs, style: text.titleMedium),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.librarySources(count - downloaded, downloaded),
          style: text.bodySmall?.copyWith(color: p.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            PillButton(
              label: l10n.actionPlayAll,
              icon: AppIcons.play,
              compact: true,
              onPressed: onPlayAll,
            ),
            PillButton(
              label: l10n.actionShuffle,
              icon: AppIcons.shuffle,
              compact: true,
              variant: PillVariant.tonal,
              onPressed: onShuffle,
            ),
          ],
        ),
      ],
    );

    // 카드 없이 배경 위에 바로 놓고, 아래에 얇은 구분선만 둔다.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        now == null
            ? info
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: info),
                  const SizedBox(width: AppSpacing.md),
                  // 지금 재생 중인 곡의 이미지.
                  ArtworkBox(
                    image: coverImageOf(context, CoverKey.track(now.id)),
                    color: coverColorOf(context, CoverKey.track(now.id)),
                    tone: toneFor(now.id),
                    size: 72,
                    radius: AppRadii.sm,
                  ),
                ],
              ),
        const SizedBox(height: AppSpacing.lg),
        const AppDivider(),
      ],
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) =>
      Icon(AppIcons.chevronRight, color: context.palette.onSurfaceMuted);
}

/// 보관함이 비었을 때: 기기 음악 불러오기 안내.
class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.importing, required this.onImport});

  final bool importing;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      icon: AppIcons.library,
      title: l10n.libraryEmptyTitle,
      body: l10n.libraryEmptyBody,
      action: PillButton(
        label: importing ? l10n.importing : l10n.libraryImport,
        icon: AppIcons.folderUpload,
        onPressed: importing ? null : onImport,
      ),
    );
  }
}
