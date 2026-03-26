// ── PatternService ────────────────────────────────────────────────────────────
// Handles ONLY pattern save/compare logic.
// No UI code here. No Firebase. No Auth.
// Called by art_screen.dart — never call Firebase from here.
// ──────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:hive/hive.dart';
import '../core/constants.dart';

class DrawPoint {
  final double x;
  final double y;

  const DrawPoint(this.x, this.y);

  Map<String, double> toMap() => {'x': x, 'y': y};

  factory DrawPoint.fromMap(Map<String, dynamic> map) => DrawPoint(
        (map['x'] as num).toDouble(),
        (map['y'] as num).toDouble(),
      );
}

class PatternService {
  PatternService._();

  static Box get _box => Hive.box(kSecureBox);

  // ── Has saved pattern? ─────────────────────────────

  static bool hasPattern() {
    return _box.containsKey(kPatternKey);
  }

  // ── Save pattern ───────────────────────────────────
  // Call this on first draw — saves as master reference

  static Future<void> savePattern(List<DrawPoint> points) async {
    final encoded = jsonEncode(points.map((p) => p.toMap()).toList());
    await _box.put(kPatternKey, encoded);
  }

  // ── Delete pattern ─────────────────────────────────
  // Used in settings → reset signature

  static Future<void> deletePattern() async {
    await _box.delete(kPatternKey);
  }

  // ── Compare pattern ────────────────────────────────
  // Returns true if drawn pattern matches saved master
  // Uses zone + similarity system

  static bool compare(List<DrawPoint> drawn) {
    if (!hasPattern()) return false;

    final raw = _box.get(kPatternKey) as String;
    final savedList = (jsonDecode(raw) as List)
        .map((e) => DrawPoint.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (drawn.length < kMinPatternPoints) return false;
    if (savedList.isEmpty) return false;

    return _zoneCheck(drawn, savedList) &&
        _similarityCheck(drawn, savedList);
  }

  // ── Zone check ─────────────────────────────────────
  // Canvas divided into 4 quadrants
  // Every zone present in saved must be present in drawn
  // Prevents missing key parts of the signature

  static bool _zoneCheck(
    List<DrawPoint> drawn,
    List<DrawPoint> saved,
  ) {
    // Find bounding box of saved signature
    double minX = double.infinity, minY = double.infinity;
    double maxX = 0, maxY = 0;

    for (final p in saved) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }

    final midX = (minX + maxX) / 2;
    final midY = (minY + maxY) / 2;

    final savedZones = saved.map((p) => _zone(p, midX, midY)).toSet();
    final drawnZones = drawn.map((p) => _zone(p, midX, midY)).toSet();

    // All saved zones must appear in drawn
    return drawnZones.containsAll(savedZones);
  }

  static int _zone(DrawPoint p, double midX, double midY) {
    if (p.x <= midX && p.y <= midY) return 1; // top-left
    if (p.x > midX && p.y <= midY) return 2;  // top-right
    if (p.x <= midX && p.y > midY) return 3;  // bottom-left
    return 4;                                   // bottom-right
  }

  // ── Similarity check ───────────────────────────────
  // For each saved point, check if drawn has a point within tolerance
  // Requires 75% of saved points to have a match

  static bool _similarityCheck(
    List<DrawPoint> drawn,
    List<DrawPoint> saved,
  ) {
    int matches = 0;

    for (final sp in saved) {
      for (final dp in drawn) {
        final dx = (dp.x - sp.x).abs();
        final dy = (dp.y - sp.y).abs();
        if (dx < kPatternTolerance && dy < kPatternTolerance) {
          matches++;
          break;
        }
      }
    }

    final similarity = (matches / saved.length) * 100;
    return similarity >= kPatternSimilarityThreshold;
  }
}
