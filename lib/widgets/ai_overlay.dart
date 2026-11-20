import 'package:flutter/material.dart';

class AiOverlay extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDismiss;

  const AiOverlay({super.key, required this.data, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final direction = data['direction'] as String;
    final explanation = data['explanation'] as String;
    final scores = Map<String, double>.from(
      (data['agent_scores'] as Map).map((k, v) => MapEntry(k, (v as num).toDouble())),
    );

    final arrows = {'left': '←', 'right': '→', 'up': '↑', 'down': '↓'};

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xE60D1B4B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.lightBlue.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AI Tutor',
                    style: TextStyle(
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(Icons.close, color: Colors.white54, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Best move:  ${arrows[direction]} ${direction.toUpperCase()}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(explanation,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            ...scores.entries.map((e) => _ConfidenceRow(
                  label: '${arrows[e.key]} ${e.key}',
                  value: e.value,
                  isTop: e.key == direction,
                )),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTop;

  const _ConfidenceRow(
      {required this.label, required this.value, required this.isTop});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: TextStyle(
                    color: isTop ? Colors.lightBlue : Colors.white54,
                    fontSize: 12,
                    fontWeight:
                        isTop ? FontWeight.bold : FontWeight.normal)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(
                    isTop ? Colors.lightBlue : Colors.blueGrey),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(value * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                  color: isTop ? Colors.lightBlue : Colors.white54,
                  fontSize: 12)),
        ],
      ),
    );
  }
}