import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../sample_data.dart';

class QuizService {
  // Akhri error ka message (screen par dikhane ke liye).
  String? lastError;

  // Models ki list. Pehla fail ho (limit ya naam) to agla try hota hai.
  static const _modelNames = [
    'gemini-3.8-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
  ];

  // Har AI call ki hadd aur poore quiz ke liye kul hadd.
  static const _callTimeout = Duration(seconds: 35);
  static const _totalTimeout = Duration(seconds: 75);

  // Profile ki skills ki list (zyada se zyada 5).
  static List<String> skillsOf(Map<String, dynamic>? p) {
    final raw = (p?['skills'] ?? '').toString();
    final seen = <String>{};
    final out = <String>[];
    for (final part in raw.split(RegExp(r'[,\n;]'))) {
      final s = part.trim();
      if (s.isEmpty) continue;
      if (seen.add(s.toLowerCase())) out.add(s);
    }
    return out.length > 5 ? out.sublist(0, 5) : out;
  }

  // Saved sawal tab hi use hote hain jab skills, field aur level wohi hon.
  static String basisOf(Map<String, dynamic>? p) => [
    skillsOf(p).join(','),
    (p?['field'] ?? '').toString().trim(),
    (p?['education'] ?? '').toString().trim(),
  ].join('|');

