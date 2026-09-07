import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';

import '../data/level.dart';

enum AttemptState { running, failed, complete }

class DarkTraceGame extends FlameGame {
  DarkTraceGame(this.level, {required this.onFailed, required this.onComplete});

  final LevelDefinition level;
  final void Function(String reason) onFailed;
  final void Function(int score, double time) onComplete;

  AttemptState state = AttemptState.running;
  double playerX = 0;
  double playerZ = 0;
  double playerY = 0;
  double cameraZ = 0;
  double elapsed = 0;
  double jumpVelocity = 0;
  double inputX = 0;
  double inputY = 0;
  bool jumpQueued = false;
  bool _reported = false;

  @override
  Color backgroundColor() => const Color(0xFF050912);

  void setMove(double x, double y) {
    inputX = x.clamp(-1, 1).toDouble();
    inputY = y.clamp(-1, 1).toDouble();
  }

  void jump() {
    if (state == AttemptState.running && playerY == 0) jumpQueued = true;
  }

  void reset() {
    state = AttemptState.running;
    playerX = 0;
    playerZ = 0;
    playerY = 0;
    cameraZ = 0;
    elapsed = 0;
    jumpVelocity = 0;
    jumpQueued = false;
    _reported = false;
  }

  @override
  void update(double dt) {
    if (state != AttemptState.running) return;
    super.update(dt);
    final delta = dt.clamp(0, .05);
    elapsed += delta;
    final speed = 5.2 + level.id * .12;
    playerX += inputX * delta * (3.8 + level.id * .04);
    playerZ += (0.45 + inputY.clamp(0, 1) * .65) * speed * delta;
    playerX = playerX.clamp(-level.pathWidth / 2 + .45, level.pathWidth / 2 - .45).toDouble();
    if (jumpQueued) {
      jumpVelocity = 6.4;
      jumpQueued = false;
    }
    if (playerY > 0 || jumpVelocity > 0) {
      playerY += jumpVelocity * delta;
      jumpVelocity -= 16 * delta;
      if (playerY <= 0) {
        playerY = 0;
        jumpVelocity = 0;
      }
    }
    cameraZ += (playerZ - cameraZ) * math.min(1, delta * 5);
    for (final obstacle in level.obstacles) {
      if (_hits(obstacle)) {
        fail(_reason(obstacle.kind));
        return;
      }
    }
    if (playerZ >= level.length) complete();
  }

  bool _hits(ObstacleDefinition obstacle) {
    final distance = (playerZ - obstacle.z).abs();
    if (distance > obstacle.depth * .62) return false;
    if (obstacle.kind == ObstacleKind.dangerousFloor) return playerY < .45 && playerX.abs() < obstacle.width;
    if (obstacle.kind == ObstacleKind.laser && !_active(obstacle, 1.8, .9)) return false;
    if (obstacle.kind == ObstacleKind.disappearing && !_active(obstacle, 2.6, 1.7)) return false;
    if (obstacle.kind == ObstacleKind.fallingBlock && !_active(obstacle, 3.2, 1.9)) return false;
    final offset = _obstacleX(obstacle) - playerX;
    final clearance = obstacle.kind == ObstacleKind.rotatingBlade || obstacle.kind == ObstacleKind.swinging ? 1.1 : .75;
    return offset.abs() < obstacle.width * .5 + clearance && playerY < (obstacle.kind == ObstacleKind.laser ? .75 : 1.25);
  }

  bool _active(ObstacleDefinition obstacle, double period, double activeFor) => ((elapsed + obstacle.z * .13) % period) < activeFor;

  double _obstacleX(ObstacleDefinition obstacle) {
    final phase = elapsed * obstacle.speed + obstacle.z * .2;
    switch (obstacle.kind) {
      case ObstacleKind.movingWall:
        return obstacle.x + math.sin(phase) * (level.pathWidth * .34);
      case ObstacleKind.swinging:
        return obstacle.x + math.sin(phase) * 1.4;
      default:
        return obstacle.x;
    }
  }

