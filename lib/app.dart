import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';
import 'data/level.dart';
import 'game/darktrace_game.dart';
import 'services/progress_repository.dart';
import 'services/supabase_service.dart';

Future<void> mainApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.instance.initialize();
  runApp(const DarkTraceApp());
}

class DarkTraceApp extends StatelessWidget {
  const DarkTraceApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DARKTRACE',
        theme: DarkTraceTheme.data,
        home: const SplashScreen(),
      );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DarkTraceShell()));
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF070B14), Color(0xFF172A3B), Color(0xFF080B13)])),
          child: Center(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _animation, curve: Curves.easeOut),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/app_icon.png', width: 132, height: 132),
                const SizedBox(height: 28),
                const Text('DARKTRACE', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 6)),
                const SizedBox(height: 8),
                const Text('RUN THE SIGNAL', style: TextStyle(color: DarkTraceTheme.cyan, fontSize: 12, letterSpacing: 3)),
              ]),
            ),
          ),
        ),
      );
}

class DarkTraceShell extends StatefulWidget {
  const DarkTraceShell({super.key});
  @override
  State<DarkTraceShell> createState() => _DarkTraceShellState();
}

class _DarkTraceShellState extends State<DarkTraceShell> {
  final levels = seedLevels();
  ProgressState? progress;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await ProgressRepository.instance.load();
    if (mounted) setState(() => progress = loaded);
  }

  Future<void> _play(LevelDefinition level) async {
    final current = progress;
    if (current == null || level.id > current.highestUnlocked) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GamePage(level: level, levels: levels, progress: current)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final current = progress;
    if (current == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final pages = [
      HomePage(levels: levels, progress: current, onPlay: _play, onLevels: () => setState(() => tab = 1)),
      LevelsPage(levels: levels, progress: current, onPlay: _play),
      ProfilePage(progress: current),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Levels'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class Atmosphere extends StatelessWidget {
  const Atmosphere({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0A101D), Color(0xFF102635), Color(0xFF0A1018)])),
        child: Stack(children: [Positioned(top: -120, right: -90, child: Container(width: 280, height: 280, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: DarkTraceTheme.cyan.withValues(alpha: .12), blurRadius: 120)]))), child]),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({required this.levels, required this.progress, required this.onPlay, required this.onLevels, super.key});
  final List<LevelDefinition> levels;
  final ProgressState progress;
  final ValueChanged<LevelDefinition> onPlay;
  final VoidCallback onLevels;
  @override
  Widget build(BuildContext context) {
    final nextId = progress.highestUnlocked;
    final next = levels[nextId - 1];
    return Atmosphere(child: ListView(padding: const EdgeInsets.fromLTRB(22, 26, 22, 28), children: [
      Row(children: [const Icon(Icons.blur_on, color: DarkTraceTheme.cyan, size: 28), const SizedBox(width: 10), const Text('DARKTRACE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)), const Spacer(), IconButton(onPressed: () => _settings(context), icon: const Icon(Icons.settings_outlined))]),
      const SizedBox(height: 34),
      const Text('RUN THE SIGNAL', style: TextStyle(fontSize: 13, letterSpacing: 3, color: DarkTraceTheme.cyan)),
      const SizedBox(height: 4),
      const Text('DARKTRACE', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 4)),
      const SizedBox(height: 8),
      Text('${progress.totalCompleted} of 15 levels cleared', style: const TextStyle(color: DarkTraceTheme.muted)),
      const SizedBox(height: 28),
      _NextCard(level: next, progress: progress, onPlay: onPlay),
      const SizedBox(height: 22),
      Row(children: [Expanded(child: _ActionCard(icon: Icons.route, label: 'LEVEL\nSELECTION', onTap: onLevels)), const SizedBox(width: 12), Expanded(child: _ActionCard(icon: Icons.tune, label: 'SETTINGS', onTap: () => _settings(context)))]),
      const SizedBox(height: 28),
      LinearProgressIndicator(value: progress.totalCompleted / 15, minHeight: 6, borderRadius: BorderRadius.circular(4), backgroundColor: Colors.white12, color: DarkTraceTheme.cyan),
      const SizedBox(height: 10),
      Text('Highest unlocked: ${progress.highestUnlocked}', style: const TextStyle(color: DarkTraceTheme.muted, fontSize: 12)),
    ]));
  }

  void _settings(BuildContext context) => showModalBottomSheet<void>(context: context, backgroundColor: DarkTraceTheme.surface, builder: (_) => const SafeArea(child: Padding(padding: EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('SETTINGS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), SizedBox(height: 18), ListTile(leading: Icon(Icons.vibration_outlined), title: Text('Haptics'), trailing: Icon(Icons.check_circle, color: DarkTraceTheme.success))]))));
}

class _NextCard extends StatelessWidget {
  const _NextCard({required this.level, required this.progress, required this.onPlay});
  final LevelDefinition level;
  final ProgressState progress;
  final ValueChanged<LevelDefinition> onPlay;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: const LinearGradient(colors: [Color(0xFF123C4A), Color(0xFF172844)]), border: Border.all(color: DarkTraceTheme.cyan.withValues(alpha: .55))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(progress.forLevel(level.id).completed ? 'REPLAY LEVEL' : 'NEXT TRACE', style: const TextStyle(color: DarkTraceTheme.cyan, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)), const SizedBox(height: 9), Text('LEVEL ${level.id.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), Text(level.title, style: const TextStyle(color: DarkTraceTheme.muted)), const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => onPlay(level), icon: const Icon(Icons.play_arrow_rounded), label: const Text('ENTER COURSE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1)), style: FilledButton.styleFrom(backgroundColor: DarkTraceTheme.cyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15))))]));
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Container(height: 92, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .045), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: DarkTraceTheme.cyan), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, height: 1.1))])));
}

