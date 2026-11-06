/// 받은 곡의 파일 태그를 쓴 결과 ([ok]가 false면 쓰지 못했다). [detail]은 실패 이유 같은 진단 글.
class TagNotice {
  const TagNotice({
    required this.title,
    required this.extension,
    required this.ok,
    this.detail = '',
  });

  final String title;
  final String extension;
  final bool ok;
  final String detail;
}
