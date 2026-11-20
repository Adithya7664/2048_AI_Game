import 'package:flutter/material.dart';

class ScoreBoard extends StatelessWidget {
  final int score;
  final int best;
  const ScoreBoard({super.key, required this.score, required this.best});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ScoreBox(label: 'SCORE', value: score),
        _ScoreBox(label: 'Best', value: best),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final int value;
  const _ScoreBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 118, 99, 132),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          Text(
            '$value',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
