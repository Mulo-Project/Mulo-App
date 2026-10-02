import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/sample/sample_data.dart';
import '../../../downloads/domain/entities/download_options.dart';
import '../../../downloads/presentation/bloc/download_queue_cubit.dart';
import '../../../downloads/presentation/widgets/download_dialog.dart';
import '../../../downloads/presentation/widgets/download_progress_card.dart';
import '../../../library/domain/entities/track.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/search_source.dart';
import '../widgets/search_source_menu.dart';

/// 입력에 따라 화면이 바뀐다 (자리 표시 데이터).
enum SearchMode { empty, url, playlist, keyword }

SearchMode searchModeOf(String input) {
  final q = input.trim();
  if (q.isEmpty) return SearchMode.empty;
  final isUrl = q.startsWith('http') || q.contains('youtu');
  if (!isUrl) return SearchMode.keyword;
  return q.contains('list=') ? SearchMode.playlist : SearchMode.url;
}

/// 검색 · URL 입력 (상세 기능: URL로 곡 정보 불러오기 #1, 키워드 검색 #2,
/// 재생목록 URL 불러오기 #3, 공유 메뉴로 받기 #4, 음질 선택 #6, 중복 다운로드 방지 #9).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  late String _query = widget.initialQuery;
  Quality _quality = Quality.best;
  SearchSource _source = SearchSource.youtube;
  final Set<String> _selected = {
    for (final t in SampleData.tracks.take(8)) t.id,
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mode = searchModeOf(_query);

    final body = switch (mode) {
      SearchMode.empty => [const _EmptyHint()],
      SearchMode.url => [
        _UrlResultCard(
          track: SampleData.tracks.first,
          quality: _quality,
          onQuality: (q) => setState(() => _quality = q),
          onDownload: () => _download(SampleData.tracks.first, _quality),
        ),
      ],
      SearchMode.playlist => _playlist(context),
      SearchMode.keyword => _keywordResults(context),
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
            title: l10n.navSearch,
            subtitle: l10n.searchSubtitle,
          ),
          Padding(
            padding: AppSpacing.screen,
            child: AppSearchField(
              controller: _controller,
              hint: _source == SearchSource.web
                  ? l10n.searchHintWeb
                  : l10n.searchHint,
              clearTooltip: l10n.actionClear,
              onChanged: (q) => setState(() => _query = q),
              suffix: SearchSourceMenu(
                source: _source,
                onChanged: (s) => setState(() => _source = s),
              ),
            ),
          ),
          const _DownloadCard(),
          const SizedBox(height: AppSpacing.md),
          ...body,
        ],
      ),
    );
  }

  /// 받기 팝업을 열고, 받기를 시작했으면 알린다.
  Future<void> _download(Track track, Quality quality) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final queued = context.l10n.downloadQueued;
    final started = await showDownloadDialog(
      context,
      title: track.title,
      artist: track.artist,
      genre: track.genre,
      quality: quality,
    );
    if (started) {
      messenger?.showSnackBar(SnackBar(content: Text(queued)));
    }
  }

  List<Widget> _keywordResults(BuildContext context) {
    final l10n = context.l10n;
    final results = [
      ...SampleData.tracks,
      ...SampleData.tracks.reversed,
    ].take(20).toList();
    return [
      _SectionLabel('${l10n.searchResultsTitle} · ${results.length}'),
      for (var i = 0; i < results.length; i++)
        TrackTile(
          title: results[i].title,
          subtitle:
              '${results[i].artist} · ${formatDuration(results[i].duration)}',
          tone: toneFor(results[i].id),
          trailing: i == 2
              ? StatusPill(label: l10n.alreadyDownloaded)
              : CircleIconButton(
                  icon: Icons.download_rounded,
                  tooltip: l10n.actionDownload,
                  onPressed: () => _download(results[i], _quality),
                ),
        ),
    ];
  }

  List<Widget> _playlist(BuildContext context) {
    final l10n = context.l10n;
    final tracks = SampleData.tracks;
    final all = _selected.length == tracks.length;
    return [
      Padding(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.searchPlaylistLabel.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              SampleData.playlists.first.$1,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatNumber('${_selected.length}', size: 40),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '/ ${l10n.songCount(tracks.length)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                PillButton(
                  label: l10n.searchDownloadSelected(_selected.length),
                  icon: Icons.download_rounded,
                  compact: true,
                  onPressed: _selected.isEmpty ? null : () {},
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      SettingRow(
        title: l10n.searchSelectAll,
        trailing: AppSwitch(
          value: all,
          onChanged: (v) => setState(() {
            _selected
              ..clear()
              ..addAll(v ? tracks.map((t) => t.id) : const []);
          }),
        ),
      ),
      for (var i = 0; i < tracks.length; i++)
        TrackTile(
          title: tracks[i].title,
          subtitle:
              '${tracks[i].artist} · ${formatDuration(tracks[i].duration)}',
          leading: _CheckBox(checked: _selected.contains(tracks[i].id)),
          onTap: () => setState(() {
            final id = tracks[i].id;
            _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
          }),
        ),
    ];
  }
}

