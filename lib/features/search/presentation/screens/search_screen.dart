import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../downloads/presentation/bloc/download_queue_cubit.dart';
import '../../../downloads/presentation/widgets/download_progress_card.dart';
import '../../domain/entities/search_source.dart';
import '../widgets/search_source_menu.dart';

/// 검색 · URL 입력 (상세 기능: URL로 곡 정보 불러오기 #1, 키워드 검색 #2,
/// 재생목록 URL 불러오기 #3, 공유 메뉴로 받기 #4, 음질 선택 #6, 중복 다운로드 방지 #9).
/// 다운로드 엔진(yt-dlp)이 연결되기 전이라 입력하면 "준비 중" 안내만 보인다.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  late String _query = widget.initialQuery;
  SearchSource _source = SearchSource.youtube;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
          if (_query.trim().isEmpty)
            _Hint(
              icon: Icons.travel_explore_rounded,
              title: l10n.searchEmptyTitle,
              body: l10n.searchEmptyBody,
            )
          else
            _Hint(
              icon: Icons.hourglass_empty_rounded,
              title: l10n.searchNotReadyTitle,
              body: l10n.searchNotReadyBody,
            ),
        ],
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
        // 받은 곡을 보관함 곡과 이어 재생하는 건 다운로드 엔진이 붙은 뒤에 한다.
        onPlay: (_) {},
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

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
          ],
        ),
      ),
    );
  }
}
