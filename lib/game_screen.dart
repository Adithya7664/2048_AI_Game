import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/game_grid.dart';
import 'widgets/score_board.dart';
import 'tile.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';
import 'widgets/ai_overlay.dart';
import 'dart:async';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int score = 0;
  int bestscore = 0;
  List<Tile> tiles = [];
  int _nextId = 0;
  List<Tile>? _previousTiles;
  int _previousScore = 0;
  bool _hasWon = false;
  bool _tutorOn = false;
  bool _showOverlay = false;
  bool _aiPlaying = false;
  Timer? _aiTimer;
  Map<String, dynamic>? _aiData;
  @override
  void initState() {
    super.initState();
    _spawnTile();
    _spawnTile();
    _loadBestScore();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (_aiPlaying) return KeyEventResult.handled;
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) _move('left');
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) _move('right');
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) _move('up');
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) _move('down');
        }
        return KeyEventResult.handled;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 13, 2, 61), // warm light tan (top)
                Color.fromARGB(255, 103, 25, 52), // classic 2048 beige (bottom)
              ],
            ),
          ),

          child: Opacity(
            opacity: 0.8,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '2048',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ScoreBoard(score: score, best: bestscore),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _undo,
                          child: const Text('Undo'),
                        ),
                        ElevatedButton(
                          onPressed: _restart,
                          child: const Text('Restart'),
                        ),
                        ElevatedButton(
                          onPressed: _fetchAndShow,
                          child: const Text('Hint 💡'),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() => _tutorOn = !_tutorOn),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _tutorOn ? Colors.lightBlue : null,
                          ),
                          child: Text(_tutorOn ? 'AI: ON' : 'AI: OFF'),
                        ),
                        ElevatedButton(
                          onPressed: _toggleAiPlay,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _aiPlaying ? Colors.green : null,
                          ),
                          child: Text(_aiPlaying ? 'Stop AI' : 'Watch AI'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: GestureDetector(
                            onVerticalDragEnd: (details) {
                              if (_aiPlaying) return;
                              if (details.primaryVelocity! < 0) _move('up');
                              if (details.primaryVelocity! > 0) _move('down');
                            },
                            onHorizontalDragEnd: (details) {
                              if (_aiPlaying) return;
                              if (details.primaryVelocity! < 0) _move('left');
                              if (details.primaryVelocity! > 0) _move('right');
                            },
                            child: Stack(
                              children: [
                                GameGrid(tiles: tiles),
                                if (_showOverlay && _aiData != null)
                                  AnimatedOpacity(
                                    opacity: _showOverlay ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: AiOverlay(
                                      data: _aiData!,
                                      onDismiss: () =>
                                          setState(() => _showOverlay = false),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _undo() {
    if (_previousTiles == null) return; // nothing to undo
    setState(() {
      tiles = _previousTiles!;
      score = _previousScore;
      _previousTiles = null; // only one level of undo
    });
  }

  // void _restart() {
  //   setState(() {
  //     tiles = [];
  //     score = 0;
  //     _hasWon = false;
  //     _spawnTile();
  //     _spawnTile();
  //   });
  // }

  void _spawnTile() {
    List<(int, int)> occupied = tiles
        .where((t) => !t.isGhost)
        .map((t) => (t.row, t.col))
        .toList();
    List<(int, int)> empty = [];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (!occupied.contains((r, c))) empty.add((r, c));
      }
    }
    if (empty.isEmpty) return;
    empty.shuffle();
    final (r, c) = empty.first;
    tiles.add(
      Tile(
        id: _nextId++,
        value: Random().nextInt(10) == 0 ? 4 : 2,
        row: r,
        col: c,
        fromRow: r,
        fromCol: c,
        merged: false,
      ),
    );
  }

  void _showWInDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 13, 2, 61),
                Color.fromARGB(255, 103, 25, 52),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You WIN!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 118, 99, 132),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'SCORE',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 103, 25, 52),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Colors.white24),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Keep PLaying',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _idAt(int r, int c) =>
      tiles.firstWhere((t) => t.row == r && t.col == c && !t.isGhost).id;

  (List<Tile>, List<int>) _collapseRowWithOrigins(
    List<int> row,
    List<(int, int)> origins,
    int targetRow,
  ) {
    // strip zeros but keep track of origins
    List<(int, (int, int))> tiles = [];
    for (int c = 0; c < 4; c++) {
      if (row[c] != 0) tiles.add((row[c], origins[c]));
    }

    List<Tile> result = [];
    List<int> anchorIds = [];
    int col = 0;

    int i = 0;
    while (i < tiles.length) {
      if (i + 1 < tiles.length && tiles[i].$1 == tiles[i + 1].$1) {
        // merge: use first tile's origin as fromRow/fromCol
        result.add(
          Tile(
            id: _nextId++,
            value: tiles[i].$1 * 2,
            row: targetRow,
            col: col,
            fromRow: tiles[i + 1].$2.$1,
            fromCol: tiles[i + 1].$2.$2,
            merged: true,
          ),
        );
        anchorIds.add(_idAt(tiles[i].$2.$1, tiles[i].$2.$2));
        score += tiles[i].$1 * 2;
        i += 2;
      } else {
        result.add(
          Tile(
            id: _idAt(tiles[i].$2.$1, tiles[i].$2.$2),
            value: tiles[i].$1,
            row: targetRow,
            col: col,
            fromRow: tiles[i].$2.$1,
            fromCol: tiles[i].$2.$2,
            merged: false,
          ),
        );
        i++;
      }
      col++;
    }
    return (result, anchorIds);
  }

  List<List<int>> _rotateClockwise(List<List<int>> g) {
    return List.generate(4, (r) => List.generate(4, (c) => g[3 - c][r]));
  }

  List<List<(int, int)>> _rotatePosClockwise(List<List<(int, int)>> g) {
    return List.generate(4, (r) => List.generate(4, (c) => g[3 - c][r]));
  }

  void _move(String dir) {
    int rotations = {'left': 0, 'up': 3, 'right': 2, 'down': 1}[dir]!;
    List<List<int>> g = List.generate(4, (_) => List.filled(4, 0));
    for (var t in tiles) {
      if (!t.isGhost) g[t.row][t.col] = t.value;
    }
    List<List<(int, int)>> posGrid = List.generate(
      4,
      (r) => List.generate(4, (c) => (r, c)),
    );
    for (int i = 0; i < rotations; i++) {
      g = _rotateClockwise(g);
      posGrid = _rotatePosClockwise(posGrid);
    }

    // collapse each row — ONE call per row
    List<Tile> newTiles = [];
    List<int> anchorIds = [];
    for (int r = 0; r < 4; r++) {
      var (row, ids) = _collapseRowWithOrigins(g[r], posGrid[r], r);
      newTiles.addAll(row);
      anchorIds.addAll(ids);
    }

    // rotate back
    for (int i = 0; i < (4 - rotations) % 4; i++) {
      newTiles = newTiles.map((t) {
        var (r, c) = _rotatePointClockwise(t.row, t.col);
        return Tile(
          id: t.id,
          value: t.value,
          row: r,
          col: c,
          fromRow: t.fromRow,
          fromCol: t.fromCol,
          merged: t.merged,
        );
      }).toList();
    }

    // check if anything changed
    List<List<int>> oldGrid = List.generate(4, (_) => List.filled(4, 0));
    for (var t in tiles) {
      if (!t.isGhost) oldGrid[t.row][t.col] = t.value;
    }
    List<List<int>> newGrid = List.generate(4, (_) => List.filled(4, 0));
    for (var t in newTiles) {
      newGrid[t.row][t.col] = t.value;
    }
    if (oldGrid.toString() != newGrid.toString()) {
      // save state for undo — snapshot of current tiles before the move
      _previousTiles = tiles
          .where((t) => !t.isGhost)
          .map(
            (t) => Tile(
              id: t.id,
              value: t.value,
              row: t.row,
              col: t.col,
              fromRow: t.row,
              fromCol: t.col, // no animation on undo restore
              merged: false,
              isGhost: false,
            ),
          )
          .toList();
      _previousScore = score;

      // ... ghosts + setState as before ...
    }
    if (oldGrid.toString() != newGrid.toString()) {
      // build ghosts from OLD tiles BEFORE setState
      List<Tile> ghosts = tiles
          .where((t) => anchorIds.contains(t.id) && !t.isGhost)
          .map(
            (t) => Tile(
              id: t.id,
              value: t.value,
              row: t.row,
              col: t.col,
              fromRow: t.row,
              fromCol: t.col,
              isGhost: true,
              merged: false,
            ),
          )
          .toList();

      setState(() {
        tiles = [...ghosts, ...newTiles];
        _spawnTile();
        if (score > bestscore) {
          bestscore = score;
          _saveBestScore();
        }
      });

      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) {
          setState(() => tiles.removeWhere((t) => t.isGhost));
          if (!_hasWon && tiles.any((t) => t.value == 2048)) {
            _hasWon = true;
            _showWInDialog();
          }
          if (_isGameOver()) {
            _showGameOverDIalog();
          }
          if (_tutorOn) _fetchAndShow();
        }
      });
    }
  }

  // helper to rotate a single point clockwise
  (int, int) _rotatePointClockwise(int r, int c) => (c, 3 - r);

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bestscore = prefs.getInt('bestscore') ?? 0;
    });
  }

  Future<void> _saveBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bestscore', bestscore);
  }

  bool _isGameOver() {
    List<List<int>> g = List.generate(4, (_) => List.filled(4, 0));
    for (var t in tiles) {
      if (!t.isGhost) g[t.row][t.col] = t.value;
    }
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (g[r][c] == 0) return false; // empty cell exists
        if (c + 1 < 4 && g[r][c] == g[r][c + 1]) {
          return false;
        } // horizontal merge possible
        if (r + 1 < 4 && g[r][c] == g[r + 1][c]) {
          return false;
        } // vertical merge possible
      }
    }
    return true;
  }

  void _showGameOverDIalog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 13, 2, 61),
                Color.fromARGB(255, 103, 25, 52),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No more moves!',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 118, 99, 132),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'SCORE',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 103, 25, 52),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Colors.white24),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _restart();
                  },
                  child: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchAndShow() async {
    final board = List.generate(
      4,
      (r) => List.generate(4, (c) {
        final t = tiles.where((t) => t.row == r && t.col == c && !t.isGhost);
        return t.isEmpty ? 0 : t.first.value;
      }),
    );
    final data = await AiService.suggest(board);
    if (data != null && mounted) {
      setState(() {
        _aiData = data;
        _showOverlay = true;
      });
      Future.delayed(const Duration(milliseconds: 8000), () {
        if (mounted) setState(() => _showOverlay = false);
      });
    }
  }

  void _toggleAiPlay() {
    if (_aiPlaying) {
      _aiTimer?.cancel();
      setState(() => _aiPlaying = false);
    } else {
      setState(() => _aiPlaying = true);
      _aiTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) async {
        if (!mounted || _isGameOver()) {
          _aiTimer?.cancel();
          setState(() => _aiPlaying = false);
          return;
        }
        final board = List.generate(
          4,
          (r) => List.generate(4, (c) {
            final t = tiles.where(
              (t) => t.row == r && t.col == c && !t.isGhost,
            );
            return t.isEmpty ? 0 : t.first.value;
          }),
        );
        final data = await AiService.suggest(board);
        if (data != null && mounted) {
          final dir = data['direction'] as String;
          _move(dir);
          setState(() {
            _aiData = data;
            _showOverlay = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    super.dispose();
  }

  void _restart() {
    _aiTimer?.cancel();
    setState(() {
      _aiPlaying = false;
      tiles = [];
      score = 0;
      _hasWon = false;
      _spawnTile();
      _spawnTile();
    });
  }
}
