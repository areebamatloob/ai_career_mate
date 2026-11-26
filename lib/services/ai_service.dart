import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'profile_service.dart';

class AiService {
  // Akhri error ka message (screen par dikhane ke liye).
  String? lastError;

  // Models ki list. Pehla fail ho (limit ya naam) to agla try hota hai.
  // Naam badalte rehte hain, agar koi "not found" aaye to docs se current
  // naam dekh lein. Fail hone wala model khud skip ho jata hai.
  static const _modelNames = [
    'gemini-3.8-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
  ];

  GenerativeModel _build(String name) {
    return FirebaseAI.googleAI().generativeModel(
      model: name,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  // Har model par busy hone par ek dafa dobara koshish, phir agla model.
  Future<GenerateContentResponse> _generateWithRetry(String prompt) async {
    Object? lastErr;
    for (final name in _modelNames) {
      final model = _build(name);
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          return await model.generateContent([Content.text(prompt)]);
        } catch (e) {
          lastErr = e;
          debugPrint('AI error ($name): $e');
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
    throw lastErr ?? Exception('AI request failed.');
  }

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('quota') ||
        msg.contains('429') ||
        msg.contains('RESOURCE_EXHAUSTED')) {
      return 'AI limit reached for now. Please try again in a few minutes. '
          '(If it keeps happening, the daily free limit is used up. '
          'It resets around 1 PM Pakistan time.)';
    }
    return msg;
  }

  // AI ka jawab JSON list ma badalta hai.
  List<Map<String, dynamic>>? _toList(String? text) {
    if (text == null) {
      lastError = 'AI returned an empty reply.';
      return null;
    }
    final decoded = jsonDecode(text);
    List list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map &&
        decoded.values.isNotEmpty &&
        decoded.values.first is List) {
      list = decoded.values.first as List;
    } else {
      lastError = 'AI reply had an unexpected format.';
      return null;
    }
    return list.cast<Map<String, dynamic>>();
  }

  // 3 career recommendations laata hai. Fail hone par null.
  Future<List<Map<String, dynamic>>?> getCareers() async {
    lastError = null;

    final p = await ProfileService().loadProfile();
    if (p == null) {
      lastError = 'Profile not found. Save your profile first.';
      return null;
    }

    final prompt = '''
You are a career advisor. Suggest the 3 best careers for this person.
Use only the information given. Do not invent skills they did not list.

Profile:
- Type: ${p['type']}
- Education: ${p['education']}, field: ${p['field']}
- Skills: ${p['skills']}
- Interests: ${p['interests']}
- Goal: ${p['goal']}
- Projects: ${p['projects']}
- Certifications: ${p['certs']}
- Skills quiz (correct/total per skill): ${jsonEncode(p['quizBySkill'])}

Reply with ONLY a JSON array of 3 objects, each with:
"title" (string),
"match" (integer 0-100, how well it fits),
"why" (one short sentence),
"skills" (array of 3 objects: "name", "current" 0-100, "required" 0-100,
          "tested" true only if it was in the quiz),
"roles" (array of 2-3 entry-level job titles).
''';

    try {
      final response = await _generateWithRetry(prompt);
      return _toList(response.text);
    } catch (e) {
      lastError = _friendly(e);
      return null;
    }
  }

  // Goal career ke liye 4-6 step ka roadmap banata hai. Fail hone par null.
  Future<List<Map<String, dynamic>>?> getRoadmap() async {
    lastError = null;

    final p = await ProfileService().loadProfile();
    if (p == null) {
      lastError = 'Profile not found. Save your profile first.';
      return null;
    }

    // Goal career dhoondo (user ne chuna ho ya pehli career).
    final careers = (p['careers'] is List) ? p['careers'] as List : [];
    Map? goal;
    if (p['goalCareer'] != null) {
      for (final c in careers) {
        if (c is Map && c['title'] == p['goalCareer']) goal = c;
      }
    }
    goal ??= careers.isNotEmpty && careers.first is Map
        ? careers.first as Map
        : null;

    if (goal == null) {
      lastError = 'Open the Careers tab first to get your career matches.';
      return null;
    }

    final prompt = '''
You are a career coach. Make a practical learning roadmap of 4 to 6 steps
for this person to become a "${goal['title']}".
Focus on the skills they are missing. Do not repeat skills they already have.

Profile:
- Education: ${p['education']}, field: ${p['field']}
- Current skills: ${p['skills']}
- Projects: ${p['projects']}

Skill gap for this career (current vs required, 0-100):
${jsonEncode(goal['skills'])}

Reply with ONLY a JSON array of objects, in the order to do them, each with:
"title" (short action),
"why" (one short sentence, why this step matters for them),
"weeks" (integer, realistic number of weeks),
"resource" (name of a well-known free course or website, NOT a link).
''';

    try {
      final response = await _generateWithRetry(prompt);
      return _toList(response.text);
    } catch (e) {
      lastError = _friendly(e);
      return null;
    }
  }
}