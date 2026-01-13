import 'package:flutter/material.dart';
import '../widgets/app_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '앱 정보 및 안내',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildSection(
                      context,
                      title: '서비스 안내',
                      content: 
                        '본 서비스는 실제 자산이 오가지 않는 "모의투자(가상거래)" 시뮬레이터입니다.\n'
                        '체결되는 모든 거래는 가상의 데이터이며, 실제 금융 시스템과 무관합니다.\n'
                        '제공되는 가상화폐 시세는 외부 API를 참조하나, 지연되거나 부정확할 수 있습니다.',
                      icon: Icons.info_outline,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      context,
                      title: '데이터 저장 및 관리',
                      content:
                        '본 앱은 서버에 사용자의 거래 기록을 저장하지 않습니다.\n'
                        '모든 투자 내역과 지갑 데이터는 현재 사용 중인 기기(브라우저)의 로컬 저장소(LocalStorage/SharedPreferences)에만 저장됩니다.\n\n'
                        '따라서 브라우저 캐시를 삭제하거나 기기를 변경할 경우 데이터가 초기화될 수 있습니다.',
                      icon: Icons.storage,
                    ),

                    const SizedBox(height: 24),

                    _buildSection(
                      context,
                      title: '개인정보 처리방침',
                      content:
                        '본 앱은 회원가입이나 로그인을 요구하지 않으며, 사용자의 이름, 이메일, 연락처 등 어떠한 개인정보도 수집하지 않습니다.',
                      icon: Icons.privacy_tip_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String content, required IconData icon}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14, 
                height: 1.5,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
