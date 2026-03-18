/// Legacy template type — kept for any routes still referencing win flow.
class Score {
  Score({required this.score, required this.duration});

  final int score;
  final Duration duration;

  String get formattedTime {
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
