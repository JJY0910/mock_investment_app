import 'package:flutter/material.dart';
import '../services/disclaimer_service.dart';

class DisclaimerDialog extends StatelessWidget {
  const DisclaimerDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 뒤로가기 방지
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('모의투자 고지', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('본 서비스는 학습 및 테스트를 위한 모의투자(가상거래) 플랫폼입니다.'),
            SizedBox(height: 12),
            Text('• 실제 자금의 입금/출금 및 실제 거래 기능은 제공하지 않습니다.'),
            SizedBox(height: 8),
            Text('• 제공되는 시세 데이터는 참고용이며, 정확성을 보장하지 않습니다.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await DisclaimerService.setAccepted(true);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('동의하고 시작', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
