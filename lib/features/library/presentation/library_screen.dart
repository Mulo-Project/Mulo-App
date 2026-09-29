import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/sample/sample_data.dart';
import '../../player/presentation/now_playing_view_model.dart';
import '../domain/track.dart';

enum LibraryTab { songs, artists, albums }

enum LibrarySort { name, added, artist }

/// 보관함 (상세 기능: 곡 목록 보기 #10, 정렬·검색 #12, 기기 음악 불러오기 #11).
/// 지금은 자리 표시 데이터.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  LibraryTab _tab = LibraryTab.songs;
  LibrarySort _sort = LibrarySort.added;
  String _query = '';

  List<Track> get _tracks {
    final q = _query.trim().toLowerCase();
    final list = SampleData.tracks
        .where(
          (t) =>
              q.isEmpty ||
              t.title.toLowerCase().contains(q) ||
              t.artist.toLowerCase().contains(q) ||
              t.album.toLowerCase().contains(q),
        )
        .toList();
    switch (_sort) {
      case LibrarySort.name:
        list.sort((a, b) => a.title.compareTo(b.title));
      case LibrarySort.added:
        list.sort((a, b) => b.addedOrder.compareTo(a.addedOrder));
      case LibrarySort.artist:
        list.sort(
          (a, b) => (
            a.artist,
            a.title,
          ).toString().compareTo((b.artist, b.title).toString()),
        );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tracks = _tracks;
    final vm = ref.read(nowPlayingProvider.notifier);
    final current = ref.watch(nowPlayingProvider.select((s) => s.track));

    final items = switch (_tab) {
      LibraryTab.songs => [
        for (var i = 0; i < tracks.length; i++)
          TrackTile(
            title: tracks[i].title,
            subtitle: '${tracks[i].artist} · ${tracks[i].album}',
            tone: toneFor(tracks[i].id),
            active: tracks[i] == current,
            trailing: Text(
              formatDuration(tracks[i].duration),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () => vm.playQueue(tracks, index: i),
          ),
      ],
      LibraryTab.artists => [
        for (final e in _groupBy(tracks, (t) => t.artist).entries)
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
        for (final e in _groupBy(tracks, (t) => t.album).entries)
          TrackTile(
            title: e.key,
            subtitle:
                '${e.value.first.artist} · ${l10n.songCount(e.value.length)}',
            tone: toneFor(e.key),
            leading: ArtworkBox(
              tone: toneFor(e.key),
              icon: Icons.album_rounded,
            ),
            trailing: const _Chevron(),
            onTap: () => vm.playQueue(e.value),
          ),
      ],
    };

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        children: [
          AppTopBar(
            large: true,
            title: l10n.navLibrary,
            subtitle: l10n.librarySubtitle,
            actions: [
              CircleIconButton(
                icon: Icons.drive_folder_upload_rounded,
                tooltip: l10n.libraryImport,
                onPressed: () {},
              ),
            ],
          ),
          Padding(
            padding: AppSpacing.screen,
            child: _LibraryHero(
              count: SampleData.tracks.length,
              onPlayAll: () => vm.playQueue(tracks),
              onShuffle: () {
                vm.playQueue(tracks);
                if (!ref.read(nowPlayingProvider).shuffle) vm.toggleShuffle();
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.screen,
            child: SegmentedPills<LibrarySort>(
              values: LibrarySort.values,
              selected: _sort,
              labelOf: (s) => switch (s) {
                LibrarySort.name => l10n.sortName,
                LibrarySort.added => l10n.sortAdded,
                LibrarySort.artist => l10n.sortArtist,
              },
              onChanged: (s) => setState(() => _sort = s),
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
      ),
    );
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
    required this.onPlayAll,
    required this.onShuffle,
  });

  final int count;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DotMatrixText('$count', dotSize: 7, gap: 2.5),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(l10n.unitSongs, style: text.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.libraryStorage(SampleData.librarySize),
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
