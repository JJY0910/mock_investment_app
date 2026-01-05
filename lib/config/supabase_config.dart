// Supabase 연동 설정
class SupabaseConfig {
  // Supabase 프로젝트 URL
  static const String supabaseUrl = 'https://jvepiawctkyyqttzhlgv.supabase.co';
  
  // Supabase Anon Key (공개 키)
  static const String supabaseAnonKey = 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2ZXBpYXdjdGt5eXF0dHpobGd2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY1OTczNDYsImV4cCI6MjA1MjE3MzM0Nn0.sb_publishable_3z5wPmYDZRJOqTSFUVmIpA_s7SfYWs_';
  
  // 초기화 완료 여부 플래그
  static bool _initialized = false;
  
  // Supabase 클라이언트 초기화 여부 확인
  static bool get isInitialized => _initialized;
  
  // 초기화 플래그 설정
  static void setInitialized() {
    _initialized = true;
  }
}
