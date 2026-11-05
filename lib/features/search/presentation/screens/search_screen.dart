import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../downloads/domain/entities/download_item.dart';
import '../../../downloads/domain/entities/download_source.dart';
import '../../../downloads/presentation/bloc/download_queue_cubit.dart';
import '../../../downloads/presentation/widgets/download_dialog.dart';
import '../../../engine/presentation/bloc/engine_cubit.dart';
import '../../../library/domain/entities/track.dart' show formatDuration;
import '../../domain/entities/engine_exception.dart';
import '../../domain/entities/media_info.dart';
import '../../domain/entities/search_sort.dart';
import '../../domain/entities/search_source.dart';
import '../bloc/preview_cubit.dart';
import '../bloc/search_cubit.dart';
import 'media_detail_screen.dart';
import '../widgets/preview_control.dart';
import '../widgets/search_source_menu.dart';

/// 검색 · URL 입력 (상세 기능: URL로 곡 정보 불러오기 #1, 키워드 검색 #2,
/// 재생목록 URL 불러오기 #3, 공유 메뉴로 받기 #4, 중복 다운로드 방지 #9).
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
  late final EngineCubit _engine = sl<EngineCubit>()..load();
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
    _engine.close();
    super.dispose();
  }

  /// 이 기기에 쓸 수 있는 엔진(yt-dlp)이 없고 서버도 없어서, 설치하기 전에는 찾을 수 없다.
  static bool _needsEngine(EngineState s) {
    final status = s.status;
    return status != null &&
        status.supported &&
        !status.installed &&
        !AppConfig.hasApiBaseUrl;
  }

  void _submit() {
    if (_needsEngine(_engine.state)) return;
    _cubit.submit(_controller.text, _source);
  }

  /// 클립보드의 링크를 입력칸에 넣고 바로 곡 정보를 불러온다.
  Future<void> _pasteLink() async {
    final messenger = ScaffoldMessenger.of(context);
    final empty = context.l10n.searchPasteEmpty;
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (!mounted) return;
    if (text == null || !SearchCubit.isUrl(text)) {
      messenger.showSnackBar(SnackBar(content: Text(empty)));
      return;
    }
    _controller.text = text;
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider.value(
      value: _cubit,
      child: SafeArea(
        bottom: false,
        // 안내(처음 · 오류 · 결과 없음)는 검색창 아래 남은 자리 가운데에, 결과는 위에서부터 이어 붙인다.
        child: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                AppTopBar(
                  large: true,
                  title: l10n.navSearch,
                  subtitle: l10n.searchSubtitle,
                ),
                Padding(
                  padding: AppSpacing.screen,
                  child: AppSearchField(
                    controller: _controller,
                    hint: _source == SearchSource.youtube
                        ? l10n.searchHint
                        : l10n.searchHintSite(sourceLabel(context, _source)),
                    clearTooltip: l10n.actionClear,
                    onChanged: (q) {
                      // 찾는 중에 글자를 고치거나 지우면 기다리지 않고 이전 결과로 돌아간다.
                      if (_cubit.state.status == SearchStatus.loading) {
                        _cubit.cancelLoading();
                      } else if (q.trim().isEmpty) {
                        _submit();
                      }
                    },
                    onSubmitted: (_) => _submit(),
                    leading: SearchSourceMenu(
                      source: _source,
                      onChanged: (s) {
                        setState(() => _source = s);
                        if (_controller.text.trim().isNotEmpty) _submit();
                      },
                    ),
                    suffix: RowIconButton(
                      icon: AppIcons.search,
                      tooltip: l10n.searchSubmitTooltip,
                      accent: true,
                      onPressed: _submit,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ]),
            ),
            BlocBuilder<EngineCubit, EngineState>(
              bloc: _engine,
              builder: (context, engine) {
                // 엔진이 없으면 찾기 전에 바로 설치하라고 안내한다.
                if (_needsEngine(engine)) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EngineNeeded(cubit: _engine, state: engine),
                  );
                }
                return BlocBuilder<SearchCubit, SearchState>(
                  bloc: _cubit,
                  buildWhen: (a, b) =>
                      (a.status == SearchStatus.loaded && a.items.isNotEmpty) !=
                      (b.status == SearchStatus.loaded && b.items.isNotEmpty),
                  builder: (context, state) {
                    final body = Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            AppSpacing.lg +
                            MediaQuery.paddingOf(context).bottom,
                      ),
                      child: _Body(onRetry: _submit, onPaste: _pasteLink),
                    );
                    // 결과는 위에서부터 길게 이어 붙이고, 안내는 남은 자리 가운데에 둔다.
                    final isList =
                        state.status == SearchStatus.loaded &&
                        state.items.isNotEmpty;
                    return isList
                        ? SliverToBoxAdapter(child: body)
                        : SliverFillRemaining(
                            hasScrollBody: false,
                            child: body,
                          );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.onRetry, required this.onPaste});

  final VoidCallback onRetry;
  final VoidCallback onPaste;

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
          action: PillButton(
            label: l10n.searchPasteLink,
            icon: AppIcons.paste,
            variant: PillVariant.tonal,
            onPressed: onPaste,
          ),
        );
      case SearchStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: LoadingState(),
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
        if (failure == EngineFailure.network) {
          return EmptyState.network(onRetry: onRetry);
        }
        if (failure == EngineFailure.timeout) {
          return EmptyState.timeout(onRetry: onRetry);
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
    final isPlaylist = state.playlistTitle != null;
    final label = isPlaylist
        ? '${l10n.searchPlaylistLabel} · ${state.playlistTitle}'
        : state.items.length == 1 && state.hasNext == false
        ? l10n.searchUrlCardLabel
        : l10n.searchResultsTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(label),
        if (isPlaylist)
          Padding(
            padding: AppSpacing.screen.copyWith(bottom: AppSpacing.xs),
            child: Align(
              alignment: Alignment.centerLeft,
              child: PillButton(
                label: l10n.searchPlaylistPick,
                icon: AppIcons.download,
                variant: PillVariant.tonal,
                compact: true,
                onPressed: () => context.push(
                  Routes.playlistImport,
                  extra: context.read<SearchCubit>().query,
                ),
              ),
            ),
          ),
        if (state.keyword)
          Padding(
            padding: AppSpacing.screen.copyWith(bottom: AppSpacing.xs),
            child: Align(
              alignment: Alignment.centerLeft,
              child: PillButton(
                label: l10n.searchPlaylistFind,
                icon: AppIcons.search,
                variant: PillVariant.tonal,
                compact: true,
                onPressed: () => context.push(
                  Routes.playlistImport,
                  extra: context.read<SearchCubit>().query,
                ),
              ),
            ),
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
          if (s != SearchSort.newest ||
              (state.keyword && cubit.source.supportsNewest))
            s,
      ],
      selected: state.sort,
      labelOf: (s) => switch (s) {
        SearchSort.relevance => l10n.searchSortRelevance,
        SearchSort.popular => l10n.searchSortPopular,
        SearchSort.newest => l10n.searchSortNewest,
        SearchSort.duration => l10n.searchSortDuration,
        SearchSort.title => l10n.searchSortTitle,
      },
      tooltip: l10n.searchSortTooltip,
      onChanged: cubit.selectSort,
      // 관련도 · 최신순은 찾는 쪽이 정한 순서라 방향을 바꾸지 않는다.
      ascending: state.sort.hasDirection ? state.isAscending : null,
      directionTooltip: state.isAscending
          ? l10n.sortAscending
          : l10n.sortDescending,
      onToggleDirection: state.sort.hasDirection ? cubit.toggleDirection : null,
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
            ? const LoadingIndicator()
            : PillButton(
                label: context.l10n.searchLoadMore,
                variant: PillVariant.tonal,
                onPressed: _load,
              ),
      ),
    );
  }
}

