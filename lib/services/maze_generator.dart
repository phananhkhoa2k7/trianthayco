import 'dart:math';

enum Dir { up, right, down, left }

extension DirX on Dir {
  Dir get opposite => switch (this) {
        Dir.up => Dir.down,
        Dir.right => Dir.left,
        Dir.down => Dir.up,
        Dir.left => Dir.right,
      };
}

/// Một ô mê cung, true = còn tường ở cạnh đó.
class MazeCell {
  bool top = true, right = true, bottom = true, left = true;
  bool visited = false;

  bool hasWall(Dir d) => switch (d) {
        Dir.up => top,
        Dir.right => right,
        Dir.down => bottom,
        Dir.left => left,
      };

  void open(Dir d) {
    switch (d) {
      case Dir.up:
        top = false;
      case Dir.right:
        right = false;
      case Dir.down:
        bottom = false;
      case Dir.left:
        left = false;
    }
  }
}

class Maze {
  final int rows, cols;
  final List<List<MazeCell>> cells;
  final Point<int> start;
  final Point<int> exit;
  final Set<Point<int>> flowers; // hoa còn lại trong mê cung
  final Set<Point<int>> letters; // thư còn lại trong mê cung

  Maze({
    required this.rows,
    required this.cols,
    required this.cells,
    required this.start,
    required this.exit,
    required this.flowers,
    required this.letters,
  });

  bool inside(Point<int> p) => p.x >= 0 && p.y >= 0 && p.x < cols && p.y < rows;

  Point<int> step(Point<int> p, Dir d) => switch (d) {
        Dir.up => Point<int>(p.x, p.y - 1),
        Dir.right => Point<int>(p.x + 1, p.y),
        Dir.down => Point<int>(p.x, p.y + 1),
        Dir.left => Point<int>(p.x - 1, p.y),
      };

  /// Có đi được từ ô p theo hướng d không (không bị tường chắn).
  bool canMove(Point<int> p, Dir d) =>
      inside(step(p, d)) && !cells[p.y][p.x].hasWall(d);
}

class MazeGenerator {
  /// Sinh mê cung "hoàn hảo" bằng DFS (recursive backtracker, dùng stack).
  /// Điểm bắt đầu ở góc trên trái, cửa ra ở góc dưới phải.
  /// Hoa và thư được rải ngẫu nhiên vào các ô khác nhau (trừ ô đầu/cuối).
  static Maze generate({
    required int rows,
    required int cols,
    required int flowerCount,
    required int letterCount,
    Random? random,
  }) {
    final rng = random ?? Random();
    final cells =
        List.generate(rows, (_) => List.generate(cols, (_) => MazeCell()));
    final maze = Maze(
      rows: rows,
      cols: cols,
      cells: cells,
      start: const Point<int>(0, 0),
      exit: Point<int>(cols - 1, rows - 1),
      flowers: {},
      letters: {},
    );

    final stack = <Point<int>>[maze.start];
    cells[0][0].visited = true;
    while (stack.isNotEmpty) {
      final cur = stack.last;
      final options = Dir.values.where((d) {
        final n = maze.step(cur, d);
        return maze.inside(n) && !cells[n.y][n.x].visited;
      }).toList();
      if (options.isEmpty) {
        stack.removeLast(); // hết đường -> quay lui
        continue;
      }
      final d = options[rng.nextInt(options.length)];
      final next = maze.step(cur, d);
      cells[cur.y][cur.x].open(d); // đục tường giữa 2 ô
      cells[next.y][next.x].open(d.opposite);
      cells[next.y][next.x].visited = true;
      stack.add(next);
    }

    // Rải vật phẩm ngẫu nhiên vào các ô khác nhau.
    final free = <Point<int>>[
      for (var y = 0; y < rows; y++)
        for (var x = 0; x < cols; x++)
          if (Point<int>(x, y) != maze.start && Point<int>(x, y) != maze.exit)
            Point<int>(x, y),
    ]..shuffle(rng);
    maze.flowers.addAll(free.take(flowerCount));
    maze.letters.addAll(free.skip(flowerCount).take(letterCount));
    return maze;
  }
}
