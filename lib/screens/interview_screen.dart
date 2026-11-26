import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/profile_service.dart';
import '../theme.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final _profileService = ProfileService();
  final _ai = AiService();
  final _answerController = TextEditingController();

  List<String> _questions = [];
  List<int> _scores = []; // -1 matlab abhi jawab nahi diya
  String _goalTitle = '';
  int _index = 0;
  bool _finished = false; // sab sawal ho gaye, result dikhao

  bool _loading = true;
  String? _errorText;
  String? _details;

  bool _rating = false; // feedback aa raha hai
  Map<String, dynamic>? _feedback; // mil gaya hua feedback
  String? _feedbackError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _errorText = null;
      _details = null;
    });

    final p = await _profileService.loadProfile();
    final goal = AiService.goalTitleOf(p);
    if (goal == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = 'Open the Careers tab first to get your career matches.';
      });
      return;
    }

    // Pehle puche gaye sawal (naye sawal inse alag aane chahiye).
    final histRaw = p?['interviewHistory'];
    final history = histRaw is List
        ? histRaw.map((e) => e.toString()).toList()
        : <String>[];

    List<String> questions = [];
    List<int> scores = [];

    final saved = p?['interviewQuestions'];
    if (!refresh &&
        saved is List &&
        saved.length >= 2 &&
        p?['interviewFor'] == goal) {
      // Pehle se save kiye hue sawal aur scores
      questions = saved.map((e) => e.toString()).toList();
      final s = p?['interviewScores'];
      scores = List.generate(questions.length, (i) {
        if (s is List && i < s.length && s[i] is num) {
          return (s[i] as num).toInt();
        }
        return -1;
      });
    } else {
      // Naye sawal: purane sawal (history + maujooda) AI ko bhejte hain.
      final avoid = <String>[...history];
      if (saved is List) avoid.addAll(saved.map((e) => e.toString()));
      final unique = avoid.toSet().toList();
      final recent = unique.length > 24
          ? unique.sublist(unique.length - 24)
          : unique;

      final q = await _ai.getInterviewQuestions(avoid: recent);
      if (!mounted) return;
      if (q == null || q.isEmpty) {
        setState(() {
          _loading = false;
          _errorText = 'Could not make your interview questions.';
          _details = _ai.lastError ?? 'No reply from AI.';
        });
        return;
      }
      questions = q;
      scores = List.filled(q.length, -1);
      await _profileService.saveProfile({
        'interviewQuestions': questions,
        'interviewFor': goal,
        'interviewScores': scores,
        'interviewHistory': recent,
      });
    }
    if (!mounted) return;

    // Pehla sawal jis ka jawab abhi nahi diya. Sab ho chuke hon to result.
    final allDone = scores.isNotEmpty && scores.every((s) => s >= 0);
    int start = scores.indexWhere((s) => s < 0);
    if (start < 0) start = 0;

    setState(() {
      _questions = questions;
      _scores = scores;
      _goalTitle = goal;
      _index = start;
      _finished = allDone;
      _feedback = null;
      _feedbackError = null;
      _answerController.clear();
      _loading = false;
    });
  }

  List<String> _strings(dynamic v) {
    if (v is! List) return [];
    return v
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _getFeedback() async {
    final answer = _answerController.text.trim();
    if (answer.length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Write a real answer first (a sentence or two).')),
      );
      return;
    }

    setState(() {
      _rating = true;
      _feedbackError = null;
    });

    final result = await _ai.rateAnswer(
      question: _questions[_index],
      answer: answer,
      goal: _goalTitle,
    );
    if (!mounted) return;

    final raw = result?['score'];
    if (result == null || raw is! num) {
      setState(() {
        _rating = false;
        _feedbackError =
            _ai.lastError ?? 'Could not get feedback. Please try again.';
      });
      return;
    }

    int score = raw.toInt();
    if (score < 1) score = 1;
    if (score > 10) score = 10;

    _scores[_index] = score;
    await _profileService.saveProfile({'interviewScores': _scores});
    if (!mounted) return;

    setState(() {
      _rating = false;
      _feedback = {
        'score': score,
        'worked': _strings(result['worked']),
        'improve': _strings(result['improve']),
        'better': (result['better'] ?? '').toString().trim(),
      };
    });
  }

  void _nextQuestion() {
    final isLast = _index == _questions.length - 1;
    setState(() {
      if (isLast) {
        _finished = true;
      } else {
        _index++;
      }
      _feedback = null;
      _feedbackError = null;
      _answerController.clear();
    });
  }

  // Wohi sawal dobara, scores saaf.
  Future<void> _practiceAgain() async {
    final fresh = List.filled(_questions.length, -1);
    await _profileService.saveProfile({'interviewScores': fresh});
    if (!mounted) return;
    setState(() {
      _scores = fresh;
      _index = 0;
      _finished = false;
      _feedback = null;
      _feedbackError = null;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Preparing your interview questions...',
                style: TextStyle(color: kMuted)),
          ],
        ),
      );
    }

    if (_errorText != null) {
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          AppCard(
            child: Column(
              children: [
                Text(_errorText!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
                if (_details != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_details!,
                        style: const TextStyle(color: kMuted, fontSize: 12),
                        textAlign: TextAlign.center),
                  ),
                const SizedBox(height: 12),
                BigButton(
                    text: 'Try again',
                    onPressed: () => _load(refresh: true)),
              ],
            ),
          ),
        ],
      );
    }

    if (_finished) return _summary();

    final locked = _rating || _feedback != null;
    final answered = _scores.where((s) => s >= 0).toList();
    final average = answered.isEmpty
        ? 0.0
        : answered.reduce((a, b) => a + b) / answered.length;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmallTag('Question ${_index + 1} of ${_questions.length}'),
              const SizedBox(height: 10),
              Text(_questions[_index],
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        TextField(
          controller: _answerController,
          maxLines: 5,
          readOnly: locked,
          decoration: const InputDecoration(hintText: 'Type your answer'),
        ),
        const SizedBox(height: 10),
        if (_rating)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_feedback == null) ...[
          if (_feedbackError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_feedbackError!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center),
            ),
          BigButton(
              text: _feedbackError != null ? 'Try again' : 'Get feedback',
              onPressed: _getFeedback),
        ] else
          _feedbackCard(),
        if (answered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Your average so far: ${average.toStringAsFixed(1)}/10 '
                  'over ${answered.length} answer${answered.length == 1 ? '' : 's'}',
              style: const TextStyle(color: kMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        TextButton.icon(
          onPressed: _rating ? null : () => _load(refresh: true),
          icon: const Icon(Icons.refresh),
          label: const Text('Get new questions'),
        ),
      ],
    );
  }

  // Sab sawal ho jane ke baad ka result.
  Widget _summary() {
    final answered = _scores.where((s) => s >= 0).toList();
    final average = answered.isEmpty
        ? 0.0
        : answered.reduce((a, b) => a + b) / answered.length;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SmallTag('Interview complete'),
              const SizedBox(height: 10),
              Center(
                child: Text('${average.toStringAsFixed(1)}/10',
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: kPrimary)),
              ),
              const Center(
                  child: Text('Average score',
                      style: TextStyle(color: kMuted))),
              const SizedBox(height: 12),
              for (int i = 0; i < _questions.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text('${i + 1}. ${_questions[i]}',
                            maxLines: 3, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 10),
                      Text(_scores[i] >= 0 ? '${_scores[i]}/10' : '–',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: kPrimary)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        BigButton(
            text: 'Get new questions', onPressed: () => _load(refresh: true)),
        const SizedBox(height: 8),
        BigButton(
            text: 'Practice these again', soft: true, onPressed: _practiceAgain),
      ],
    );
  }

  Widget _feedbackCard() {
    final f = _feedback!;
    final score = f['score'] as int;
    final worked = f['worked'] as List<String>;
    final improve = f['improve'] as List<String>;
    final better = f['better'] as String;
    final isLast = _index == _questions.length - 1;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                  child: Text('Feedback',
                      style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              Text('$score/10',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('What worked',
              style: TextStyle(fontWeight: FontWeight.w800)),
          if (worked.isEmpty)
            const Text('• Nothing stood out yet. Add more detail.')
          else
            for (final w in worked) Text('• $w'),
          const SizedBox(height: 8),
          const Text('Improve', style: TextStyle(fontWeight: FontWeight.w800)),
          for (final t in improve) Text('• $t'),
          if (better.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('A stronger answer could start like this',
                style: TextStyle(fontWeight: FontWeight.w800)),
            Text(better),
          ],
          const SizedBox(height: 14),
          BigButton(
              text: isLast ? 'Finish' : 'Next question',
              onPressed: _nextQuestion),
          const SizedBox(height: 8),
          BigButton(
            text: 'Try this question again',
            soft: true,
            onPressed: () => setState(() => _feedback = null),
          ),
        ],
      ),
    );
  }
}