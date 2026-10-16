import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../search/domain/entities/subtitle_track.dart';
import '../bloc/subtitle_preview_cubit.dart';

/// 상세 페이지에서 "이 자막 사용"을 눌러 돌아온 결과.
/// [edited]는 글을 고친 경우의 자막이고, 고치지 않았으면 null이다.
class SubtitleChoice {
  const SubtitleChoice(this.edited);

  final SubtitleTrack? edited;
}

/// 자막 한 벌의 전체 가사를 받기 전에 훑어보고 글을 고치는 페이지를 연다.
/// "이 자막 사용"을 누르면 [SubtitleChoice], 그냥 닫으면 null을 돌려준다.
Future<SubtitleChoice?> showSubtitleDetail(
  BuildContext context, {
  required String url,
  required String language,
  required String title,
  required String kind,
  required bool skipSounds,
  required bool selected,
  SubtitleTrack? edited,
}) => Navigator.of(context, rootNavigator: true).push<SubtitleChoice>(
  MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (_) {
        final cubit = sl<SubtitlePreviewCubit>();
        // 이미 고쳐 둔 글이 있으면 다시 읽지 않고 그것을 보여 준다.
        if (edited != null) {
          cubit.show(edited);
        } else {
          cubit.load(url, language: language, skipSounds: skipSounds);
        }
        return cubit;
      },
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

/// 고른 언어의 자막 전체(시간 + 글). 받기 전에 어떤 가사가 들어올지 확인하고,
/// 줄의 글을 고친다. 시간은 바꿀 수 없고 줄을 더하거나 지울 수도 없다 (싱크는 받은 뒤 재생 화면에서).
class SubtitleDetailScreen extends StatefulWidget {
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

  @override
  State<SubtitleDetailScreen> createState() => _SubtitleDetailScreenState();
}

class _SubtitleDetailScreenState extends State<SubtitleDetailScreen> {
  List<TextEditingController> _controllers = const [];
  SubtitleTrack? _source;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// 불러온 자막이 바뀌면 줄마다 입력칸을 새로 만든다.
  void _sync(SubtitleTrack? track) {
    if (identical(track, _source)) return;
    for (final c in _controllers) {
      c.dispose();
    }
    _source = track;
    _controllers = [
      for (final cue in track?.cues ?? const <SubtitleCue>[])
        TextEditingController(text: cue.text),
    ];
  }

  static String _clock(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// 글만 고친 자막. 고치지 않았으면 null. 글을 비운 줄은 빠진다.
  SubtitleTrack? _editedTrack() {
    final src = _source;
    if (src == null) return null;
    var changed = false;
    final cues = <SubtitleCue>[];
    for (var i = 0; i < src.cues.length; i++) {
      final text = _controllers[i].text.trim();
      if (text != src.cues[i].text.trim()) changed = true;
      if (text.isNotEmpty) cues.add(SubtitleCue(src.cues[i].start, text));
    }
    return changed
        ? SubtitleTrack(
            language: src.language,
            automatic: src.automatic,
            cues: cues,
          )
        : null;
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
              title: widget.title,
              subtitle: widget.kind,
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
                  _sync(track);
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
                                    widget.url,
                                    language: widget.language,
                                    skipSounds: widget.skipSounds,
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xs,
                        ),
                        child: Text(
                          l10n.downloadSubtitleEditHint,
                          style: text.bodySmall?.copyWith(
                            color: p.onSurfaceMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          itemCount: track.cues.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: AppTextField(
                              label: _clock(track.cues[i].start),
                              controller: _controllers[i],
                              maxLines: 2,
                              textInputAction: TextInputAction.newline,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                  label: widget.selected
                      ? l10n.downloadSubtitleUseEdited
                      : l10n.downloadSubtitleUse,
                  icon: AppIcons.check,
                  onPressed: () =>
                      Navigator.of(context).pop(SubtitleChoice(_editedTrack())),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
