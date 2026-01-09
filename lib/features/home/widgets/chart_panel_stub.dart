import 'package:flutter/material.dart';

/// 차트 패널 (비웹 플랫폼용 Stub)
class ChartPanel extends StatelessWidget {
  const ChartPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.web, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chart is available on Web only',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
