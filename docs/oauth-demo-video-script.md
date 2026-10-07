# OAuth 인증 시연 영상 시나리오

구글 인증 요청에 첨부하는 영상(YouTube "일부 공개", 3분 안팎, 영어 자막 또는 설명 권장). 화면은 실제 폰(또는 에뮬레이터)을 녹화한다.

1. **앱 소개 (10초):** 앱 이름 Mulo, 하는 일("저장한 음원 재생, 내 유튜브 재생목록에서 곡 가져오기").
2. **동의 화면 (30초):** 재생목록 가져오기 > "내 재생목록" 탭 → 로그인 안내 창 → 허용 → 구글 계정 선택 → **동의 화면 전체**(앱 이름 · 요청 범위 `youtube.readonly`)가 보이게 잠깐 멈춘다. 주소창이 보이는 브라우저 동의 화면이면 client_id가 보이게 한다.
3. **범위 사용 (60초):** 로그인 후 내 재생목록 목록 표시 → 하나를 눌러 곡 목록 표시 → 곡을 골라 가져오기. 이것이 `youtube.readonly`를 쓰는 유일한 기능임을 말한다.
4. **삭제 · 해제 (20초):** 설정 > 계정 > 로그아웃 → 계정 정보가 사라지는 것을 보여 준다. 구글 계정의 앱 권한 페이지(myaccount.google.com/permissions)에서 해제할 수 있다고 언급.
5. 홈페이지와 개인정보처리방침 URL을 마지막에 화면에 띄운다.

범위를 쓰는 이유(인증 요청 입력용, 영어):
"Mulo lets users pick songs from their own YouTube playlists to import into a local music library. It uses the read-only youtube.readonly scope solely to list the user's playlists and the songs in them (playlists.list / playlistItems.list). No data is modified, stored on our servers, shared, or used for ads."
