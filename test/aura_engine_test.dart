import 'package:flutter_test/flutter_test.dart';
import 'package:aura_surface/core/aura_engine.dart';

void main() {
  group('interpret', () {
    test('high arousal + low valence → stressed', () {
      expect(interpret(const Signals(arousal: 0.8, valence: 0.2, ambientLight: 0.5, typingCadence: 0.5)), AffectState.stressed);
    });

    test('low arousal + low valence → tired', () {
      expect(interpret(const Signals(arousal: 0.2, valence: 0.3, ambientLight: 0.3, typingCadence: 0.3)), AffectState.tired);
    });

    test('high arousal + high valence → energized', () {
      expect(interpret(const Signals(arousal: 0.8, valence: 0.8, ambientLight: 0.6, typingCadence: 0.7)), AffectState.energized);
    });

    test('steady mid arousal + fast typing → focused', () {
      expect(interpret(const Signals(arousal: 0.5, valence: 0.6, ambientLight: 0.5, typingCadence: 0.7)), AffectState.focused);
    });

    test('neutral signals → calm', () {
      expect(interpret(Signals.neutral), AffectState.calm);
    });

    test('is total and deterministic across the signal space', () {
      for (var a = 0.0; a <= 1.0; a += 0.25) {
        for (var v = 0.0; v <= 1.0; v += 0.25) {
          for (var t = 0.0; t <= 1.0; t += 0.5) {
            final s = Signals(arousal: a, valence: v, ambientLight: 0.5, typingCadence: t);
            final state = interpret(s);
            expect(AffectState.values.contains(state), isTrue);
            expect(interpret(s), state); // deterministic
          }
        }
      }
    });
  });

  group('adaptFor', () {
    test('stressed lowers motion and density (calms the UI)', () {
      final calm = auraFor(Signals.neutral);
      final stressed = auraFor(const Signals(arousal: 0.85, valence: 0.15, ambientLight: 0.5, typingCadence: 0.5));
      expect(stressed.motion, lessThan(calm.motion));
      expect(stressed.density, lessThan(calm.density));
    });

    test('energized raises motion and contrast', () {
      final energized = auraFor(const Signals(arousal: 0.85, valence: 0.85, ambientLight: 0.6, typingCadence: 0.7));
      expect(energized.motion, greaterThan(0.7));
      expect(energized.contrast, greaterThan(0.6));
    });

    test('every field stays within range and carries a rationale', () {
      for (final state in AffectState.values) {
        final cfg = adaptFor(Signals.neutral, state);
        for (final f in [cfg.warmth, cfg.motion, cfg.density, cfg.contrast, cfg.brightness]) {
          expect(f, inInclusiveRange(0.0, 1.0));
        }
        expect(cfg.rationale.isNotEmpty, isTrue);
        expect(cfg.state, state);
      }
    });

    test('brighter rooms produce a brighter surface', () {
      final dim = auraFor(const Signals(arousal: 0.5, valence: 0.6, ambientLight: 0.1, typingCadence: 0.5));
      final bright = auraFor(const Signals(arousal: 0.5, valence: 0.6, ambientLight: 0.9, typingCadence: 0.5));
      expect(bright.brightness, greaterThan(dim.brightness));
    });
  });
}
