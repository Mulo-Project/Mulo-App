import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../../../lyrics/domain/entities/timed_lyrics_text.dart';
import '../../../lyrics/presentation/widgets/lyrics_import_bar.dart';
import '../../../lyrics/presentation/widgets/timed_lyrics_controller.dart';
import '../../../lyrics/presentation/widgets/lyrics_edit_scaffold.dart';
import '../bloc/subtitle_preview_cubit.dart';

/// 상세 페이지에서 "이 자막 사용"을 눌러 돌아온 결과.
/// [text]는 그 자막의 가사(.lrc 글)로, 페이지에서 글을 고쳤다면 고친 글이다.
/// 받기 창이 이 글을 "가사 설정"의 가사로 적용한다.
class SubtitleChoice {
  const SubtitleChoice(this.text);

  final String text;
}

/// 자막 한 벌의 전체 가사를 받기 전에 훑어보고 글을 고치는 페이지를 연다.
/// [edited]는 앞서 고쳐 둔 가사로, 있으면 다시 읽지 않고 그것을 이어서 고친다.
/// "이 자막 사용"을 누르면 [SubtitleChoice](가사 글), 그냥 닫으면 null을 돌려준다.
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

  /// 웹에서 가사를 찾을 때 검색어가 되는 곡 (받기 창에 적힌 제목 · 아티스트).
  Track _probe() => Track(
    id: 'download',
    title: widget.songTitle.isEmpty ? widget.title : widget.songTitle,
    artist: widget.songArtist,
    album: '',
    duration: Duration.zero,
    uri: '',
    addedAt: DateTime.now(),
  );

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
          // 영상 자막 말고 파일이나 웹에서도 가사를 불러올 수 있다 (가사 설정과 같은 줄).
          top: LyricsImportBar(
            keyPrefix: 'subtitle-detail',
            controller: _text,
            track: _probe(),
            onReplace: (raw) => setState(() {
              // 처음 보여 준 자막(비교 기준)은 그대로 두어 불러온 글이 "고친 가사"로 돌아가게 한다.
              final base = _base ?? '';
              _fill(raw);
              _base = base;
            }),
          ),
          body: body,
          primaryKey: const ValueKey('subtitle-detail-use'),
          primaryLabel: l10n.downloadSubtitleUse,
          // 자막(또는 불러온 글)이 아직 없으면 고를 수 없다 (불러오는 중 · 못 읽음).
          onPrimary: _base == null
              ? null
              : () =>
                    Navigator.of(context).pop(SubtitleChoice(_text.compose())),
          leadingIcon: AppIcons.back,
        );
      },
    );
  }
}
