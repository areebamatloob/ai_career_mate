import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'profile_service.dart';

class AiService {
  // Akhri error ka message (screen par dikhane ke liye).
  String? lastError;

  // Model ka naam waqt ke saath badalta rehta hai. Agar "model not found"
  // aaye to Firebase AI Logic ke docs ma current model naam dekh lein.
  final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.8-flash',
    generationConfig: GenerationConfig(responseMimeType: 'application/json'),
  );
  // Server busy (500/503) ho to 3 dafa tak dobara koshish karta hai.
  Future<GenerateContentResponse> _generateWithRetry(String prompt) async {
    const maxTries = 3;
    for (int attempt = 1; ; attempt++) {
      try {
        return await _model.generateContent([Content.text(prompt)]);
      } catch (e) {
        final msg = e.toString();
        final busy = msg.contains('500') ||
            msg.contains('503') ||
            msg.contains('high demand');
        if (!busy || attempt >= maxTries) rethrow;
        await Future.delayed(Duration(seconds: 3 * attempt));
      }
    }
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
      final text = response.text;
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
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('quota') || msg.contains('429')) {
        lastError =
        'Too many requests right now. Please wait a minute and try again.';
      } else {
        lastError = msg;
      }
      debugPrint('AI error: $e');
      return null;
    }
  }
}