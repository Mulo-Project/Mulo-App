import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/subtitle_preview_cubit.dart';

/// 자막 한 벌의 전체 가사를 받기 전에 훑어보는 페이지를 연다.
/// "이 자막 사용"을 누르면 true, 그냥 닫으면 null을 돌려준다.
Future<bool?> showSubtitleDetail(
  BuildContext context, {
  required String url,
  required String language,
  required String title,
  required String kind,
  required bool skipSounds,
  required bool selected,
}) => Navigator.of(context, rootNavigator: true).push<bool>(
  MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (_) =>
          sl<SubtitlePreviewCubit>()
            ..load(url, language: language, skipSounds: skipSounds),
      child: SubtitleDetailScreen(
        url: url,
        language: language,
        title: title,
        kind: kind,
        skipSounds: skipSounds,
        selected: selected,
      ),
    ),
  ),
);

/// 고른 언어의 자막 전체(시간 + 글). 받기 전에 어떤 가사가 들어올지 확인하고 고른다.
class SubtitleDetailScreen extends StatelessWidget {
  const SubtitleDetailScreen({
    super.key,
    required this.url,
    required this.language,
    required this.title,
    required this.kind,
    required this.skipSounds,
    required this.selected,
  });

  final String url;
  final String language;
  final String title;
  final String kind;
  final bool skipSounds;
  final bool selected;

  static String _clock(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: title,
              subtitle: kind,
              leading: CircleIconButton(
                icon: AppIcons.back,
                tooltip: l10n.actionCancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: BlocBuilder<SubtitlePreviewCubit, SubtitlePreview>(
                builder: (context, preview) {
                  final track = preview.track;
                  if (preview.status == SubtitlePreviewStatus.failed) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.downloadLyricsPreviewFailed,
                              style: text.bodyMedium?.copyWith(
                                color: p.onSurfaceMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            PillButton(
                              label: l10n.downloadLyricsRetry,
                              compact: true,
                              variant: PillVariant.tonal,
                              onPressed: () =>
                                  context.read<SubtitlePreviewCubit>().load(
                                    url,
                                    language: language,
                                    skipSounds: skipSounds,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (track == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(strokeWidth: 2),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.downloadLyricsPreviewLoading,
                            style: text.bodyMedium?.copyWith(
                              color: p.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: track.cues.length,
                    itemBuilder: (_, i) {
                      final cue = track.cues[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 52,
                              child: Text(
                                _clock(cue.start),
                                style: text.bodySmall?.copyWith(
                                  color: p.onSurfaceMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(cue.text, style: text.bodyMedium),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: SizedBox(
                width: double.infinity,
                child: PillButton(
                  key: const ValueKey('subtitle-detail-use'),
                  label: selected
                      ? l10n.downloadSubtitleInUse
                      : l10n.downloadSubtitleUse,
                  icon: AppIcons.check,
                  onPressed: selected
                      ? null
                      : () => Navigator.of(context).pop(true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
