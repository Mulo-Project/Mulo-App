/// 검색 결과를 늘어놓는 순서 (relevance는 찾은 그대로).
/// newest는 올린 날 최신 순으로 `찾아 오는` 것이라 고르면 검색을 다시 한다 (키워드 검색만).
/// 나머지는 받아 온 결과 안에서만 바꾼다.
enum SearchSort { relevance, newest, shortest, longest, title }
