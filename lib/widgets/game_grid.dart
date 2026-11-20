import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_application_1/tile.dart';

class GameGrid extends StatelessWidget {
  final List<Tile> tiles;
  const GameGrid({super.key, required this.tiles});
  static const double gap = 8;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = constraints.maxWidth;
        double cellSize = (size - 5 * gap) / 4;

        return Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(217, 61, 23, 96),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // static background cells
              ...List.generate(16, (i) {
                int r = i ~/ 4, c = i % 4;
                return Positioned(
                  left: gap + c * (cellSize + gap),
                  top: gap + r * (cellSize + gap),
                  width: cellSize,
                  height: cellSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }),

              // animated tiles
              ...tiles.map(
                (tile) => AnimatedTileWidget(
                  key: ValueKey(tile.id),
                  tile: tile,
                  cellsize: cellSize,
                  gap: gap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AnimatedTileWidget extends StatefulWidget {
  final Tile tile;
  final double cellsize, gap;
  const AnimatedTileWidget({
    super.key,
    required this.cellsize,
    required this.gap,
    required this.tile,
  });
  @override
  State<AnimatedTileWidget> createState() => _AnimatedTileWidgetState();
}

class _AnimatedTileWidgetState extends State<AnimatedTileWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnim;
  late Animation<double> _scaleAnim;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnim =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
        );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedTileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tile.row != widget.tile.row ||
        oldWidget.tile.col != widget.tile.col ||
        oldWidget.tile.merged != widget.tile.merged) {
      _controller.forward(from: 0.0); // restart from beginning
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double fromLeft =
        widget.gap + widget.tile.fromCol * (widget.cellsize + widget.gap);
    double fromTop =
        widget.gap + widget.tile.fromRow * (widget.cellsize + widget.gap);
    double toLeft =
        widget.gap + widget.tile.col * (widget.cellsize + widget.gap);
    double toTop =
        widget.gap + widget.tile.row * (widget.cellsize + widget.gap);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double left = lerpDouble(fromLeft, toLeft, _slideAnim.value)!;
        double top = lerpDouble(fromTop, toTop, _slideAnim.value)!;
        double scale = widget.tile.merged ? _scaleAnim.value : 1.0;
        // show pre-merge value while sliding, merged value when pop starts
        int displayValue = (widget.tile.merged && _controller.value < 0.5)
            ? widget.tile.value ~/ 2
            : widget.tile.value;

        return Positioned(
          left: left,
          top: top,
          width: widget.cellsize,
          height: widget.cellsize,
          child: Transform.scale(
            scale: scale,
            child: _buildTileVisual(displayValue),
          ),
        );
      },
    );
  }

  Widget _buildTileVisual(int value) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          color: _tileColor(value),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Color _tileColor(int value) {
    const colors = {
      2: Color(0xFFE1F5FE),
      4: Color(0xFFE0F2F1),
      8: Color(0xFF81D4FA),
      16: Color(0xFF80CBC4),
      32: Color(0xFF4FC3F7),
      64: Color(0xFF4DB6AC),
      128: Color(0xFF29B6F6),
      256: Color(0xFF26A69A),
      512: Color(0xFFFFFFFF),
      1024: Color(0xFFFFD54F),
      2048: Color(0xFFFFB300),
    };
    return colors[value] ?? const Color(0xFFFFFFFF);
  }
}
