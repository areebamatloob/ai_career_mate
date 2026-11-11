import 'package:flutter/material.dart';

// ---------- Colors used everywhere in the app ----------
const Color kPrimary = Color(0xFF0F6B6B);
const Color kBackground = Color(0xFFEEF3F8);
const Color kSoft = Color(0xFFDDF0EE);
const Color kAccent = Color(0xFFF2A33A);
const Color kAccentSoft = Color(0xFFFFF0D6);
const Color kInk = Color(0xFF12202B);
const Color kMuted = Color(0xFF5F7380);
const Color kLine = Color(0xFFDCE5EC);

ThemeData buildTheme() {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: kLine),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: kPrimary, primary: kPrimary),
    scaffoldBackgroundColor: kBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      foregroundColor: kInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle:
          TextStyle(color: kInk, fontSize: 20, fontWeight: FontWeight.w800),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBackground,
      border: border,
      enabledBorder: border,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}

// ---------- Small reusable widgets ----------

/// White rounded box used for most content.
class AppCard extends StatelessWidget {
  final Widget child;
  const AppCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLine),
      ),
      child: child,
    );
  }
}

/// Full width button. soft = true gives the light green style.
class BigButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool soft;
  const BigButton(
      {super.key, required this.text, this.onPressed, this.soft = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: soft ? kSoft : kPrimary,
          foregroundColor: soft ? kPrimary : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(text),
      ),
    );
  }
}

/// Small yellow label like "Your goal".
class SmallTag extends StatelessWidget {
  final String text;
  const SmallTag(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: kAccentSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// A bar that shows the user's level (green) against the level needed (yellow).
class SkillBar extends StatelessWidget {
  final String name;
  final int current;
  final int required;
  final bool tested;
  const SkillBar(
      {super.key,
      required this.name,
      required this.current,
      required this.required,
      required this.tested});

  Widget _bar(double fraction, Color color) {
    return FractionallySizedBox(
      widthFactor: fraction.clamp(0.0, 1.0),
      child: Container(
        height: 9,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(9)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = current > required ? required : current;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              Text('$current/$required · ${tested ? 'tested' : 'self-reported'}',
                  style: const TextStyle(color: kMuted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            height: 9,
            decoration: BoxDecoration(
                color: kLine, borderRadius: BorderRadius.circular(9)),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                _bar(required / 100, kAccentSoft),
                _bar(shown / 100, kPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
