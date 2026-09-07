import 'package:flutter/material.dart';
import 'core/aura_engine.dart';

void main() => runApp(const AuraApp());

class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraSurface',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const AuraScreen(),
    );
  }
}

const _stateNames = {
  AffectState.calm: 'Calm',
  AffectState.focused: 'Focused',
  AffectState.stressed: 'Stressed',
  AffectState.tired: 'Tired',
  AffectState.energized: 'Energized',
};

class AuraScreen extends StatefulWidget {
  const AuraScreen({super.key});

  @override
  State<AuraScreen> createState() => _AuraScreenState();
}

class _AuraScreenState extends State<AuraScreen> {
  double _arousal = 0.5;
  double _valence = 0.5;
  double _light = 0.5;
  double _typing = 0.5;

  Signals get _signals => Signals(arousal: _arousal, valence: _valence, ambientLight: _light, typingCadence: _typing);

  @override
  Widget build(BuildContext context) {
    final cfg = auraFor(_signals);
    final accent = Color(cfg.accent);
    final base = Color.lerp(const Color(0xFF0B1020), const Color(0xFF1A1206), cfg.warmth)!;
    final surface = Color.lerp(Colors.black, base, 0.4 + cfg.brightness * 0.6)!;
    final pad = 12.0 + (1 - cfg.density) * 12;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.8),
                radius: 1.4,
                colors: [accent.withOpacity(0.10 + cfg.contrast * 0.12), surface],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('AuraSurface', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            key: ValueKey(cfg.state),
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(color: accent.withOpacity(0.2), borderRadius: BorderRadius.circular(999)),
                            child: Text(_stateNames[cfg.state]!, style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 12.5)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AuraCard(accent: accent, contrast: cfg.contrast, pad: pad),
                            SizedBox(height: pad),
                            for (final t in ['A breathing exercise', 'Your focus streak', 'A gentle reminder'])
                              Padding(
                                padding: EdgeInsets.only(bottom: pad * 0.7),
                                child: _Row(text: t, accent: accent, contrast: cfg.contrast, pad: pad),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x22FFFFFF))),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: accent),
                          const SizedBox(width: 10),
                          Expanded(child: Text(cfg.rationale, style: const TextStyle(color: Color(0xFFC7CEDB), fontSize: 12.5, height: 1.4))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.lock_outline, size: 13, color: Color(0xFF6B7488)),
                        SizedBox(width: 6),
                        Expanded(child: Text('All signals are processed on-device and never leave your phone.', style: TextStyle(color: Color(0xFF6B7488), fontSize: 11))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _signal('Arousal', _arousal, accent, (v) => setState(() => _arousal = v)),
                    _signal('Valence', _valence, accent, (v) => setState(() => _valence = v)),
                    _signal('Ambient light', _light, accent, (v) => setState(() => _light = v)),
                    _signal('Typing cadence', _typing, accent, (v) => setState(() => _typing = v)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _signal(String label, double value, Color accent, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 108, child: Text(label, style: const TextStyle(color: Color(0xFF98A2B8), fontSize: 12))),
        Expanded(child: Slider(value: value, activeColor: accent, onChanged: onChanged)),
      ],
    );
  }
}

class _AuraCard extends StatelessWidget {
  const _AuraCard({required this.accent, required this.contrast, required this.pad});
  final Color accent;
  final double contrast;
  final double pad;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: EdgeInsets.all(pad + 6),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.withOpacity(0.25 + contrast * 0.2), accent.withOpacity(0.08)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1 + contrast * 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa_rounded, color: Colors.white.withOpacity(0.6 + contrast * 0.4)),
              const SizedBox(width: 8),
              Text('Your moment', style: TextStyle(color: Colors.white.withOpacity(0.7 + contrast * 0.3), fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The surface adapts its tone, motion, and density to how you seem right now.',
            style: TextStyle(color: Colors.white.withOpacity(0.6 + contrast * 0.25), fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.text, required this.accent, required this.contrast, required this.pad});
  final String text;
  final Color accent;
  final double contrast;
  final double pad;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: EdgeInsets.all(pad * 0.85),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04 + contrast * 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08 + contrast * 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 14, backgroundColor: accent.withOpacity(0.25), child: Icon(Icons.circle, size: 10, color: accent)),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: Colors.white.withOpacity(0.75 + contrast * 0.25), fontSize: 13.5)),
        ],
      ),
    );
  }
}
