/// 검색 결과를 늘어놓는 순서 (relevance는 찾은 그대로).
/// newest는 올린 날 최신 순으로 `찾아 오는` 것이라 고르면 검색을 다시 한다 (키워드 검색만).
/// 나머지는 받아 온 결과 안에서만 바꾼다 (popular는 목록에 있는 조회수 많은 순).
/// 인기 · 길이 · 제목은 오름 · 내림차순을 바꿀 수 있다 ([SearchSortX.hasDirection]).
enum SearchSort { relevance, popular, newest, duration, title }

extension SearchSortX on SearchSort {
  /// 오름 · 내림차순을 바꿀 수 있는 정렬인지 (관련도 · 최신순은 찾는 쪽이 정한 순서라 바꿀 수 없다).
  bool get hasDirection =>
      this == SearchSort.popular ||
      this == SearchSort.duration ||
      this == SearchSort.title;

  /// 기준을 처음 골랐을 때의 방향 (true 오름차순): 인기는 많은 순, 길이는 짧은 순, 제목은 가나다순.
  bool get defaultAscending => this != SearchSort.popular;
}
