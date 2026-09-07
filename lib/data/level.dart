enum ObstacleKind { staticWall, movingWall, rotatingBlade, laser, fallingBlock, disappearing, swinging, dangerousFloor }

class ObstacleDefinition {
  const ObstacleDefinition(this.kind, this.x, this.z, {this.width = 1.4, this.depth = 1.2, this.speed = 1});

  final ObstacleKind kind;
  final double x;
  final double z;
  final double width;
  final double depth;
  final double speed;
}

class LevelDefinition {
  const LevelDefinition({
    required this.id,
    required this.title,
    required this.zone,
    required this.targetSeconds,
    required this.length,
    required this.obstacles,
    this.pathWidth = 5.2,
  });

  final int id;
  final String title;
  final String zone;
  final int targetSeconds;
  final double length;
  final double pathWidth;
  final List<ObstacleDefinition> obstacles;

  String get difficulty => id <= 3 ? 'TRAINING' : id <= 6 ? 'INDUSTRIAL' : id <= 9 ? 'NEON' : id <= 12 ? 'UNSTABLE' : 'CORE';
  int get hazardCount => obstacles.length;
}

List<LevelDefinition> seedLevels() {
  const s = ObstacleKind.staticWall;
  const m = ObstacleKind.movingWall;
  const r = ObstacleKind.rotatingBlade;
  const l = ObstacleKind.laser;
  const f = ObstacleKind.fallingBlock;
  const d = ObstacleKind.disappearing;
  const w = ObstacleKind.swinging;
  const floor = ObstacleKind.dangerousFloor;
  return [
    const LevelDefinition(id: 1, title: 'FIRST SIGNAL', zone: 'Training Facility', targetSeconds: 42, length: 38, obstacles: [ObstacleDefinition(s, 0, 11), ObstacleDefinition(s, -1.8, 22), ObstacleDefinition(s, 1.6, 30)]),
    const LevelDefinition(id: 2, title: 'SHIFT VECTOR', zone: 'Training Facility', targetSeconds: 48, length: 43, obstacles: [ObstacleDefinition(m, 0, 10, speed: 1.2), ObstacleDefinition(m, -1.5, 20, speed: 1.5), ObstacleDefinition(s, 1.5, 32)]),
    const LevelDefinition(id: 3, title: 'NARROW TRACE', zone: 'Training Facility', targetSeconds: 53, length: 48, pathWidth: 3.8, obstacles: [ObstacleDefinition(s, 1.1, 10), ObstacleDefinition(l, -1.1, 17), ObstacleDefinition(m, 0, 27, speed: 1.7), ObstacleDefinition(s, -1, 39)]),
    const LevelDefinition(id: 4, title: 'IRON ROTATION', zone: 'Industrial Ring', targetSeconds: 58, length: 53, obstacles: [ObstacleDefinition(r, 0, 10, speed: 1.2), ObstacleDefinition(s, -1.7, 20), ObstacleDefinition(r, 0, 31, speed: 1.5), ObstacleDefinition(s, 1.6, 44)]),
    const LevelDefinition(id: 5, title: 'MOVING FOUNDRY', zone: 'Industrial Ring', targetSeconds: 64, length: 59, pathWidth: 4.4, obstacles: [ObstacleDefinition(m, -1.4, 9, speed: 1.5), ObstacleDefinition(r, 1.2, 19), ObstacleDefinition(m, 1.5, 30, speed: 1.9), ObstacleDefinition(r, -1, 43, speed: 1.8), ObstacleDefinition(s, 0, 53)]),
    const LevelDefinition(id: 6, title: 'BURN WINDOW', zone: 'Industrial Ring', targetSeconds: 70, length: 65, obstacles: [ObstacleDefinition(floor, 0, 10, width: 2), ObstacleDefinition(l, 0, 20, speed: 1.4), ObstacleDefinition(floor, -1.3, 31, width: 1.8), ObstacleDefinition(r, 1.3, 43), ObstacleDefinition(floor, 0, 56, width: 2)]),
    const LevelDefinition(id: 7, title: 'SWING STATE', zone: 'Neon Sector', targetSeconds: 75, length: 70, pathWidth: 4.4, obstacles: [ObstacleDefinition(w, 0, 10, speed: 1.3), ObstacleDefinition(s, -1.6, 21), ObstacleDefinition(w, 0, 32, speed: 1.6), ObstacleDefinition(m, 1.4, 44, speed: 2), ObstacleDefinition(s, -1.4, 59)]),
    const LevelDefinition(id: 8, title: 'LASER LATTICE', zone: 'Neon Sector', targetSeconds: 80, length: 75, pathWidth: 4.6, obstacles: [ObstacleDefinition(l, 0, 10, speed: 1.4), ObstacleDefinition(l, 1.5, 21, speed: 1.8), ObstacleDefinition(r, -1.4, 34, speed: 2), ObstacleDefinition(l, 0, 47, speed: 2.1), ObstacleDefinition(s, 1.5, 62)]),
    const LevelDefinition(id: 9, title: 'VANISHING RUN', zone: 'Neon Sector', targetSeconds: 86, length: 80, pathWidth: 4.1, obstacles: [ObstacleDefinition(d, 0, 10), ObstacleDefinition(d, -1.5, 19), ObstacleDefinition(w, 1.4, 29, speed: 1.8), ObstacleDefinition(d, 0, 41), ObstacleDefinition(r, -1.4, 55), ObstacleDefinition(d, 1.2, 69)]),
    const LevelDefinition(id: 10, title: 'ENERGY DESCENT', zone: 'Unstable Facility', targetSeconds: 91, length: 85, pathWidth: 3.9, obstacles: [ObstacleDefinition(l, 0, 10, speed: 2), ObstacleDefinition(m, -1.3, 20, speed: 2.1), ObstacleDefinition(d, 1.2, 31), ObstacleDefinition(r, 0, 43, speed: 2.2), ObstacleDefinition(l, -1.2, 56, speed: 2.2), ObstacleDefinition(m, 1.2, 70, speed: 2.4)]),
    const LevelDefinition(id: 11, title: 'RAPID SEQUENCE', zone: 'Unstable Facility', targetSeconds: 97, length: 91, pathWidth: 3.7, obstacles: [ObstacleDefinition(m, 0, 9, speed: 2.4), ObstacleDefinition(r, -1.2, 18, speed: 2.5), ObstacleDefinition(l, 1.2, 28, speed: 2.5), ObstacleDefinition(w, 0, 39, speed: 2.2), ObstacleDefinition(m, -1.3, 52, speed: 2.8), ObstacleDefinition(r, 1.2, 67, speed: 2.8), ObstacleDefinition(l, 0, 80, speed: 2.7)]),
    const LevelDefinition(id: 12, title: 'FALLING LOGIC', zone: 'Unstable Facility', targetSeconds: 104, length: 98, pathWidth: 3.8, obstacles: [ObstacleDefinition(f, -1.3, 10, speed: 1.6), ObstacleDefinition(d, 1.2, 21), ObstacleDefinition(f, 0, 33, speed: 1.9), ObstacleDefinition(l, -1.2, 45, speed: 2.4), ObstacleDefinition(f, 1.2, 58, speed: 2.1), ObstacleDefinition(d, 0, 72), ObstacleDefinition(r, -1.2, 87, speed: 2.8)]),
    const LevelDefinition(id: 13, title: 'CONVERGENCE', zone: 'DarkTrace Core', targetSeconds: 111, length: 106, pathWidth: 3.6, obstacles: [ObstacleDefinition(m, 0, 10, speed: 2.5), ObstacleDefinition(l, -1.2, 20, speed: 2.6), ObstacleDefinition(w, 1.2, 31, speed: 2.5), ObstacleDefinition(f, 0, 43, speed: 2), ObstacleDefinition(r, -1.2, 57, speed: 3), ObstacleDefinition(d, 1.2, 70), ObstacleDefinition(m, 0, 84, speed: 3), ObstacleDefinition(l, -1.1, 98, speed: 2.8)]),
    const LevelDefinition(id: 14, title: 'NO SAFE ANGLE', zone: 'DarkTrace Core', targetSeconds: 118, length: 114, pathWidth: 3.4, obstacles: [ObstacleDefinition(floor, 0, 10, width: 1.8), ObstacleDefinition(r, -1.1, 19, speed: 3), ObstacleDefinition(l, 1.1, 30, speed: 3), ObstacleDefinition(m, 0, 42, speed: 3.2), ObstacleDefinition(w, -1.1, 55, speed: 3), ObstacleDefinition(d, 1, 68), ObstacleDefinition(f, 0, 80, speed: 2.7), ObstacleDefinition(r, -1.1, 94, speed: 3.4), ObstacleDefinition(l, 1, 106, speed: 3.2)]),
    const LevelDefinition(id: 15, title: 'THE DARKTRACE', zone: 'DarkTrace Core', targetSeconds: 128, length: 124, pathWidth: 3.2, obstacles: [ObstacleDefinition(m, 0, 9, speed: 3), ObstacleDefinition(r, -1, 18, speed: 3.4), ObstacleDefinition(l, 1, 28, speed: 3.2), ObstacleDefinition(f, 0, 39, speed: 2.8), ObstacleDefinition(d, -1, 51), ObstacleDefinition(w, 1, 62, speed: 3.2), ObstacleDefinition(m, 0, 74, speed: 3.6), ObstacleDefinition(l, -1, 86, speed: 3.5), ObstacleDefinition(r, 1, 98, speed: 3.7), ObstacleDefinition(f, 0, 110, speed: 3), ObstacleDefinition(d, 0, 119)]),
  ];
}
