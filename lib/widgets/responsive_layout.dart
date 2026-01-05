import 'package:flutter/material.dart';

// 반응형 레이아웃 Wrapper
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;   // 모바일 레이아웃
  final Widget desktop;  // 데스크톱 레이아웃

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    required this.desktop,
  }) : super(key: key);

  // 모바일/데스크톱 구분 기준: 768px
  static const double mobileBreakpoint = 768.0;

  // 현재 화면이 모바일인지 확인하는 헬퍼 메서드
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return mobile; // 모바일 뷰
        } else {
          return desktop; // 데스크톱 뷰
        }
      },
    );
  }
}
