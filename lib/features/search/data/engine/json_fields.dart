/// JSON의 문자열 목록에서 비어 있지 않은 것만 (없거나 목록이 아니면 빈 목록).
List<String> parseStrings(Object? raw) => raw is List
    ? [
        for (final c in raw)
          if (c is String && c.trim().isNotEmpty) c.trim(),
      ]
    : const [];

/// JSON의 분류 목록 (yt-dlp `categories`).
List<String> parseCategories(Object? raw) => parseStrings(raw);

/// JSON의 숫자 칸 (정수 · 실수 모두 정수로, 아니면 null).
int? parseCount(Object? raw) => raw is num ? raw.round() : null;

/// JSON의 날짜 칸: yt-dlp의 `20240131` 또는 ISO `2024-01-31...` (아니면 null).
DateTime? parseDate(Object? raw) {
  if (raw is! String) return null;
  final s = raw.trim();
  if (RegExp(r'^\d{8}$').hasMatch(s)) {
    return DateTime.tryParse(
      '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6)}',
    );
  }
  return DateTime.tryParse(s);
}

/// JSON의 문자열 칸 (비어 있으면 null).
String? parseText(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw.trim() : null;
