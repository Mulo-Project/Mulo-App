/// 검색 대상 사이트. 키워드 검색을 yt-dlp가 지원하는 사이트만 둔다
/// (그 밖의 사이트는 주소를 붙여 넣어 받는다).
enum SearchSource {
  youtube('ytsearch', supportsNewest: true),
  soundcloud('scsearch', serverValue: 'web'),
  bilibili('bilisearch'),
  niconico('nicosearch', supportsNewest: true);

  const SearchSource(
    this.searchKey, {
    this.supportsNewest = false,
    this.serverValue,
  });

  /// yt-dlp 검색 접두사 (`<접두사><개수>:<검색어>`).
  final String searchKey;

  /// 날짜 순 검색(`<접두사>date`)이 있는지.
  final bool supportsNewest;

  /// 서버 `source` 쿼리 값을 따로 정한 사이트 (SoundCloud는 서버 명세에 이미 있는 `web`).
  final String? serverValue;

  /// 서버에 보낼 `source` 값. 유튜브는 기본이라 null.
  String? get serverQuery => this == youtube ? null : (serverValue ?? name);
}
