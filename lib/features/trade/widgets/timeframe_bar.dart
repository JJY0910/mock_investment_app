// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

/// 타임프레임 선택 바 (차트 바로 위)
class TimeframeBar extends StatefulWidget {
  const TimeframeBar({Key? key}) : super(key: key);

  @override
  State<TimeframeBar> createState() => _TimeframeBarState();
}

class _TimeframeBarState extends State<TimeframeBar> {
  String _selectedTimeframe = '1분';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: ['1분', '5분', '15분', '1시간'].map((tf) {
          final isSelected = tf == _selectedTimeframe;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: () => setState(() => _selectedTimeframe = tf),
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected 
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                foregroundColor: isSelected 
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyMedium?.color,
                side: BorderSide(
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Theme.of(context).dividerColor,
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                minimumSize: const Size(56, 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                tf,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