  String _reason(ObstacleKind kind) => switch (kind) {
        ObstacleKind.laser => 'Laser timing missed',
        ObstacleKind.fallingBlock => 'Falling hazard impact',
        ObstacleKind.dangerousFloor => 'Unsafe floor',
        ObstacleKind.rotatingBlade => 'Rotating blade impact',
        ObstacleKind.swinging => 'Swinging obstacle impact',
        ObstacleKind.disappearing => 'Platform vanished',
        _ => 'Obstacle impact',
      };

  void fail(String reason) {
    if (_reported || state != AttemptState.running) return;
    state = AttemptState.failed;
    _reported = true;
    onFailed(reason);
  }

  void complete() {
    if (_reported || state != AttemptState.running) return;
    state = AttemptState.complete;
    _reported = true;
    final remaining = math.max(0, level.targetSeconds - elapsed);
    final score = (1000 + remaining * 32 + level.id * 75).round();
    onComplete(score, elapsed);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final width = size.x;
    final height = size.y;
    final horizon = height * .27;
    final palette = _palette(level.id);
    final road = Paint()..color = palette.road;
    final side = Paint()..color = palette.side;
    canvas.drawRect(Rect.fromLTWH(0, horizon, width, height - horizon), Paint()..color = palette.sky);
    final roadTop = _screenY(horizon, 22);
    canvas.drawPath(Path()..moveTo(width * .44, roadTop)..lineTo(width * .56, roadTop)..lineTo(width * .94, height)..lineTo(width * .06, height)..close(), road);
    for (var index = 0; index < 9; index++) {
      final z = cameraZ + 5 + index * 5;
      final y = _screenY(horizon, z - cameraZ);
      final scale = _scale(z - cameraZ);
      final lane = width * .5;
      canvas.drawRect(Rect.fromCenter(center: Offset(lane, y), width: width * .02 * scale, height: 2 + scale * 3), side);
    }
    for (final obstacle in level.obstacles.reversed) {
      final relative = obstacle.z - cameraZ;
      if (relative < 1 || relative > 125) continue;
      _renderObstacle(canvas, obstacle, width, horizon, palette);
    }
    _renderFinish(canvas, width, horizon, palette);
    _renderPlayer(canvas, width, horizon, palette);
  }

  double _scale(double relative) => (1 / (1 + relative * .055)).clamp(.12, 1.0);
  double _screenY(double horizon, double relative) => horizon + (size.y - horizon) * _scale(relative);
  double _screenX(double x, double relative) => size.x * .5 + x * size.x * .12 * _scale(relative);

