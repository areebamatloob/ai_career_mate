import 'package:flutter_test/flutter_test.dart';
import 'package:ai_career_mate/sample_data.dart';

void main() {
  test('every quiz question has a valid correct answer', () {
    for (final q in sampleQuiz) {
      expect(q.answer >= 0 && q.answer < q.options.length, true);
    }
  });
}