enum _HitAction { detail, preview, download }

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit});

  final MediaHit hit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subtitle = [
      if (hit.uploader.isNotEmpty) hit.uploader,
      // 채널 이름 옆에 전체 길이도 보인다.
      if (hit.duration != null) formatDuration(hit.duration!),
      if (hit.downloaded) l10n.alreadyDownloaded,
    ].join(' · ');
    final thumb = hit.thumbnailUrl;
    // 받기 버튼 아이콘은 이 곡의 받기 상태를 따른다 (받는 중 · 대기 · 받음).
    final key = downloadSourceKey(hit.url);
    final status = context.select<DownloadQueueCubit, DownloadStatus?>((c) {
      DownloadStatus? found;
      for (final e in c.state.items) {
        if (downloadSourceKey(e.url) != key) continue;
        if (e.status == DownloadStatus.downloading) return e.status;
        if (e.isActive) found = e.status;
      }
      return found;
    });
    final (icon, tooltip) = switch (status) {
      DownloadStatus.downloading => (
        AppIcons.hourglassTop,
        l10n.downloadStateDownloading,
      ),
      DownloadStatus.queued || DownloadStatus.paused => (
        AppIcons.hourglassEmpty,
        l10n.downloadStateQueued,
      ),
      _
          when hit.downloaded ||
              context.select<DownloadQueueCubit, bool>(
                (c) => c.isDownloaded(hit.url),
              ) =>
        (AppIcons.checkCircle, l10n.downloadStateDone),
      _ => (AppIcons.download, l10n.actionDownload),
    };

    return TrackTile(
      title: hit.title,
      subtitle: subtitle,
      tone: toneFor(hit.id),
      artwork: thumb == null ? null : NetworkImage(thumb),
      // 줄마다 유리(흐림 층)를 두면 목록 스크롤이 끊겨서 면 없는 작은 버튼을 쓴다.
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PreviewRowButton(hit: hit),
          RowIconButton(
            icon: icon,
            tooltip: tooltip,
            onPressed: () => _download(context),
          ),
        ],
      ),
      footer: PreviewProgressBar(hitId: hit.id),
      onTap: () => showMediaDetail(context, hit),
      onMenu: (position) => _menu(context, position),
    );
  }

  void _download(BuildContext context) => showDownloadDialog(
    context,
    title: hit.title,
    artist: hit.uploader,
    duration: hit.duration,
    thumbnailUrl: hit.thumbnailUrl,
    url: hit.url,
  );

  /// 곡 옵션 메뉴: 길게 누르기 · 데스크톱 오른쪽 클릭.
  Future<void> _menu(BuildContext context, Offset position) async {
    final l10n = context.l10n;
    final previewing = context.read<PreviewCubit>().state.isActive(hit.id);
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
          value: _HitAction.preview,
          icon: previewing ? AppIcons.pause : AppIcons.headphones,
          label: previewing ? l10n.searchPreviewStop : l10n.searchPreview,
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
      case _HitAction.preview:
        await togglePreview(context, hit);
      case _HitAction.download:
        _download(context);
    }
  }
}

/// 다운로드 엔진(yt-dlp)이 없을 때 검색 자리에 보이는 안내: 바로 설치할 수 있다.
class _EngineNeeded extends StatelessWidget {
  const _EngineNeeded({required this.cubit, required this.state});

  final EngineCubit cubit;
  final EngineState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      icon: AppIcons.download,
      title: l10n.searchEngineNeededTitle,
      body: state.failed
          ? l10n.searchEngineInstallFailed
          : l10n.searchEngineNeededBody,
      action: PillButton(
        label: state.busy
            ? l10n.settingsEngineInstalling
            : l10n.settingsEngineInstall,
        icon: AppIcons.download,
        onPressed: state.busy ? null : cubit.install,
      ),
    );
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
    return EmptyState(icon: icon, title: title, body: body, action: action);
  }
}
