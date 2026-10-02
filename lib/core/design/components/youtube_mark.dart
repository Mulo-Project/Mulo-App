import 'package:flutter/material.dart';

import '../tokens/app_palette.dart';

/// 유튜브 표시: 빨간 둥근 사각형 안에 항상 흰 재생 삼각형 (테마와 상관없다).
class YoutubeMark extends StatelessWidget {
  const YoutubeMark({super.key, this.size = 24});

  /// 가로 길이. 세로는 70%.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('youtube-mark'),
      width: size,
      height: size * .7,
      decoration: BoxDecoration(
        color: AppPalette.youtubeRed,
        borderRadius: BorderRadius.circular(size * .22),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.play_arrow_rounded,
        size: size * .62,
        color: AppPalette.markWhite,
      ),
    );
  }
}
