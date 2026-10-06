import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../downloads/presentation/bloc/download_queue_cubit.dart';
import '../../../downloads/presentation/widgets/download_dialog.dart';
import '../../../downloads/presentation/widgets/download_progress_card.dart';
import '../../../library/domain/entities/track.dart' show formatDuration;
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_sort.dart';
import '../../domain/entities/search_source.dart';
import '../bloc/search_cubit.dart';
import '../widgets/search_source_menu.dart';

/// 검색 · URL 입력 (상세 기능: URL로 곡 정보 불러오기 #1, 키워드 검색 #2,
/// 재생목록 URL 불러오기 #3, 공유 메뉴로 받기 #4, 음질 선택 #6, 중복 다운로드 방지 #9).
/// 입력하고 확인을 누르면 찾는다. 곡을 누르면 받기 팝업이 열린다.
/// 지금은 대기열에만 넣고 실제 받기는 다음 작업에서 이어진다.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  late final SearchCubit _cubit = sl<SearchCubit>();
  SearchSource _source = SearchSource.youtube;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().isNotEmpty) _submit();
  }

  @override
  void dispose() {
    _controller.dispose();
    _cubit.close();
    super.dispose();
  }

  void _submit() => _cubit.submit(_controller.text, _source);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider.value(
      value: _cubit,
      child: SafeArea(
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
                onChanged: (q) {
                  if (q.trim().isEmpty) _submit();
                },
                onSubmitted: (_) => _submit(),
                suffix: SearchSourceMenu(
                  source: _source,
                  onChanged: (s) {
                    setState(() => _source = s);
                    if (_controller.text.trim().isNotEmpty) _submit();
                  },
                ),
              ),
            ),
            const _DownloadCard(),
            const SizedBox(height: AppSpacing.md),
            _Body(onRetry: _submit),
          ],
        ),
      ),
    );
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
    return Padding(
      padding: AppSpacing.screen.copyWith(top: AppSpacing.sm),
      child: DownloadProgressCard(
        current: current,
        waiting: queue.waiting,
        // 받은 곡을 보관함 곡과 이어 재생하는 건 실제 받기를 붙인 뒤에 한다.
        onPlay: (_) {},
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SearchCubit>().state;

    switch (state.status) {
      case SearchStatus.idle:
        return _Hint(
          icon: AppIcons.explore,
          title: l10n.searchEmptyTitle,
          body: l10n.searchEmptyBody,
        );
      case SearchStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        );
      case SearchStatus.failed:
        final failure = state.failure;
        if (failure == EngineFailure.unavailable) {
          return _Hint(
            icon: AppIcons.hourglassEmpty,
            title: l10n.searchNotReadyTitle,
            body: l10n.searchNotReadyBody,
          );
        }
        return _Hint(
          icon: AppIcons.hourglassEmpty,
          title: l10n.searchErrorTitle,
          body: switch (failure) {
            EngineFailure.network => l10n.searchNetworkBody,
            EngineFailure.unauthorized => l10n.searchAuthBody,
            EngineFailure.notFound => l10n.searchNotFoundBody,
            _ => l10n.searchErrorBody,
          },
          action: PillButton(
            label: l10n.actionRetry,
            icon: AppIcons.refresh,
            onPressed: onRetry,
          ),
        );
      case SearchStatus.loaded:
        if (state.items.isEmpty) {
          return _Hint(
            icon: AppIcons.search,
            title: l10n.searchNoResultsTitle,
            body: l10n.searchNoResultsBody,
          );
        }
        return _Results(state: state);
    }
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final isPlaylist = state.playlistTitle != null;
    final label = isPlaylist
        ? '${l10n.searchPlaylistLabel} · ${state.playlistTitle}'
        : state.items.length == 1 && state.hasNext == false
        ? l10n.searchUrlCardLabel
        : l10n.searchResultsTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.screen.copyWith(bottom: AppSpacing.xs),
          child: Text(label, style: text.titleMedium),
        ),
        if (state.items.length > 1)
          Padding(
            padding: AppSpacing.screen.copyWith(bottom: AppSpacing.xs),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: _SortMenu(),
            ),
          ),
        for (final hit in state.visibleItems) _HitTile(hit: hit),
        if (state.hasNext)
          // 끝까지 내려와 이 줄이 화면에 들어오면 다음 결과를 불러온다.
          // 곡이 늘 때마다 새로 만들어서(key) 다음 쪽도 같은 방식으로 이어진다.
          _LoadMoreTrigger(key: ValueKey(state.items.length)),
      ],
    );
  }
}

/// 정렬 메뉴 (받아 온 결과 안에서 순서만 바꾼다).
class _SortMenu extends StatelessWidget {
  const _SortMenu();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SearchCubit>();
    final state = context.watch<SearchCubit>().state;
    return AppDropdown<SearchSort>(
      // 최신순은 검색을 날짜 순으로 다시 하는 것이라 키워드 검색일 때만 있다.
      values: [
        for (final s in SearchSort.values)
          if (s != SearchSort.newest || state.keyword) s,
      ],
      selected: state.sort,
      labelOf: (s) => switch (s) {
        SearchSort.relevance => l10n.searchSortRelevance,
        SearchSort.newest => l10n.searchSortNewest,
        SearchSort.shortest => l10n.searchSortShortest,
        SearchSort.longest => l10n.searchSortLongest,
        SearchSort.title => l10n.searchSortTitle,
      },
      tooltip: l10n.searchSortTooltip,
      onChanged: cubit.selectSort,
    );
  }
}

/// 결과 맨 아래: 화면에 들어오면 다음 쪽을 불러온다 (무한 스크롤).
/// 불러오기가 끝났는데도 더 있으면(실패한 경우) 다시 누를 수 있는 버튼을 보여 준다.
class _LoadMoreTrigger extends StatefulWidget {
  const _LoadMoreTrigger({super.key});

  @override
  State<_LoadMoreTrigger> createState() => _LoadMoreTriggerState();
}

class _LoadMoreTriggerState extends State<_LoadMoreTrigger> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    await context.read<SearchCubit>().loadMore();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final loadingMore = context.watch<SearchCubit>().state.loadingMore;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: _loading || loadingMore
            ? const CircularProgressIndicator()
            : PillButton(
                label: context.l10n.searchLoadMore,
                variant: PillVariant.tonal,
                onPressed: _load,
              ),
      ),
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit});

  final MediaHit hit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subtitle = [
      if (hit.uploader.isNotEmpty) hit.uploader,
      if (hit.duration != null) formatDuration(hit.duration!),
      if (hit.downloaded) l10n.alreadyDownloaded,
    ].join(' · ');
    final thumb = hit.thumbnailUrl;

    return TrackTile(
      title: hit.title,
      subtitle: subtitle,
      tone: toneFor(hit.id),
      artwork: thumb == null ? null : NetworkImage(thumb),
      trailing: CircleIconButton(
        icon: AppIcons.download,
        tooltip: l10n.actionDownload,
        onPressed: () => _download(context),
      ),
      onTap: () => _download(context),
    );
  }

  void _download(BuildContext context) =>
      showDownloadDialog(context, title: hit.title, artist: hit.uploader);
}

class _Hint extends StatelessWidget {
  const _Hint({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
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
                child: Icon(icon, size: 30, color: context.palette.accent),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              style: text.bodyMedium?.copyWith(
                color: context.palette.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
