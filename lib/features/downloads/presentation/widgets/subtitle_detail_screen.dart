import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../lyrics/domain/entities/timed_lyrics_text.dart';
import '../../../lyrics/presentation/widgets/timed_lyrics_field.dart';
import '../bloc/subtitle_preview_cubit.dart';

/// 상세 페이지에서 "이 자막 사용"을 눌러 돌아온 결과.
/// [edited]는 글을 고친 경우의 가사(.lrc 글)이고, 고치지 않았으면 null이다.
class SubtitleChoice {
  const SubtitleChoice(this.edited);

  final String? edited;
}

/// 자막 한 벌의 전체 가사를 받기 전에 훑어보고 글을 고치는 페이지를 연다.
/// [edited]는 앞서 고쳐 둔 가사로, 있으면 다시 읽지 않고 그것을 이어서 고친다.
/// "이 자막 사용"을 누르면 [SubtitleChoice], 그냥 닫으면 null을 돌려준다.
Future<SubtitleChoice?> showSubtitleDetail(
  BuildContext context, {
  required String url,
  required String language,
  required String title,
  required String kind,
  required bool skipSounds,
  required bool selected,
  String? edited,
}) => Navigator.of(context, rootNavigator: true).push<SubtitleChoice>(
  MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (_) {
        final cubit = sl<SubtitlePreviewCubit>();
        if (edited == null) {
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
        edited: edited,
      ),
    ),
  ),
);

/// 고른 언어의 자막 전체. 왼쪽에 시간, 오른쪽에 복사할 수 있는 글 한 덩어리로 보여 주고,
/// 글을 고칠 수 있다. 시간은 바꿀 수 없다 (싱크는 받은 뒤 재생 화면에서).
class SubtitleDetailScreen extends StatefulWidget {
  const SubtitleDetailScreen({
    super.key,
    required this.url,
    required this.language,
    required this.title,
    required this.kind,
    required this.skipSounds,
    required this.selected,
    this.edited,
  });

  final String url;
  final String language;
  final String title;
  final String kind;
  final bool skipSounds;
  final bool selected;
  final String? edited;

  @override
  State<SubtitleDetailScreen> createState() => _SubtitleDetailScreenState();
}

class _SubtitleDetailScreenState extends State<SubtitleDetailScreen> {
  final _text = TextEditingController();
  var _times = const <Duration>[];

  /// 처음 보여 준 가사(.lrc 글). 고쳤는지 비교한다.
  String? _base;

  @override
  void initState() {
    super.initState();
    final edited = widget.edited;
    if (edited != null) _fill(edited);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _fill(String raw) {
    final split = TimedLyricsText.parse(raw);
    _base = raw;
    _times = split.times;
    _text.text = split.text;
  }

  /// 고친 가사. 고치지 않았으면 null.
  String? _editedRaw() {
    final base = _base;
    if (base == null) return null;
    final composed = TimedLyricsText(_text.text, _times).compose(_text.text);
    return composed == base.trimRight() ? null : composed;
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
              child: BlocConsumer<SubtitlePreviewCubit, SubtitlePreview>(
                listener: (context, preview) {
                  final track = preview.track;
                  if (track != null && _base == null) {
                    setState(() => _fill(track.toLrc()));
                  }
                },
                builder: (context, preview) {
                  if (preview.status == SubtitlePreviewStatus.failed &&
                      _base == null) {
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
                  if (_base == null) {
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text(
                            l10n.downloadSubtitleEditHint,
                            style: text.bodySmall?.copyWith(
                              color: p.onSurfaceMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TimedLyricsField(
                            controller: _text,
                            times: _times,
                          ),
                        ),
                      ],
                    ),
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
                  label: l10n.downloadSubtitleUse,
                  icon: AppIcons.check,
                  onPressed: () =>
                      Navigator.of(context).pop(SubtitleChoice(_editedRaw())),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
