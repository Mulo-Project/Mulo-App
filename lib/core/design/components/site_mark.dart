import 'package:flutter/material.dart';

import '../tokens/app_palette.dart';

/// 검색 사이트를 나타내는 동그란 표시: 브랜드 색 바탕에 머리글자 하나.
/// (유튜브는 [YoutubeMark]를 쓴다.)
class SiteMark extends StatelessWidget {
  const SiteMark({
    super.key,
    required this.letter,
    required this.color,
    this.size = 24,
  });

  final String letter;
  final Color color;

  /// 원의 지름.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        letter,
        style: TextStyle(
          color: AppPalette.markWhite,
          fontSize: size * .5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
