import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String valueText;
  final IconData icon;
  final double currentValue;
  final double? oldValue;
  final Color baseColor;

  const SensorCard({
    super.key,
    required this.title,
    required this.valueText,
    required this.icon,
    required this.currentValue,
    this.oldValue,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    Color valueColor = Colors.white;
    IconData? arrowIcon;

    if (oldValue != null) {
      if (currentValue > oldValue!) {
        valueColor = Colors.greenAccent;
        arrowIcon = Icons.arrow_upward;
      } else if (currentValue < oldValue!) {
        valueColor = Colors.redAccent;
        arrowIcon = Icons.arrow_downward;
      }
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: baseColor, size: 25),
          ),
          const SizedBox(width: 10),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      valueText,
                      style: TextStyle(
                        color: valueColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (arrowIcon != null) ...[
                      const SizedBox(width: 0),
                      Icon(arrowIcon, color: valueColor, size: 24),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