class LevelsPage extends StatelessWidget {
  const LevelsPage({required this.levels, required this.progress, required this.onPlay, super.key});
  final List<LevelDefinition> levels;
  final ProgressState progress;
  final ValueChanged<LevelDefinition> onPlay;
  @override
  Widget build(BuildContext context) => Atmosphere(child: ListView(padding: const EdgeInsets.all(22), children: [const Text('LEVELS', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const Text('Every route is earned.', style: TextStyle(color: DarkTraceTheme.muted)), const SizedBox(height: 24), ...levels.map((level) => _LevelTile(level: level, progress: progress, onPlay: onPlay))]));
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.progress, required this.onPlay});
  final LevelDefinition level;
  final ProgressState progress;
  final ValueChanged<LevelDefinition> onPlay;
  @override
  Widget build(BuildContext context) {
    final entry = progress.forLevel(level.id);
    final unlocked = level.id <= progress.highestUnlocked;
    return InkWell(onTap: unlocked ? () => onPlay(level) : null, child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), decoration: BoxDecoration(color: unlocked ? Colors.white.withValues(alpha: .05) : Colors.black12, borderRadius: BorderRadius.circular(8), border: Border.all(color: level.id == progress.highestUnlocked ? DarkTraceTheme.cyan : Colors.white12)), child: Row(children: [Container(width: 46, height: 46, alignment: Alignment.center, decoration: BoxDecoration(color: unlocked ? DarkTraceTheme.cyan.withValues(alpha: .13) : Colors.white10, borderRadius: BorderRadius.circular(6)), child: unlocked ? Text('${level.id}', style: const TextStyle(fontWeight: FontWeight.w900)) : const Icon(Icons.lock_outline, size: 18, color: DarkTraceTheme.muted)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(level.title, style: TextStyle(fontWeight: FontWeight.w800, color: unlocked ? null : DarkTraceTheme.muted)), Text('${level.zone}  •  ${level.difficulty}', style: const TextStyle(fontSize: 11, color: DarkTraceTheme.muted)), if (entry.completed) Text('Best ${entry.bestScore}  •  ${entry.bestTime!.toStringAsFixed(1)}s', style: const TextStyle(fontSize: 11, color: DarkTraceTheme.success))])), if (entry.completed) const Icon(Icons.check_circle, color: DarkTraceTheme.success, size: 19) else if (unlocked) const Icon(Icons.play_circle_outline, color: DarkTraceTheme.cyan) else const Icon(Icons.lock_outline, color: DarkTraceTheme.muted)])));
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.progress, super.key});
  final ProgressState progress;
  @override
  Widget build(BuildContext context) => Atmosphere(child: ListView(padding: const EdgeInsets.all(22), children: [const Text('PROFILE', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 25), const CircleAvatar(radius: 38, backgroundColor: DarkTraceTheme.cyan, child: Icon(Icons.person, color: Colors.black, size: 40)), const SizedBox(height: 12), const Center(child: Text('TRACE RUNNER', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))), const SizedBox(height: 30), Row(children: [Expanded(child: _Metric(value: '${progress.totalCompleted}', label: 'Cleared')), Expanded(child: _Metric(value: '${progress.highestUnlocked}', label: 'Unlocked')), Expanded(child: _Metric(value: '${progress.levels.values.fold<int>(0, (sum, item) => sum + item.attempts)}', label: 'Attempts'))]), const SizedBox(height: 30), const Text('PROGRESS', style: TextStyle(color: DarkTraceTheme.muted, letterSpacing: 1.5, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text('Best performances are saved locally and synced when an authenticated Supabase session is available.', style: Theme.of(context).textTheme.bodyMedium)]));
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: DarkTraceTheme.cyan)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 11, color: DarkTraceTheme.muted))]);
}

