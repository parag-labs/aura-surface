/// The affect interpreter and visual-adaptation engine — the deterministic core of AuraSurface.
/// It reads a small set of on-device [Signals] (arousal, valence, ambient light, typing cadence)
/// and maps them, first to an [AffectState], then to a [VisualConfig] describing how the UI
/// should feel: colour warmth, motion intensity, density, contrast, and accent. The adaptation is
/// intentionally subtle and always explainable. Pure Dart, so it is unit-testable and reproducible.
library;

/// On-device signals, each normalized to [0, 1]. In a real build these come from HRV, a facial
/// expression estimate (MediaPipe), typing rhythm, and the ambient light sensor — never leaving
/// the device.
class Signals {
  const Signals({
    required this.arousal,
    required this.valence,
    required this.ambientLight,
    required this.typingCadence,
  });

  /// Physiological/behavioural activation. High = wired/stressed, low = calm/tired.
  final double arousal;

  /// Emotional positivity. High = positive, low = negative.
  final double valence;

  /// Environment brightness. High = bright room, low = dark.
  final double ambientLight;

  /// Typing speed/rhythm. High = fast/agitated, low = slow/relaxed.
  final double typingCadence;

  static const neutral = Signals(arousal: 0.5, valence: 0.5, ambientLight: 0.5, typingCadence: 0.5);
}

/// A coarse affective state the UI responds to.
enum AffectState { calm, focused, stressed, tired, energized }

/// How the interface should present itself. All fields are 0..1 except [accent] (ARGB int).
class VisualConfig {
  const VisualConfig({
    required this.state,
    required this.warmth,
    required this.motion,
    required this.density,
    required this.contrast,
    required this.brightness,
    required this.accent,
    required this.rationale,
  });

  final AffectState state;

  /// 0 = cool/blue, 1 = warm/amber.
  final double warmth;

  /// 0 = still, 1 = lively animation.
  final double motion;

  /// 0 = sparse/large, 1 = dense/compact.
  final double density;

  /// 0 = soft/low contrast, 1 = crisp/high contrast.
  final double contrast;

  /// Overall surface brightness, 0 = very dim, 1 = bright.
  final double brightness;

  /// Accent colour as an ARGB int.
  final int accent;

  /// A short, honest explanation of *why* the UI changed — always shown to the user.
  final String rationale;
}

/// Interpret signals into an affect state. Deterministic and total.
///
/// The logic, in priority order:
///  - high arousal + low valence → stressed (the UI should calm things down);
///  - low arousal + low valence → tired;
///  - high arousal + high valence → energized;
///  - moderate arousal + fast, steady typing → focused;
///  - otherwise → calm.
AffectState interpret(Signals s) {
  if (s.arousal >= 0.6 && s.valence < 0.45) return AffectState.stressed;
  if (s.arousal < 0.4 && s.valence < 0.5) return AffectState.tired;
  if (s.arousal >= 0.6 && s.valence >= 0.6) return AffectState.energized;
  if (s.typingCadence >= 0.55 && s.arousal >= 0.4 && s.arousal < 0.7) return AffectState.focused;
  return AffectState.calm;
}

/// Map an affect state (plus ambient light) to a visual configuration. The changes are subtle by
/// design — a "tasteful emotional skin", not a mood swing.
VisualConfig adaptFor(Signals s, AffectState state) {
  // Ambient light nudges brightness so the screen matches the room, dampened to stay gentle.
  final ambientBrightness = 0.35 + s.ambientLight * 0.4;

  switch (state) {
    case AffectState.stressed:
      return VisualConfig(
        state: state,
        warmth: 0.65,
        motion: 0.2, // slow things down
        density: 0.25, // declutter
        contrast: 0.4, // softer
        brightness: (ambientBrightness * 0.85).clamp(0.0, 1.0),
        accent: 0xFF6C8CFF, // calming blue
        rationale: 'Signals suggest stress, so the interface is calmer: warmer tone, less motion, and fewer elements.',
      );
    case AffectState.tired:
      return VisualConfig(
        state: state,
        warmth: 0.8,
        motion: 0.15,
        density: 0.3,
        contrast: 0.35,
        brightness: (ambientBrightness * 0.7).clamp(0.0, 1.0),
        accent: 0xFFFFB27A, // warm, low-strain
        rationale: 'Low energy detected, so the screen dims and warms to reduce strain.',
      );
    case AffectState.energized:
      return VisualConfig(
        state: state,
        warmth: 0.35,
        motion: 0.85,
        density: 0.7,
        contrast: 0.8,
        brightness: ambientBrightness,
        accent: 0xFF34D9C8, // bright, lively
        rationale: 'You seem energized, so the UI is livelier: cooler, crisper, and more animated.',
      );
    case AffectState.focused:
      return VisualConfig(
        state: state,
        warmth: 0.45,
        motion: 0.35,
        density: 0.4,
        contrast: 0.7,
        brightness: ambientBrightness,
        accent: 0xFF7C6CFF,
        rationale: 'Focused typing detected, so distractions are dialled down and contrast is raised.',
      );
    case AffectState.calm:
      return VisualConfig(
        state: state,
        warmth: 0.55,
        motion: 0.4,
        density: 0.45,
        contrast: 0.55,
        brightness: ambientBrightness,
        accent: 0xFF9A8CFF,
        rationale: 'A balanced, calm baseline.',
      );
  }
}

/// Convenience: signals → full visual config in one call.
VisualConfig auraFor(Signals s) => adaptFor(s, interpret(s));
