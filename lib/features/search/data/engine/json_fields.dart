/// JSON의 분류 목록에서 비어 있지 않은 문자열만 (없거나 목록이 아니면 빈 목록).
List<String> parseCategories(Object? raw) => raw is List
    ? [
        for (final c in raw)
          if (c is String && c.trim().isNotEmpty) c.trim(),
      ]
    : const [];
