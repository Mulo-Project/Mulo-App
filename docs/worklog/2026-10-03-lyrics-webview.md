# 가사 웹 검색으로 가져오기

- 날짜: 2026-10-03
- 분류: 앱
- 상태: 완료
- 브랜치 · 커밋: `feature/lyrics-webview`
- 상세 기능: 가사 (웹 검색 가져오기)

## 한 일
- 가사 편집기에 "웹에서 검색해 가져오기" 버튼(Android만) 추가. WebView에서 검색 → 가사를 끌어서 선택 → "가져오기"로 편집기에 삽입.
- `lyrics_web_screen.dart` 추가, ARB 문구(ko · en) 추가. 결정: D-046.

## 바꾼 설정
- pubspec: `webview_flutter` 추가.
- AndroidManifest: `INTERNET` 권한 추가.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과. 기기 실행 확인은 하지 못함.

## 남은 일 · 질문
- 실기기에서 선택 · 가져오기 동작 확인. 데스크톱 웹 검색은 미지원.