  // Firestore ke map key ke liye mahfooz naam.
  static String cleanKey(String s) {
    final c = s
        .replaceAll(RegExp(r'[./\[\]*~`]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return c.isEmpty ? 'Skill' : c;
  }

  static List<Map<String, dynamic>> toMaps(List<QuizQuestion> qs) => [
    for (final q in qs)
      {
        'skill': q.skill,
        'question': q.question,
        'options': q.options,
        'answer': q.answer,
      }
  ];

  static List<QuizQuestion> fromMaps(dynamic raw) {
    final out = <QuizQuestion>[];
    if (raw is! List) return out;
    for (final m in raw) {
      try {
        final map = Map<String, dynamic>.from(m as Map);
        final options =
        (map['options'] as List).map((e) => e.toString()).toList();
        final answer = (map['answer'] as num).toInt();
        if (options.length != 4 || answer < 0 || answer > 3) continue;
        out.add(QuizQuestion(
          map['skill'].toString(),
          map['question'].toString(),
          options,
          answer,
        ));
      } catch (_) {}
    }
    return out;
  }

  // Education level ke hisab se sawalon ki mushkil.
  static String difficultyGuide(Map<String, dynamic> p) {
    final edu = (p['education'] ?? '').toString();
    switch (edu) {
      case 'High school':
        return 'VERY EASY. The candidate is a high school student. Test only '
            'basic ideas and simple everyday use of the skill, at school '
            'level. No advanced terms, no tricky cases, no long code.';
      case 'Diploma':
        return 'EASY. The candidate has a diploma or is a beginner. Test '
            'fundamentals and simple practical use. Avoid tricky cases.';
      case 'Bachelor (in progress)':
        return 'EASY TO MEDIUM. The candidate is still studying for a '
            'bachelor degree. Test course-level knowledge with simple '
            'practical situations. Do not use tricky edge cases.';
      case 'Bachelor (completed)':
        return 'MEDIUM TO HARD. The candidate has finished a bachelor '
            'degree. Test practical, scenario-based understanding and '
            'reading short snippets, so they can honestly check their skill.';
      case 'Master':
        return 'HARD. The candidate holds a master degree. Test deeper '
            'practical understanding, trade-offs and scenarios.';
      default:
        return 'MEDIUM. Test practical understanding of the skill.';
    }
  }

  String _friendly(Object? e) {
    final msg = (e ?? 'Unknown error').toString();
    if (msg.contains('quota') ||
        msg.contains('429') ||
        msg.contains('RESOURCE_EXHAUSTED')) {
      return 'AI limit reached for now. Please try again in a few minutes. '
          '(If it keeps happening, the daily free limit is used up. '
          'It resets around 1 PM Pakistan time.)';
    }
    if (msg.contains('TimeoutException')) {
      return 'The AI is taking too long right now. Please try again.';
    }
    return msg;
  }

  // AI ke jawab se sahi sawal nikalta hai, options shuffle karta hai.
  List<QuizQuestion> _parse(String? text, List<String> skills, int perSkill) {
    if (text == null) return [];
    final decoded = jsonDecode(text);
    List? raw;
    if (decoded is List) {
      raw = decoded;
    } else if (decoded is Map &&
        decoded.values.isNotEmpty &&
        decoded.values.first is List) {
      raw = decoded.values.first as List;
    }
    if (raw == null) return [];

    final rnd = Random();
    final out = <QuizQuestion>[];
    final counts = <String, int>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final q = (item['question'] ?? '').toString().trim();
      final opts = item['options'];
      final ans = item['answer'];
      if (q.isEmpty || opts is! List || opts.length != 4 || ans is! num) {
        continue;
      }
      final options = opts.map((e) => e.toString().trim()).toList();
      if (options.any((o) => o.isEmpty) || options.toSet().length != 4) {
        continue;
      }
      final a = ans.toInt();
      if (a < 0 || a > 3) continue;

      var skill = (item['skill'] ?? '').toString().trim();
      final match = skills.where((s) => s.toLowerCase() == skill.toLowerCase());
      skill = match.isNotEmpty
          ? match.first
          : (skill.isEmpty ? skills.first : skill);

      // Har skill ke zyada se zyada perSkill sawal.
      final key = skill.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
      if (counts[key]! > perSkill) continue;

      // Options ka tarteeb badlo, sahi jawab ka naya number nikalo.
      final order = [0, 1, 2, 3]..shuffle(rnd);
      final shuffled = [for (final i in order) options[i]];
      out.add(QuizQuestion(skill, q, shuffled, order.indexOf(a)));
    }
    out.shuffle(rnd);
    return out;
  }

  // Profile ki skills aur education ke hisab se naye sawal banata hai.
  // Fail hone par null.
  Future<List<QuizQuestion>?> generate(Map<String, dynamic> p) async {
    lastError = null;

    final skills = skillsOf(p);
    if (skills.isEmpty) {
      lastError = 'Add your skills in your profile first.';
      return null;
    }
    const perSkill = 2;
    final total = skills.length * perSkill;
    final needed = total > 2 ? total - 1 : total;

    final prompt = '''
You are writing a skills test for a candidate. Write exactly $total
multiple-choice questions: exactly $perSkill for each skill listed below.

Candidate:
- Education level: ${p['education']}
- Field of study: ${p['field']}
- Type: ${p['type']}

Difficulty (very important, follow it strictly):
${difficultyGuide(p)}
Within each skill, the second question may be a little harder than the first,
but both must stay inside the difficulty above.

Skills to test (use these exact names in the "skill" field):
${skills.map((s) => '- $s').join('\n')}

Rules:
- Exactly 4 options per question and exactly ONE clearly correct option.
  No "all of the above" or "none of the above". Wrong options must be
  plausible, not silly.
- Keep each question under 40 words and each option under 15 words. Any
  code must be a few lines, written as plain text.
- For non-technical skills such as communication, use a short realistic
  situation.
- Before you answer, double-check that the correct option really is correct.
- "answer" is the 0-based index (0 to 3) of the correct option.
- Variation seed: ${DateTime.now().millisecondsSinceEpoch}

Reply with ONLY a JSON array of objects, each with:
"skill" (string), "question" (string), "options" (array of 4 strings),
"answer" (integer 0-3).
''';

    final watch = Stopwatch()..start();
    Object? lastErr;
    for (final name in _modelNames) {
      if (watch.elapsed > _totalTimeout) break;
      final model = FirebaseAI.googleAI().generativeModel(
        model: name,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.5,
        ),
      );
      for (int attempt = 1; attempt <= 2; attempt++) {
        if (watch.elapsed > _totalTimeout) break;
        try {
          final response = await model
              .generateContent([Content.text(prompt)]).timeout(_callTimeout);
          final list = _parse(response.text, skills, perSkill);
          if (list.length >= needed && list.length >= 2) return list;
          lastErr = 'AI returned too few valid questions.';
          break; // agla model try karo
        } catch (e) {
          lastErr = e;
          debugPrint('Quiz AI error ($name): $e');
          final msg = e.toString();
          final busy = msg.contains('500') ||
              msg.contains('503') ||
              msg.contains('high demand');
          if (busy && attempt < 2) {
            await Future.delayed(const Duration(seconds: 3));
            continue;
          }
          break; // agla model try karo
        }
      }
    }
    lastError = _friendly(lastErr);
    return null;
  }
}