/// 검색창 아래, 받는 중인 곡이 있을 때만 보인다.
class _DownloadCard extends StatelessWidget {
  const _DownloadCard();

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<DownloadQueueCubit>().state;
    final current = queue.current;
    if (current == null) return const SizedBox.shrink();
    final tracks = SampleData.tracks;
    return Padding(
      padding: AppSpacing.screen.copyWith(top: AppSpacing.sm),
      child: DownloadProgressCard(
        current: current,
        waiting: queue.waiting,
        onPlay: (item) {
          final i = tracks.indexWhere((t) => t.id == item.id);
          if (i >= 0) {
            context.read<NowPlayingCubit>().playQueue(tracks, index: i);
          }
        },
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: AppSpacing.screen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            GlassSurface(
              shape: const CircleBorder(),
              child: SizedBox.square(
                dimension: 64,
                child: Icon(
                  Icons.travel_explore_rounded,
                  size: 30,
                  color: context.palette.accent,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.searchEmptyTitle, style: text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.searchEmptyBody,
              style: text.bodyMedium?.copyWith(
                color: context.palette.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UrlResultCard extends StatelessWidget {
  const _UrlResultCard({
    required this.track,
    required this.quality,
    required this.onQuality,
    required this.onDownload,
  });

  final Track track;
  final Quality quality;
  final ValueChanged<Quality> onQuality;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.searchUrlCardLabel.toUpperCase(), style: text.labelSmall),
          const SizedBox(height: AppSpacing.md),
          const ArtworkBox(size: 96, radius: 20, tone: GlowTone.tertiary),
          const SizedBox(height: AppSpacing.md),
          Text(track.title, style: text.headlineSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            track.artist,
            style: text.bodyMedium?.copyWith(
              color: context.palette.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StatNumber(formatDuration(track.duration), size: 32),
          const SizedBox(height: AppSpacing.lg),
          SegmentedPills<Quality>(
            expand: true,
            values: Quality.values,
            selected: quality,
            labelOf: (q) => switch (q) {
              Quality.best => l10n.qualityBest,
              Quality.normal => l10n.qualityNormal,
              Quality.saver => l10n.qualitySaver,
            },
            onChanged: onQuality,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: PillButton(
              label: l10n.actionDownload,
              icon: Icons.download_rounded,
              onPressed: onDownload,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.md,
      AppSpacing.xs,
    ),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: checked ? p.accent : p.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: checked ? p.accent : p.outline),
      ),
      child: Icon(
        checked ? Icons.check_rounded : Icons.music_note_rounded,
        color: checked ? p.onAccent : p.onSurfaceMuted,
        size: 22,
      ),
    );
  }
}