class GamePage extends StatefulWidget {
  const GamePage({required this.level, required this.levels, required this.progress, super.key});
  final LevelDefinition level;
  final List<LevelDefinition> levels;
  final ProgressState progress;
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final DarkTraceGame game;
  Timer? ticker;
  String? failureReason;
  bool paused = false;
  bool saving = false;
  int? finalScore;
  double? finalTime;
  int? bestScore;
  double? bestTime;

  @override
  void initState() {
    super.initState();
    game = DarkTraceGame(widget.level, onFailed: _fail, onComplete: (score, time) => _complete(score, time));
    ticker = Timer.periodic(const Duration(milliseconds: 180), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  void _fail(String reason) {
    if (mounted) setState(() => failureReason = reason);
  }

  Future<void> _complete(int score, double time) async {
    setState(() { finalScore = score; finalTime = time; saving = true; });
    final latest = await ProgressRepository.instance.load();
    final updated = await ProgressRepository.instance.recordAttempt(latest, widget.level.id, score: score, time: time);
    bestScore = updated.forLevel(widget.level.id).bestScore;
    bestTime = updated.forLevel(widget.level.id).bestTime;
    if (mounted) setState(() => saving = false);
  }

  void _restart() {
    setState(() { failureReason = null; finalScore = null; finalTime = null; bestScore = null; bestTime = null; paused = false; game.paused = false; });
    game.reset();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    final down = event is KeyDownEvent;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) game.setMove(down ? -1 : 0, game.inputY);
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) game.setMove(down ? 1 : 0, game.inputY);
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) game.setMove(game.inputX, down ? 1 : 0);
    if (key == LogicalKeyboardKey.space && down) game.jump();
    return KeyEventResult.handled;
  }

  void _pause() {
    setState(() { paused = !paused; game.paused = paused; });
    if (paused) {
      showDialog<void>(context: context, barrierDismissible: false, builder: (_) => AlertDialog(title: const Text('PAUSED'), content: Text('LEVEL ${widget.level.id}  •  ${game.elapsed.toStringAsFixed(1)}s'), actions: [TextButton(onPressed: () { Navigator.pop(context); _restart(); }, child: const Text('RESTART LEVEL')), TextButton(onPressed: () { Navigator.pop(context); showModalBottomSheet<void>(context: context, builder: (_) => const SafeArea(child: Padding(padding: EdgeInsets.all(24), child: Text('Settings are active for this session.', textAlign: TextAlign.center)))); }, child: const Text('SETTINGS')), TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('LEVEL SELECTION')), TextButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('EXIT TO HOME')), FilledButton(onPressed: () { Navigator.pop(context); _pause(); }, child: const Text('RESUME'))]));
    }
  }

  @override
  void didUpdateWidget(covariant GamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    game.paused = paused;
  }

  @override
  Widget build(BuildContext context) {
    final overlay = failureReason != null || finalScore != null;
    return Scaffold(backgroundColor: Colors.black, body: Focus(autofocus: true, onKeyEvent: _key, child: Stack(children: [GameWidget(game: game), Positioned(top: MediaQuery.paddingOf(context).top + 10, left: 16, right: 16, child: Row(children: [Text('LEVEL ${widget.level.id.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.w900)), const Spacer(), Text('${game.elapsed.toStringAsFixed(1)}s', style: const TextStyle(color: DarkTraceTheme.cyan, fontWeight: FontWeight.w800)), const SizedBox(width: 10), IconButton(onPressed: overlay ? null : _pause, icon: const Icon(Icons.pause_circle_outline, color: Colors.white))])), Positioned(bottom: 28, left: 24, child: _Joystick(onChanged: (value) => game.setMove(value.dx, value.dy))), Positioned(bottom: 38, right: 26, child: FloatingActionButton(onPressed: overlay ? null : game.jump, backgroundColor: DarkTraceTheme.cyan, foregroundColor: Colors.black, child: const Icon(Icons.arrow_upward))), if (failureReason != null) _FailureOverlay(reason: failureReason!, onRetry: _restart, onExit: () => Navigator.pop(context)), if (finalScore != null) _CompleteOverlay(level: widget.level, score: finalScore!, bestScore: bestScore ?? finalScore!, bestTime: bestTime ?? finalTime!, time: finalTime!, saving: saving, onNext: _continue, onExit: () => Navigator.pop(context))])));
  }

  void _continue() {
    if (widget.level.id == 15) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GamePage(level: widget.levels[widget.level.id], levels: widget.levels, progress: widget.progress)));
  }
}

class _Joystick extends StatelessWidget {
  const _Joystick({required this.onChanged});
  final ValueChanged<Offset> onChanged;
  @override
  Widget build(BuildContext context) => GestureDetector(onPanUpdate: (details) => onChanged(Offset((details.localPosition.dx - 52) / 45, (details.localPosition.dy - 52) / 45)), onPanEnd: (_) => onChanged(Offset.zero), child: Container(width: 104, height: 104, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black54, border: Border.all(color: Colors.white24, width: 2)), child: const Center(child: Icon(Icons.circle, color: Colors.white54, size: 38))));
}

class _FailureOverlay extends StatelessWidget {
  const _FailureOverlay({required this.reason, required this.onRetry, required this.onExit});
  final String reason;
  final VoidCallback onRetry;
  final VoidCallback onExit;
  @override
  Widget build(BuildContext context) => Container(color: const Color(0xCC070A12), alignment: Alignment.center, child: Container(margin: const EdgeInsets.all(28), padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: DarkTraceTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: DarkTraceTheme.danger)), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.warning_amber_rounded, color: DarkTraceTheme.danger, size: 42), const SizedBox(height: 15), const Text('ATTEMPT FAILED', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 7), Text(reason, style: const TextStyle(color: DarkTraceTheme.muted)), const SizedBox(height: 24), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.replay), label: const Text('RETRY LEVEL'))), SizedBox(width: double.infinity, child: TextButton.icon(onPressed: onExit, icon: const Icon(Icons.route), label: const Text('LEVEL SELECTION'))), SizedBox(width: double.infinity, child: TextButton.icon(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), icon: const Icon(Icons.home_outlined), label: const Text('EXIT TO HOME')))])));
}

