import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/widgets/cover_sheet.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/entities/library_sort.dart';
import '../../domain/entities/track.dart';
import '../bloc/library_cubit.dart';
import '../bloc/library_import_cubit.dart';

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
  LibrarySort _sort = LibrarySort.added;
  String _query = '';

  /// 장르 탭에서 골라 들어간 장르 (null이면 장르 목록). 빈 문자열은 "알 수 없는 장르".
  String? _genre;

  List<Track> _filtered(List<Track> all, AppLocalizations l10n) {
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
    return sortTracks(list, _sort);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final all = context.select((LibraryCubit c) => c.state.tracks);
    final importing = context.select((LibraryImportCubit c) => c.state.running);
    final tracks = _filtered(all, l10n);
    final vm = context.read<NowPlayingCubit>();

    final items = switch (_tab) {
      LibraryTab.songs => [
        for (var i = 0; i < tracks.length; i++)
          _songTile(context, tracks[i], i, tracks),
      ],
      LibraryTab.artists => [
        for (final e in _groupBy(tracks, (t) => artistOf(l10n, t)).entries)
          TrackTile(
            title: e.key,
            subtitle: l10n.songCount(e.value.length),
            tone: toneFor(e.key),
            leading: ArtworkBox(
              tone: toneFor(e.key),
              radius: 24,
              icon: Icons.person_rounded,
            ),
            trailing: const _Chevron(),
            onTap: () => vm.playQueue(e.value),
          ),
      ],
      LibraryTab.albums => [
        for (final e in _groupBy(tracks, (t) => albumOf(l10n, t)).entries)
          TrackTile(
            title: e.key,
            subtitle:
                '${artistOf(l10n, e.value.first)} · ${l10n.songCount(e.value.length)}',
            tone: toneFor(e.key),
            leading: ArtworkBox(
              tone: toneFor(e.key),
              icon: Icons.album_rounded,
            ),
            trailing: const _Chevron(),
            onTap: () => vm.playQueue(e.value),
          ),
      ],
      LibraryTab.genres when _genre != null => [
        _GenreHeader(
          name: genreOf(l10n, _genre!),
          backTooltip: l10n.genreBack,
          onBack: () => setState(() => _genre = null),
        ),
        ..._genreSongs(context, groupByGenre(tracks)[_genre] ?? const []),
      ],
      LibraryTab.genres => [
        for (final e in groupByGenre(tracks).entries)
          TrackTile(
            title: genreOf(l10n, e.key),
            subtitle: l10n.songCount(e.value.length),
            tone: toneFor(e.key),
            leading: ArtworkBox(
              tone: toneFor(e.key),
              icon: Icons.category_rounded,
            ),
            trailing: const _Chevron(),
            onTap: () => setState(() => _genre = e.key),
          ),
      ],
    };

    return BlocListener<LibraryImportCubit, LibraryImportState>(
      listenWhen: (a, b) => a.seq != b.seq,
      listener: _showOutcome,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(
            bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            AppTopBar(
              large: true,
              title: l10n.navLibrary,
              subtitle: l10n.librarySubtitle,
              actions: [
                CircleIconButton(
                  icon: importing
                      ? Icons.hourglass_top_rounded
                      : Icons.drive_folder_upload_rounded,
                  tooltip: l10n.libraryImport,
                  onPressed: importing ? null : _import,
                ),
              ],
            ),
            if (all.isEmpty) ...[
              Padding(
                padding: AppSpacing.screen,
                child: _EmptyLibrary(importing: importing, onImport: _import),
              ),
            ] else ...[
              Padding(
                padding: AppSpacing.screen,
                child: _LibraryHero(
                  count: all.length,
                  downloaded: all
                      .where((t) => t.source == TrackSource.download)
                      .length,
                  onPlayAll: () => vm.playQueue(tracks),
                  onShuffle: () {
                    vm.playQueue(tracks);
                    if (!vm.state.shuffle) vm.toggleShuffle();
                  },
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
                  onChanged: (t) => setState(() {
                    _tab = t;
                    _genre = null;
                  }),
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
                    values: LibrarySort.values,
                    selected: _sort,
                    tooltip: l10n.sortLabel,
                    icon: Icons.sort_rounded,
                    labelOf: (s) => switch (s) {
                      LibrarySort.name => l10n.sortName,
                      LibrarySort.added => l10n.sortAdded,
                      LibrarySort.artist => l10n.sortArtist,
                    },
                    onChanged: (s) => setState(() => _sort = s),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Text(
                      l10n.libraryNoMatch,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                ...items,
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _genreSongs(BuildContext context, List<Track> songs) => [
    for (var i = 0; i < songs.length; i++)
      _songTile(context, songs[i], i, songs),
  ];

  Widget _songTile(BuildContext context, Track t, int i, List<Track> queue) {
    final l10n = context.l10n;
    final vm = context.read<NowPlayingCubit>();
    final current = context.select((NowPlayingCubit c) => c.state.track);
    return TrackTile(
      title: t.title,
      subtitle: '${artistOf(l10n, t)} · ${albumOf(l10n, t)}',
      tone: toneFor(t.id),
      active: t == current,
      artwork: coverImageOf(context, CoverKey.track(t.id)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatDuration(t.duration),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          IconButton(
            tooltip: l10n.coverChange,
            onPressed: () => showCoverSheet(
              context,
              coverKey: CoverKey.track(t.id),
              title: t.title,
              tone: toneFor(t.id),
            ),
            icon: Icon(
              Icons.more_vert_rounded,
              color: context.palette.onSurfaceMuted,
            ),
          ),
        ],
      ),
      onTap: () => vm.playQueue(queue, index: i),
    );
  }

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

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatNumber('$count', size: 56),
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
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              PillButton(
                label: l10n.actionPlayAll,
                icon: Icons.play_arrow_rounded,
                compact: true,
                onPressed: onPlayAll,
              ),
              PillButton(
                label: l10n.actionShuffle,
                icon: Icons.shuffle_rounded,
                compact: true,
                variant: PillVariant.tonal,
                onPressed: onShuffle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.chevron_right_rounded, color: context.palette.onSurfaceMuted);
}

/// 모르는 아티스트 · 앨범은 안내 문구로.
String artistOf(AppLocalizations l10n, Track t) =>
    t.artist.isEmpty ? l10n.unknownArtist : t.artist;

String albumOf(AppLocalizations l10n, Track t) =>
    t.album.isEmpty ? l10n.unknownAlbum : t.album;

String genreOf(AppLocalizations l10n, String genre) =>
    genre.isEmpty ? l10n.unknownGenre : genre;

/// 장르 안으로 들어갔을 때 맨 위: 뒤로 가기 + 장르 이름.
class _GenreHeader extends StatelessWidget {
  const _GenreHeader({
    required this.name,
    required this.backTooltip,
    required this.onBack,
  });

  final String name;
  final String backTooltip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screen,
      child: Row(
        children: [
          IconButton(
            tooltip: backTooltip,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 보관함이 비었을 때: 기기 음악 불러오기 안내.
class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.importing, required this.onImport});

  final bool importing;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return GlassCard(
      tone: GlowTone.secondary,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.library_music_rounded, size: 40),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.libraryEmptyTitle, style: text.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.libraryEmptyBody,
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          PillButton(
            label: importing ? l10n.importing : l10n.libraryImport,
            icon: Icons.drive_folder_upload_rounded,
            onPressed: importing ? null : onImport,
          ),
        ],
      ),
    );
  }
}