  void _renderObstacle(Canvas canvas, ObstacleDefinition obstacle, double width, double horizon, _Palette palette) {
    final relative = obstacle.z - cameraZ;
    final scale = _scale(relative);
    final center = Offset(_screenX(_obstacleX(obstacle), relative), _screenY(horizon, relative));
    final obstacleColor = _activeColor(obstacle, palette);
    final w = width * .11 * obstacle.width * scale;
    final h = width * .07 * scale;
    if (obstacle.kind == ObstacleKind.laser) {
      final beam = Paint()..color = obstacleColor..strokeWidth = math.max(2, 8 * scale);
      canvas.drawLine(Offset(center.dx - w * 3, center.dy - h), Offset(center.dx + w * 3, center.dy - h), beam);
      canvas.drawCircle(Offset(center.dx - w * 3, center.dy - h), 5 * scale, Paint()..color = palette.glow);
      canvas.drawCircle(Offset(center.dx + w * 3, center.dy - h), 5 * scale, Paint()..color = palette.glow);
      return;
    }
    final shadow = Paint()..color = const Color(0x55000000);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy + h * .6), width: w * 2, height: h * .5), shadow);
    final body = Path()..moveTo(center.dx - w, center.dy)..lineTo(center.dx - w * .72, center.dy - h * 1.4)..lineTo(center.dx + w * .72, center.dy - h * 1.4)..lineTo(center.dx + w, center.dy)..close();
    canvas.drawPath(body, Paint()..color = obstacleColor);
    canvas.drawPath(Path()..moveTo(center.dx - w, center.dy)..lineTo(center.dx - w * .72, center.dy - h * 1.4)..lineTo(center.dx - w * .45, center.dy - h * 1.8)..lineTo(center.dx - w * 1.1, center.dy - h * .35)..close(), Paint()..color = palette.dark);
    if (obstacle.kind == ObstacleKind.rotatingBlade || obstacle.kind == ObstacleKind.swinging) {
      final blade = Paint()..color = palette.glow..strokeWidth = math.max(2, scale * 5)..strokeCap = StrokeCap.round;
      final angle = elapsed * obstacle.speed;
      canvas.drawLine(center, center + Offset(math.cos(angle) * w * 2.4, math.sin(angle) * h * 2.4), blade);
      canvas.drawLine(center, center + Offset(-math.cos(angle) * w * 2.4, -math.sin(angle) * h * 2.4), blade);
    }
  }

  Color _activeColor(ObstacleDefinition obstacle, _Palette palette) {
    final active = obstacle.kind != ObstacleKind.laser || _active(obstacle, 1.8, .9);
    return active ? palette.danger : palette.safe;
  }

  void _renderFinish(Canvas canvas, double width, double horizon, _Palette palette) {
    final relative = level.length - cameraZ;
    if (relative < 1 || relative > 125) return;
    final center = Offset(_screenX(0, relative), _screenY(horizon, relative));
    final scale = _scale(relative);
    final paint = Paint()..color = palette.finish..style = PaintingStyle.stroke..strokeWidth = 4 * scale;
    canvas.drawCircle(center, width * .08 * scale, paint);
    canvas.drawLine(Offset(center.dx - width * .08 * scale, center.dy), Offset(center.dx + width * .08 * scale, center.dy), paint);
  }

  void _renderPlayer(Canvas canvas, double width, double horizon, _Palette palette) {
    final center = Offset(_screenX(playerX, 2.4), size.y * .78 - playerY * width * .045);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy + 13), width: 42, height: 11), Paint()..color = const Color(0x66000000));
    final body = Paint()..color = palette.player;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: center, width: 30, height: 48), const Radius.circular(8)), body);
    canvas.drawCircle(Offset(center.dx, center.dy - 25), 12, Paint()..color = palette.glow);
    canvas.drawRect(Rect.fromCenter(center: Offset(center.dx, center.dy - 25), width: 12, height: 3), Paint()..color = palette.dark);
  }

  _Palette _palette(int id) {
    if (id <= 3) return const _Palette(Color(0xFF101B30), Color(0xFF1B2942), Color(0xFF253552), Color(0xFFFF5470), Color(0xFF40D9FF), Color(0xFF35D7B0), Color(0xFF8AA4C5));
    if (id <= 6) return const _Palette(Color(0xFF211A1B), Color(0xFF352428), Color(0xFF513438), Color(0xFFFF613B), Color(0xFFFFC15A), Color(0xFF35D7B0), Color(0xFFAD8377));
    if (id <= 9) return const _Palette(Color(0xFF10152D), Color(0xFF172452), Color(0xFF27346D), Color(0xFFFF3FB4), Color(0xFF4DE9FF), Color(0xFF4DFFB8), Color(0xFFA98BFF));
    if (id <= 12) return const _Palette(Color(0xFF17191D), Color(0xFF282C2E), Color(0xFF3B4443), Color(0xFFFF4F4F), Color(0xFFFFCA6B), Color(0xFF51E4C2), Color(0xFFB3C4BE));
    return const _Palette(Color(0xFF160D20), Color(0xFF28143A), Color(0xFF48205B), Color(0xFFFF426D), Color(0xFFFF9CDA), Color(0xFF66FFD4), Color(0xFFD59DFF));
  }
}

class _Palette {
  const _Palette(this.sky, this.road, this.side, this.danger, this.glow, this.finish, this.player);
  final Color sky;
  final Color road;
  final Color side;
  final Color danger;
  final Color glow;
  final Color finish;
  final Color player;
  Color get safe => const Color(0xFF53627A);
  Color get dark => const Color(0xFF0B1020);
}
