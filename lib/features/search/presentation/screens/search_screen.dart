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
import '../../domain/entities/search_source.dart';
import '../bloc/search_cubit.dart';
import 'media_detail_screen.dart';
import '../widgets/search_source_menu.dart';
import '../widgets/video_category.dart';

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
        if (state.categories.isNotEmpty) const _CategoryFilter(),
        for (final hit in state.visibleItems) _HitTile(hit: hit),
        if (state.hasNext)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Center(
              child: state.loadingMore
                  ? const CircularProgressIndicator()
                  : PillButton(
                      label: l10n.searchLoadMore,
                      variant: PillVariant.tonal,
                      onPressed: context.read<SearchCubit>().loadMore,
                    ),
            ),
          ),
      ],
    );
  }
}

/// 결과 위의 분류 필터: 전체 + 지금까지 알아낸 유튜브 분류.
/// 분류는 곡마다 뒤에서 읽기 때문에 시간이 지나며 늘어난다.
class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SearchCubit>();
    final state = context.watch<SearchCubit>().state;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        child: SegmentedPills<String?>(
          values: [null, ...state.categories],
          selected: state.category,
          labelOf: (c) =>
              c == null ? l10n.searchFilterAll : categoryLabel(l10n, c),
          onChanged: cubit.selectCategory,
        ),
      ),
    );
  }
}

enum _HitAction { detail, download }

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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleIconButton(
            icon: AppIcons.download,
            tooltip: l10n.actionDownload,
            onPressed: () => _download(context),
          ),
          Builder(
            builder: (context) => IconButton(
              tooltip: l10n.searchHitMenuTitle,
              onPressed: () => _menu(context),
              icon: Icon(AppIcons.more, color: context.palette.onSurfaceMuted),
            ),
          ),
        ],
      ),
      onTap: () => _download(context),
      onMenu: (position) => _menu(context, position),
    );
  }

  void _download(BuildContext context) =>
      showDownloadDialog(context, title: hit.title, artist: hit.uploader);

  /// 곡 옵션 메뉴: ⋮ · 길게 누르기 · 데스크톱 오른쪽 클릭.
  Future<void> _menu(BuildContext context, [Offset? position]) async {
    final l10n = context.l10n;
    final action = await showAppMenu<_HitAction>(
      context,
      globalPosition: position,
      items: [
        AppMenuItem(
          value: _HitAction.detail,
          icon: AppIcons.info,
          label: l10n.searchHitMenuDetail,
        ),
        AppMenuItem(
          value: _HitAction.download,
          icon: AppIcons.download,
          label: l10n.actionDownload,
        ),
      ],
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _HitAction.detail:
        await showMediaDetail(context, hit);
      case _HitAction.download:
        _download(context);
    }
  }
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
