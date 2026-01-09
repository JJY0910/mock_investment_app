// Supabase 연동 설정
class SupabaseConfig {
  // Supabase 프로젝트 URL
  static const String supabaseUrl = 'https://jvepiawctkyyqttzhlgv.supabase.co';
  
  // Supabase Publishable Key (Flutter Web에서는 publishable key 사용 필수)
  static const String supabaseAnonKey = 'sb_publishable_3z5wPmYDZRJOqTSFUVmIpA_s7SfYWs_';
  
  // 초기화 완료 여부 플래그
  static bool _initialized = false;
  
  // Supabase 클라이언트 초기화 여부 확인
  static bool get isInitialized => _initialized;
  
  // 초기화 플래그 설정
  static void setInitialized() {
    _initialized = true;
  }
}
