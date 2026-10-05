/// 검색 결과를 늘어놓는 순서. 받아 온 결과 안에서 정한다 (relevance는 찾은 그대로).
/// popular는 조회수 많은 순, newest는 올린 날 최신 순 (모르는 곡은 맨 뒤).
enum SearchSort { relevance, popular, newest, shortest, longest, title }
