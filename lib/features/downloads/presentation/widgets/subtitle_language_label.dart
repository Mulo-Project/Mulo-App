/// 자막 언어 코드(`ko`, `en-US`, `ja-orig` …)를 사람이 읽는 이름으로.
/// `-orig`는 유튜브가 자동 생성한 원어 자막이다. 모르는 코드는 코드 그대로 보인다.
String subtitleLanguageLabel(String code, {required bool korean}) {
  final auto = code.endsWith('-orig');
  final parts = (auto ? code.substring(0, code.length - 5) : code).split(
    RegExp('[-_]'),
  );
  final names = _names[parts.first.toLowerCase()];
  var name = names == null ? code : (korean ? names.$1 : names.$2);
  // 지역이 붙은 코드(`en-US`)는 지역도 보여 같은 이름끼리 구분한다.
  if (names != null && parts.length > 1) name = '$name (${parts[1]})';
  if (!auto) return name;
  return korean ? '$name (자동)' : '$name (auto)';
}

const _names = <String, (String, String)>{
  'ko': ('한국어', 'Korean'),
  'en': ('영어', 'English'),
  'ja': ('일본어', 'Japanese'),
  'zh': ('중국어', 'Chinese'),
  'es': ('스페인어', 'Spanish'),
  'fr': ('프랑스어', 'French'),
  'de': ('독일어', 'German'),
  'pt': ('포르투갈어', 'Portuguese'),
  'ru': ('러시아어', 'Russian'),
  'it': ('이탈리아어', 'Italian'),
  'id': ('인도네시아어', 'Indonesian'),
  'th': ('태국어', 'Thai'),
  'vi': ('베트남어', 'Vietnamese'),
  'ar': ('아랍어', 'Arabic'),
  'hi': ('힌디어', 'Hindi'),
  'tr': ('튀르키예어', 'Turkish'),
};
