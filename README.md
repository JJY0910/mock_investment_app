# 🚀 모의 투자 트레이더 (Mock Investment App)

Flutter Web 기반의 수익형 모의 투자 PWA입니다. 실시간 주식 및 암호화폐 시세 데이터로 모의 매매를 경험하고, 광고 시청을 통해 잔고를 리셋할 수 있습니다.

## ✨ 주요 기능

- 🏦 **초기 자산 1억 원** - 모든 신규 유저에게 가상 자산 1억 원 제공
- 📊 **실시간 시세 연동** - Yahoo Finance (주식) + Upbit API (암호화폐)
- 📱 **반응형 디자인** - 모바일/데스크톱 최적화 레이아웃
- 🎬 **광고 리셋 기능** - 잔고 1억 원 미만 시 광고 시청으로 리셋 가능
- 🏆 **고수 랭킹** - 상위 50% 트레이더 실시간 포지션 공유 (향후 구현)
- 💻 **PWA 지원** - 홈 화면 추가 시 네이티브 앱처럼 동작

## 📋 시작 전 준비사항

### 1. Flutter 설치 확인

이 프로젝트를 실행하려면 Flutter SDK가 필요합니다. 아래 명령어로 설치 여부를 확인하세요:

```powershell
flutter --version
```

Flutter가 설치되어 있지 않다면 [공식 문서](https://docs.flutter.dev/get-started/install)를 참조하여 설치해주세요.

### 2. Supabase 데이터베이스 설정

프로젝트 루트에 있는 `supabase_schema.sql` 파일을 Supabase 콘솔에서 실행해주세요:

1. [Supabase 콘솔](https://jvepiawctkyyqttzhlgv.supabase.co) 접속
2. **SQL Editor** 메뉴로 이동
3. `supabase_schema.sql` 파일의 내용을 복사하여 붙여넣기
4. **Run** 버튼 클릭하여 실행

이 스크립트는 다음 테이블을 생성합니다:
- `users` - 사용자 정보
- `positions` - 보유 자산 (포지션)
- `transactions` - 거래 내역
- `ad_rewards` - 광고 리워드 기록

## 🛠️ 프로젝트 설정 및 실행

### 1. 의존성 패키지 설치

프로젝트 디렉토리로 이동 후 패키지를 설치합니다:

```powershell
cd C:\Users\abcde\.gemini\antigravity\scratch\mock_investment_app
flutter pub get
```

### 2. 개발 서버 실행

```powershell
flutter run -d chrome
```

또는 엣지 브라우저로 실행:

```powershell
flutter run -d edge
```

### 3. 프로덕션 빌드 (배포용)

```powershell
flutter build web
```

빌드된 파일은 `build/web` 폴더에 생성됩니다.

## 📁 프로젝트 구조

```
mock_investment_app/
├── lib/
│   ├── main.dart                    # 앱 진입점 (Supabase 초기화)
│   ├── config/
│   │   ├── supabase_config.dart     # Supabase 연동 설정
│   │   └── constants.dart            # 앱 전역 상수
│   ├── services/
│   │   └── price_service.dart       # 시세 데이터 Fetching 서비스
│   ├── providers/
│   │   └── price_provider.dart      # 시세 데이터 상태 관리
│   ├── screens/
│   │   └── home_screen.dart         # 메인 대시보드 화면
│   └── widgets/
│       └── responsive_layout.dart   # 반응형 레이아웃 위젯
├── web/
│   ├── index.html                   # PWA HTML 엔트리포인트
│   └── manifest.json                # PWA 매니페스트
├── pubspec.yaml                     # Flutter 패키지 의존성
└── supabase_schema.sql              # Supabase DB 스키마 스크립트
```

## 🎨 주요 화면 설명

### 메인 대시보드 (Home Screen)

#### 데스크톱 (3단 레이아웃)
- **왼쪽 (40%)** - 잔고 카드 + 차트 영역 (향후 구현)
- **중앙 (30%)** - 실시간 시세 리스트
- **오른쪽 (30%)** - 상위 50% 고수 랭킹 (향후 구현)

#### 모바일 (세로 스크롤)
- 잔고 카드
- 실시간 시세 리스트
- 고수 랭킹 미리보기

### 광고 리셋 기능

- 우측 하단 FAB 버튼을 클릭하면 광고 리셋 다이얼로그가 표시됩니다
- **현재는 Google AdSense Placeholder가 표시됩니다**
- 실제 광고는 AdSense 승인 후 스크립트를 `web/index.html`에 삽입하면 작동합니다

## 🔗 API 연동 정보

### 1. Yahoo Finance API (주식 시세)
- **엔드포인트**: `https://query1.finance.yahoo.com/v8/finance/chart/{symbol}`
- **지원 종목**: SQQQ, TQQQ 등 미국 주식
- **업데이트 주기**: 10초

### 2. Upbit API (암호화폐 시세)
- **엔드포인트**: `https://api.upbit.com/v1/ticker?markets=KRW-{symbol}`
- **지원 종목**: XRP, BTC 등 원화 마켓 암호화폐
- **업데이트 주기**: 10초

## 🎬 Google AdSense 연동 방법 (선택사항)

실제 광고 수익화를 원하신다면 다음 단계를 따르세요:

1. [Google AdSense](https://www.google.com/adsense) 가입 및 승인 받기
2. AdSense 대시보드에서 광고 단위 생성
3. 생성된 광고 코드를 `web/index.html`의 `<head>` 태그에 삽입
4. `lib/screens/home_screen.dart`의 `_showAdResetDialog()` 함수 내 Placeholder를 실제 광고 div로 교체

## 📱 PWA 설치 테스트

### 데스크톱 (Chrome)
1. 개발 서버 실행 후 Chrome에서 접속
2. 주소창 오른쪽의 "설치" 아이콘 클릭
3. 앱 설치 확인

### 모바일 (iOS Safari)
1. Safari에서 앱 접속
2. 공유 버튼 → "홈 화면에 추가"
3. 홈 화면에서 앱 아이콘 확인

## 🚧 향후 구현 예정 기능

- [ ] 실제 매수/매도 기능
- [ ] 포트폴리오 수익률 계산
- [ ] 거래 내역 페이지
- [ ] 차트 시각화 (fl_chart 사용)
- [ ] 사용자 인증 (Supabase Auth)
- [ ] 고수 랭킹 집계 로직
- [ ] 실제 Google AdSense 광고 연동

## ⚠️ 주의사항

- Yahoo Finance API는 무료이지만 호출 제한이 있을 수 있습니다
- Upbit API도 분당 호출 제한이 있으므로 과도한 요청은 피하세요
- 현재 광고 리셋 기능은 시뮬레이션입니다 (실제 잔고 변경 없음)
- Supabase Anon Key는 공개 키이므로 클라이언트에 포함되어도 안전하지만, Row Level Security (RLS) 정책을 반드시 확인하세요

## 📞 문의 및 지원

이 프로젝트는 Flutter Web 기반의 마스터 아키텍처 가이드를 따라 구축되었습니다.

---

**Made with ❤️ by Antigravity Agent**
