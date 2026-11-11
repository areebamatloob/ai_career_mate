import 'dart:async';
import 'package:flutter/material.dart';
import '../sample_data.dart';
import '../theme.dart';
import 'main_shell.dart';

/// Timed quiz. You cannot go back to an earlier question.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int secondsPerQuestion = 25;

  int _index = 0;
  int? _selected;
  int _secondsLeft = secondsPerQuestion;
  Timer? _timer;
  bool _finished = false;
  final List<bool> _results = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = secondsPerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        _next(); // time is over, an unanswered question counts as wrong
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _next() {
    final question = sampleQuiz[_index];
    _results.add(_selected == question.answer);

    if (_index == sampleQuiz.length - 1) {
      _timer?.cancel();
      setState(() => _finished = true);
    } else {
      setState(() {
        _index++;
        _selected = null;
      });
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope blocks the phone's back button during the quiz.
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_finished ? 'Quiz result' : 'Skills quiz'),
        ),
        body: _finished ? _buildResult() : _buildQuestion(),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = sampleQuiz[_index];
    final isLast = _index == sampleQuiz.length - 1;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Question ${_index + 1} of ${sampleQuiz.length} · ${q.skill}',
                  style: const TextStyle(color: kMuted)),
            ),
            Text('${_secondsLeft}s',
                style: const TextStyle(
                    color: kAccent, fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: LinearProgressIndicator(
            value: _index / sampleQuiz.length,
            minHeight: 9,
            backgroundColor: kLine,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Text(q.question,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        for (int i = 0; i < q.options.length; i++)
          GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _selected == i ? kSoft : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _selected == i ? kPrimary : kLine),
              ),
              child: Text(q.options[i],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        const SizedBox(height: 4),
        BigButton(text: isLast ? 'Finish' : 'Next question', onPressed: _next),
        const SizedBox(height: 10),
        const Text(
          'Each question is timed and you cannot go back. Unanswered questions count as wrong.',
          style: TextStyle(color: kMuted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final score = _results.where((r) => r).length;

    // Count right answers for every skill.
    final Map<String, List<int>> bySkill = {};
    for (int i = 0; i < _results.length; i++) {
      final skill = sampleQuiz[i].skill;
      bySkill.putIfAbsent(skill, () => [0, 0]);
      bySkill[skill]![1]++;
      if (_results[i]) bySkill[skill]![0]++;
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        AppCard(
          child: Column(
            children: [
              Text('$score/${_results.length}',
                  style: const TextStyle(
                      fontSize: 44, fontWeight: FontWeight.w800, color: kPrimary)),
              const Text('Quiz complete.'),
              const SizedBox(height: 12),
              for (final entry in bySkill.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(entry.key,
                              style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text('${entry.value[0]}/${entry.value[1]}',
                          style: const TextStyle(color: kMuted)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        BigButton(
          text: 'See my career matches',
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainShell()),
            (route) => false,
          ),
        ),
      ],
    );
  }
}
