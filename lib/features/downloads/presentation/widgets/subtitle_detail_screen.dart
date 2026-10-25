import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../library/domain/entities/track.dart';
import '../../../lyrics/domain/entities/timed_lyrics_text.dart';
import '../../../lyrics/domain/usecases/lyrics_usecases.dart';
import '../../../lyrics/presentation/screens/lyrics_web_screen.dart';
import '../../../lyrics/presentation/widgets/lyrics_dialogs.dart';
import '../../../lyrics/presentation/widgets/timed_lyrics_controller.dart';
import '../../../lyrics/presentation/widgets/lyrics_edit_scaffold.dart';
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
  String songTitle = '',
  String songArtist = '',
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
        songTitle: songTitle,
        songArtist: songArtist,
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
    this.songTitle = '',
    this.songArtist = '',
  });

  final String url;
  final String language;
  final String title;
  final String kind;
  final bool skipSounds;
  final bool selected;
  final String? edited;

  /// 받을 곡의 제목 · 아티스트 (웹에서 가사를 찾을 때 검색어).
  final String songTitle;
  final String songArtist;

  @override
  State<SubtitleDetailScreen> createState() => _SubtitleDetailScreenState();
}

class _SubtitleDetailScreenState extends State<SubtitleDetailScreen> {
  final _text = TimedLyricsController();

  /// 처음 보여 준 가사(.lrc 글). 고쳤는지 비교한다.
  String? _base;
  var _synced = false;

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
    _synced = split.isSynced;
    _text.load(split);
  }

  Future<void> _pickFile() async {
    final picked = await sl<PickLyricsFile>()(const NoParams());
    if (picked != null && mounted) await _apply(picked);
  }

  Future<void> _searchWeb() async {
    final probe = Track(
      id: 'download',
      title: widget.songTitle.isEmpty ? widget.title : widget.songTitle,
      artist: widget.songArtist,
      album: '',
      duration: Duration.zero,
      uri: '',
      addedAt: DateTime.now(),
    );
    final picked = await showLyricsWeb(context, probe);
    if (picked != null && mounted) await _apply(picked);
  }

  /// 불러온 글을 넣는다. 가사가 이미 있으면 바꿀지 뒤에 붙일지 먼저 묻는다.
  /// 자막을 못 읽었어도(실패 · 없음) 불러온 글을 이 곡의 가사로 쓸 수 있다.
  Future<void> _apply(String imported) async {
    // 처음 보여 준 자막(비교 기준)은 그대로 둔다: 불러온 글이 "고친 가사"로 돌아가게.
    // 자막을 못 읽었어도 고친 글로 돌려줄 수 있게 기준이 없으면 빈 글로 둔다.
    final base = _base ?? '';
    if (_text.text.trim().isEmpty) {
      setState(() {
        _fill(imported);
        _base = base;
      });
      return;
    }
    final mode = await showLyricsImportMode(context);
    if (mode == null || !mounted) return;
    setState(() {
      if (mode == LyricsImportMode.replace) {
        _fill(imported);
        _base = base;
      } else {
        // 붙인 글은 시간 없는 줄로 뒤에 더한다.
        final extra = TimedLyricsText.parse(imported).text;
        _text.text = '${_text.text.trimRight()}\n$extra';
      }
    });
  }

  /// 고친 가사. 고치지 않았으면 null.
  String? _editedRaw() {
    final base = _base;
    if (base == null) return null;
    final composed = _text.compose();
    return composed == base.trimRight() ? null : composed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return BlocConsumer<SubtitlePreviewCubit, SubtitlePreview>(
      listener: (context, preview) {
        final track = preview.track;
        if (track != null && _base == null) {
          setState(() => _fill(track.toLrc()));
        }
      },
      builder: (context, preview) {
        Widget? body;
        if (preview.status == SubtitlePreviewStatus.failed && _base == null) {
          body = Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.downloadLyricsPreviewFailed,
                    style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PillButton(
                    label: l10n.downloadLyricsRetry,
                    compact: true,
                    variant: PillVariant.tonal,
                    onPressed: () => context.read<SubtitlePreviewCubit>().load(
                      widget.url,
                      language: widget.language,
                      skipSounds: widget.skipSounds,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (_base == null) {
          body = LoadingState(label: l10n.downloadLyricsPreviewLoading);
        }
        return LyricsEditScaffold(
          title: widget.title,
          subtitle: widget.kind,
          controller: _text,
          showTimes: _synced,
          notice: l10n.downloadSubtitleEditHint,
          // 영상 자막 말고 파일이나 웹에서도 가사를 불러올 수 있다 (자막이 없거나 읽지 못했을 때도).
          tools: [
            PlainButton(
              key: const ValueKey('subtitle-detail-file'),
              label: l10n.lyricsLoadFile,
              icon: AppIcons.fileOpen,
              onPressed: _pickFile,
            ),
            if (lyricsWebSupported)
              PlainButton(
                key: const ValueKey('subtitle-detail-web'),
                label: l10n.lyricsWebSearch,
                icon: AppIcons.explore,
                onPressed: _searchWeb,
              ),
          ],
          body: body,
          primaryKey: const ValueKey('subtitle-detail-use'),
          primaryLabel: l10n.downloadSubtitleUse,
          onPrimary: () =>
              Navigator.of(context).pop(SubtitleChoice(_editedRaw())),
          leadingIcon: AppIcons.back,
        );
      },
    );
  }
}
