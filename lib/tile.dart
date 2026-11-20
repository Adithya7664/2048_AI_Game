class Tile {
  final int id;
  final int value;
  final int row, col;
  final int fromRow, fromCol;
  final bool merged;
  final bool isGhost;

  Tile({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
    required this.fromCol,
    required this.fromRow,
    required this.merged,
    this.isGhost = false,
  });
}