class _CompleteOverlay extends StatelessWidget {
  const _CompleteOverlay({required this.level, required this.score, required this.bestScore, required this.bestTime, required this.time, required this.saving, required this.onNext, required this.onExit});
  final LevelDefinition level;
  final int score;
  final int bestScore;
  final double bestTime;
  final double time;
  final bool saving;
  final VoidCallback onNext;
  final VoidCallback onExit;
  @override
  Widget build(BuildContext context) => Container(color: const Color(0xCC070A12), alignment: Alignment.center, child: Container(margin: const EdgeInsets.all(28), padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: DarkTraceTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: DarkTraceTheme.success)), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(level.id == 15 ? Icons.workspace_premium : Icons.check_circle, color: DarkTraceTheme.success, size: 46), const SizedBox(height: 14), Text(level.id == 15 ? 'GAME COMPLETED' : 'LEVEL COMPLETE', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 18), _ResultRow(label: 'Score', value: '$score'), _ResultRow(label: 'Time', value: '${time.toStringAsFixed(1)}s'), _ResultRow(label: 'Best score', value: '$bestScore'), _ResultRow(label: 'Best time', value: '${bestTime.toStringAsFixed(1)}s'), const SizedBox(height: 18), if (saving) const LinearProgressIndicator() else SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onNext, icon: Icon(level.id == 15 ? Icons.home : Icons.arrow_forward), label: Text(level.id == 15 ? 'RETURN HOME' : 'CONTINUE'))), const SizedBox(height: 6), TextButton(onPressed: onExit, child: const Text('LEVEL SELECTION'))])));
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Text(label, style: const TextStyle(color: DarkTraceTheme.muted)), const Spacer(), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: DarkTraceTheme.cyan))]));
}
