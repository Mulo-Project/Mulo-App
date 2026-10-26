import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/track.dart';
import 'track_menu.dart';

/// 모르는 아티스트 · 앨범 · 장르는 안내 문구로.
String artistOf(AppLocalizations l10n, Track t) =>
    t.artist.isEmpty ? l10n.unknownArtist : t.artist;

String albumOf(AppLocalizations l10n, Track t) =>
    t.album.isEmpty ? l10n.unknownAlbum : t.album;

String genreOf(AppLocalizations l10n, String genre) =>
    genre.isEmpty ? l10n.unknownGenre : genre;

/// 여러 곡 선택 상태 (보관함 곡 탭). 선택 모드가 아니면 길게 누르기로 모드에 들어가고,
/// 선택 모드에서는 누르면 고르거나 풀며 오른쪽에 체크가 보인다. 팝업 메뉴는 ⋮로만 연다.
class TrackSelection {
  const TrackSelection({
    required this.active,
    required this.selected,
    required this.onToggle,
  });

  /// 선택 모드인가.
  final bool active;

  /// 이 곡이 골라져 있는가.
  final bool selected;

  /// 고르거나 푼다 (선택 모드가 아니면 모드에 들어가며 이 곡을 고른다).
  final VoidCallback onToggle;
}

/// 선택 모드에서 곡 줄 오른쪽에 보이는 체크 표시.
Widget selectionMark(BuildContext context, TrackSelection sel) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
  child: Icon(
    sel.selected ? AppIcons.checkCircle : AppIcons.radioOff,
    color: sel.selected
        ? context.palette.accent
        : context.palette.onSurfaceMuted,
  ),
);

/// 곡 목록의 한 줄 (보관함 · 재생목록 상세 · 앨범에서 같이 쓴다).
/// 누르면 [queue]를 [index]부터 재생하고, ⋮ · 길게 누르기는 곡 메뉴를 연다.
/// [playlistId]가 있으면 재생목록 안의 곡이라서 곡 메뉴의 삭제가 "빼기" · "파일 삭제"로 나뉜다.
class TrackListTile extends StatelessWidget {
  const TrackListTile({
    super.key,
    required this.track,
    required this.queue,
    required this.index,
    this.playlistId,
    this.showAlbum = true,
    this.showNumber = false,
    this.selection,
  });

  final Track track;
  final List<Track> queue;
  final int index;
  final String? playlistId;

  /// 부제에 앨범도 보여 줄지 (앨범 화면에서는 아티스트만).
  final bool showAlbum;

  /// 커버 앞에 목록 속 순번을 보여 줄지 (재생목록 상세).
  final bool showNumber;

  /// 있으면 여러 곡 선택을 지원한다 ([TrackSelection]).
  final TrackSelection? selection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vm = context.read<NowPlayingCubit>();
    // 곡 전체가 아니라 "이 곡인지"만 고른다: 곡이 바뀔 때 두 줄만 다시 그려진다.
    final isCurrent = context.select(
      (NowPlayingCubit c) => c.state.track?.id == track.id,
    );
    final t = track;
    final sel = selection;
    final picking = sel != null && sel.active;
    return TrackTile(
      title: t.title,
      subtitle: showAlbum
          ? '${artistOf(l10n, t)} · ${albumOf(l10n, t)}'
          : artistOf(l10n, t),
      tone: toneFor(t.id),
      color: coverColorOf(context, CoverKey.track(t.id)),
      active: isCurrent,
      number: showNumber ? index + 1 : null,
      artwork: coverImageOf(context, CoverKey.track(t.id)),
      trailing: picking
          ? selectionMark(context, sel)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatDuration(t.duration),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TrackMoreButton(track: t, playlistId: playlistId),
              ],
            ),
      onTap: picking ? sel.onToggle : () => vm.playQueue(queue, index: index),
      // 선택을 지원하는 목록에서는 길게 누르기가 선택 모드 진입이고, 메뉴는 ⋮로만 연다.
      onLongPress: sel?.onToggle,
      onMenu: sel != null
          ? null
          : (pos) => showTrackMenu(
              context,
              t,
              globalPosition: pos,
              playlistId: playlistId,
            ),
    );
  }
}
