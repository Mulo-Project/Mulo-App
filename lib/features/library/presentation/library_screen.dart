import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../../covers/presentation/cover_controller.dart';
import '../../covers/presentation/cover_sheet.dart';
import '../../player/presentation/now_playing_view_model.dart';
import '../di.dart';
import '../domain/track.dart';
import 'library_import_view_model.dart';

enum LibraryTab { songs, artists, albums }

enum LibrarySort { name, added, artist }

/// 보관함 (상세 기능: 곡 목록 보기 #10, 정렬·검색 #12, 기기 음악 불러오기 #11).
/// 곡은 보관함 DB(drift)에서 읽는다.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  LibraryTab _tab = LibraryTab.songs;
  LibrarySort _sort = LibrarySort.added;
  String _query = '';

  List<Track> _filtered(List<Track> all, AppLocalizations l10n) {
    final q = _query.trim().toLowerCase();
    final list = all
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
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
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
    final all = ref.watch(libraryTracksProvider).value ?? const <Track>[];
    final importing = ref.watch(libraryImportProvider.select((s) => s.running));
    final tracks = _filtered(all, l10n);
    final vm = ref.read(nowPlayingProvider.notifier);
    final current = ref.watch(nowPlayingProvider.select((s) => s.track));

    final items = switch (_tab) {
      LibraryTab.songs => [
        for (var i = 0; i < tracks.length; i++)
          TrackTile(
            title: tracks[i].title,
            subtitle:
                '${artistOf(l10n, tracks[i])} · ${albumOf(l10n, tracks[i])}',
            tone: toneFor(tracks[i].id),
            active: tracks[i] == current,
            artwork: coverImageOf(ref, CoverKey.track(tracks[i].id)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatDuration(tracks[i].duration),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                IconButton(
                  tooltip: l10n.coverChange,
                  onPressed: () => showCoverSheet(
                    context,
                    coverKey: CoverKey.track(tracks[i].id),
                    title: tracks[i].title,
                    tone: toneFor(tracks[i].id),
                  ),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: context.palette.onSurfaceMuted,
                  ),
                ),
              ],
            ),
            onTap: () => vm.playQueue(tracks, index: i),
          ),
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
    };

    return SafeArea(
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
        ],
      ),
    );
  }

  Future<void> _import() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await ref
        .read(libraryImportProvider.notifier)
        .importDeviceMusic();
    final message = switch (outcome) {
      null => null,
      ImportAdded(:final count) when count > 0 => l10n.importAdded(count),
      ImportAdded() => l10n.importNothingNew,
      ImportDenied() => l10n.importDenied,
      ImportFailed() => l10n.importFailed,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
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
