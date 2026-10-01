import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
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
  });

  final Track track;
  final List<Track> queue;
  final int index;
  final String? playlistId;

  /// 부제에 앨범도 보여 줄지 (앨범 화면에서는 아티스트만).
  final bool showAlbum;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vm = context.read<NowPlayingCubit>();
    final current = context.select((NowPlayingCubit c) => c.state.track);
    final t = track;
    return TrackTile(
      title: t.title,
      subtitle: showAlbum
          ? '${artistOf(l10n, t)} · ${albumOf(l10n, t)}'
          : artistOf(l10n, t),
      tone: toneFor(t.id),
      active: t == current,
      artwork: coverImageOf(context, CoverKey.track(t.id)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatDuration(t.duration),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TrackMoreButton(track: t, playlistId: playlistId),
        ],
      ),
      onTap: () => vm.playQueue(queue, index: index),
      onMenu: (pos) => showTrackMenu(
        context,
        t,
        globalPosition: pos,
        playlistId: playlistId,
      ),
    );
  }
}
