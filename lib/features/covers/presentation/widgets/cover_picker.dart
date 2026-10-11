import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/cover_cubit.dart';
import '../bloc/cover_web_cubit.dart';
import 'cover_editor_page.dart';

/// 커버 이미지를 새로 고른다: 기기 사진이나 웹 이미지를 고르고, 확대 · 위치를 맞춘 뒤
/// 돌려준다. 어느 단계에서든 닫으면 null. 저장은 부른 쪽에서 [CoverCubit.setArt]로 한다.
///
/// [initialQuery]는 웹 이미지 고르기에서 처음부터 검색해 둘 말 (곡 · 재생목록 이름).
Future<CoverArt?> pickCoverArt(
  BuildContext context, {
  String initialQuery = '',
}) async {
  final covers = context.read<CoverCubit>();
  final source = await showModalBottomSheet<_Source>(
    context: context,
    backgroundColor: context.palette.surface,
    showDragHandle: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.md)),
    ),
    builder: (_) => const _SourceSheet(),
  );
  if (source == null || !context.mounted) return null;

  final CoverArt? picked;
  switch (source) {
    case _Source.device:
      final path = await covers.pickFile();
      picked = path == null ? null : CoverArt.file(path);
    case _Source.web:
      final url = await Navigator.of(context, rootNavigator: true).push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => BlocProvider(
            create: (_) => sl<CoverWebCubit>(),
            child: _WebImagePage(initialQuery: initialQuery),
          ),
        ),
      );
      picked = url == null ? null : CoverArt.web(url);
  }
  if (picked == null || !context.mounted) return null;
  return showCoverEditor(context, picked);
}

enum _Source { device, web }

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.coverSourceTitle, style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            PillButton(
              label: l10n.coverSourceDevice,
              icon: AppIcons.photoLibrary,
              onPressed: () => Navigator.of(context).pop(_Source.device),
            ),
            const SizedBox(height: AppSpacing.xs),
            PillButton(
              label: l10n.coverSourceWeb,
              icon: AppIcons.globe,
              variant: PillVariant.tonal,
              onPressed: () => Navigator.of(context).pop(_Source.web),
            ),
          ],
        ),
      ),
    );
  }
}

/// 웹 이미지 고르기: 이미지 주소를 붙여 넣거나, 검색어로 찾은 결과에서 고른다.
/// 고른 이미지의 주소를 돌려준다 (파일은 받지 않는다).
class _WebImagePage extends StatefulWidget {
  const _WebImagePage({this.initialQuery = ''});

  final String initialQuery;

  @override
  State<_WebImagePage> createState() => _WebImagePageState();
}

class _WebImagePageState extends State<_WebImagePage> {
  late final _input = TextEditingController(text: widget.initialQuery.trim());

  @override
  void initState() {
    super.initState();
    // 이름이 있으면 그 이름으로 찾은 결과를 먼저 보여 준다.
    final q = widget.initialQuery.trim();
    if (q.isNotEmpty && !isWebImageUrl(q)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<CoverWebCubit>().search(q);
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    if (isWebImageUrl(v)) {
      Navigator.of(context).pop(v);
    } else {
      context.read<CoverWebCubit>().search(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final isUrl = isWebImageUrl(_input.text);

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.coverSourceWeb,
                leading: CircleIconButton(
                  icon: AppIcons.close,
                  tooltip: l10n.actionBack,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Padding(
                padding: AppSpacing.screen.copyWith(top: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSearchField(
                      hint: l10n.coverWebHint,
                      clearTooltip: l10n.actionClear,
                      controller: _input,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _submit,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.coverWebHelp,
                      style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
                    ),
                    if (isUrl) ...[
                      const SizedBox(height: AppSpacing.sm),
                      PillButton(
                        label: l10n.coverWebUseUrl,
                        icon: AppIcons.link,
                        onPressed: () => _submit(_input.text),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<CoverWebCubit, CoverWebState>(
                  builder: (context, state) => switch (state.status) {
                    CoverWebStatus.idle => const SizedBox.shrink(),
                    CoverWebStatus.loading => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    CoverWebStatus.failed => _Message(l10n.coverWebFailed),
                    CoverWebStatus.loaded when state.images.isEmpty => _Message(
                      l10n.coverWebEmpty,
                    ),
                    CoverWebStatus.loaded => GridView.builder(
                      padding: AppSpacing.screen.copyWith(
                        top: AppSpacing.md,
                        bottom: AppSpacing.md,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 180,
                            mainAxisSpacing: AppSpacing.sm,
                            crossAxisSpacing: AppSpacing.sm,
                          ),
                      itemCount: state.images.length,
                      itemBuilder: (context, i) {
                        final url = state.images[i];
                        return GestureDetector(
                          onTap: () => Navigator.of(context).pop(url),
                          child: LayoutBuilder(
                            builder: (context, box) => ArtworkBox(
                              image: NetworkImage(url),
                              size: box.maxWidth,
                              radius: AppRadii.sm,
                            ),
                          ),
                        );
                      },
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: context.palette.onSurfaceMuted),
    ),
  );
}
