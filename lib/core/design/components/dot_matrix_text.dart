import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';

/// LED 점 행렬 스타일 글자 (5×7). 숫자와 `: . - / %`, 공백을 지원한다.
///
/// 재생 시간, 곡 수, 다운로드 진행률처럼 큰 숫자에 쓴다.
/// 지원하지 않는 글자는 빈 칸으로 그린다.
class DotMatrixText extends StatelessWidget {
  const DotMatrixText(
    this.text, {
    super.key,
    this.dotSize = 5,
    this.gap = 2,
    this.color,
    this.showUnlit = true,
  });

  final String text;

  /// 점 하나의 지름. 글자 높이 = 7 × (dotSize + gap).
  final double dotSize;
  final double gap;

  /// 켜진 점 색. 없으면 onSurface.
  final Color? color;

  /// 꺼진 점을 옅게 보여 줄지.
  final bool showUnlit;

  static const int _cols = 5;
  static const int _rows = 7;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lit = color ?? p.onSurface;
    final cell = dotSize + gap;
    final charWidth = _cols * cell;
    final width = text.length * (charWidth + cell) - cell;

    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size(width.clamp(0, double.infinity), _rows * cell - gap),
          painter: _DotMatrixPainter(
            text: text,
            dot: dotSize,
            cell: cell,
            lit: lit,
            unlit: showUnlit ? lit.withValues(alpha: .08) : null,
          ),
        ),
      ),
    );
  }
}

class _DotMatrixPainter extends CustomPainter {
  _DotMatrixPainter({
    required this.text,
    required this.dot,
    required this.cell,
    required this.lit,
    required this.unlit,
  });

  final String text;
  final double dot;
  final double cell;
  final Color lit;
  final Color? unlit;

  @override
  void paint(Canvas canvas, Size size) {
    final litPaint = Paint()..color = lit;
    final unlitPaint = unlit == null ? null : (Paint()..color = unlit!);
    final r = dot / 2;
    var originX = 0.0;

    for (final ch in text.split('')) {
      final glyph = _glyphs[ch] ?? _glyphs[' ']!;
      for (var row = 0; row < DotMatrixText._rows; row++) {
        final bits = glyph[row];
        for (var col = 0; col < DotMatrixText._cols; col++) {
          final on = bits[col] == '#';
          final paint = on ? litPaint : unlitPaint;
          if (paint == null) continue;
          canvas.drawCircle(
            Offset(originX + col * cell + r, row * cell + r),
            r,
            paint,
          );
        }
      }
      originX += (DotMatrixText._cols + 1) * cell;
    }
  }

  @override
  bool shouldRepaint(_DotMatrixPainter old) =>
      old.text != text ||
      old.lit != lit ||
      old.unlit != unlit ||
      old.dot != dot ||
      old.cell != cell;
}

const Map<String, List<String>> _glyphs = {
  '0': ['.###.', '#...#', '#..##', '#.#.#', '##..#', '#...#', '.###.'],
  '1': ['..#..', '.##..', '..#..', '..#..', '..#..', '..#..', '.###.'],
  '2': ['.###.', '#...#', '....#', '...#.', '..#..', '.#...', '#####'],
  '3': ['#####', '...#.', '..#..', '...#.', '....#', '#...#', '.###.'],
  '4': ['...#.', '..##.', '.#.#.', '#..#.', '#####', '...#.', '...#.'],
  '5': ['#####', '#....', '####.', '....#', '....#', '#...#', '.###.'],
  '6': ['..##.', '.#...', '#....', '####.', '#...#', '#...#', '.###.'],
  '7': ['#####', '....#', '...#.', '..#..', '.#...', '.#...', '.#...'],
  '8': ['.###.', '#...#', '#...#', '.###.', '#...#', '#...#', '.###.'],
  '9': ['.###.', '#...#', '#...#', '.####', '....#', '...#.', '.##..'],
  ':': ['.....', '..#..', '..#..', '.....', '..#..', '..#..', '.....'],
  '.': ['.....', '.....', '.....', '.....', '.....', '.##..', '.##..'],
  '-': ['.....', '.....', '.....', '#####', '.....', '.....', '.....'],
  '/': ['.....', '....#', '...#.', '..#..', '.#...', '#....', '.....'],
  '%': ['##...', '##..#', '...#.', '..#..', '.#...', '#..##', '...##'],
  ' ': ['.....', '.....', '.....', '.....', '.....', '.....', '.....'],
};
