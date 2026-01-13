/// 사용자 입력 검증 및 파싱 유틸리티
class InputParsers {
  /// KRW 입력 파싱
  /// 콤마, 공백 제거 후 정수 변환
  /// 실패 시(음수, NaN, 비숫자) null 반환
  static int? parseKrwInput(String input) {
    if (input.isEmpty) return null;
    
    // 콤마, 공백 제거
    final cleaned = input.replaceAll(',', '').replaceAll(' ', '');
    
    // 비숫자 포함 체크 (정규식: 숫자만 허용)
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return null;
    }

    try {
      final value = int.parse(cleaned);
      if (value < 0) return null;
      return value;
    } catch (e) {
      return null;
    }
  }

  /// Double 입력 파싱 (수량 등)
  /// 콤마, 공백 제거
  /// 실패 시 null 반환
  static double? parseDoubleSafe(String input) {
    if (input.isEmpty) return null;
    
    final cleaned = input.replaceAll(',', '').replaceAll(' ', '');
    
    try {
      final value = double.parse(cleaned);
      if (value.isNaN || value.isInfinite || value < 0) return null;
      return value;
    } catch (e) {
      return null;
    }
  }
}
