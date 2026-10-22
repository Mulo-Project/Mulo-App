import 'package:flutter/material.dart';

/// 위쪽 머리 위젯들 뒤에 곡 줄을 이어 붙인 세로 목록.
/// 곡 줄은 [trackBuilder]가 보이는 만큼만 만든다 (곡이 수천 개여도 화면에 걸린 줄만 그린다).
class LazyTrackList extends StatelessWidget {
  const LazyTrackList({
    super.key,
    required this.padding,
    required this.header,
    required this.trackCount,
    required this.trackBuilder,
  });

  final EdgeInsetsGeometry padding;
  final List<Widget> header;
  final int trackCount;
  final Widget Function(BuildContext context, int index) trackBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: header.length + trackCount,
      itemBuilder: (context, i) => i < header.length
          ? header[i]
          : trackBuilder(context, i - header.length),
    );
  }
}
