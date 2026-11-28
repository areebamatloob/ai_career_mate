import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../sample_data.dart';
import '../services/profile_service.dart';
import '../services/quiz_service.dart';
import '../theme.dart';
import 'main_shell.dart';
import 'welcome_screen.dart';

/// Timed quiz. You cannot go back to an earlier question.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int secondsPerQuestion = 40;

  final _profileService = ProfileService();
  final _quizService = QuizService();

  List<QuizQuestion> _questions = [];
  bool _loading = true;
  String? _loadError;
  String? _loadDetails;

  int _index = 0;
  int? _selected;
  int _secondsLeft = secondsPerQuestion;
  Timer? _timer;
  bool _finished = false;
  final List<bool> _results = [];

  bool _isSaving = false;
  bool _saved = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Sawal tayyar karta hai: naye AI sawal, warna pehle save kiye hue.
  Future<void> _start() async {
    _timer?.cancel();
    setState(() {
      _loading = true;
      _loadError = null;
      _loadDetails = null;
    });

    final p = await _profileService.loadProfile();
    if (p == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not load your profile.';
        _loadDetails = 'Check your internet and try again.';
      });
      return;
    }

    var qs = await _quizService.generate(p);
    if (qs != null) {
      // Naye sawal save (agli dafa AI na chale to kaam aayenge).
      // unawaited: save ka intezar nahi, quiz foran shuru hota hai.
      unawaited(_profileService.saveProfile({
        'quizQuestions': QuizService.toMaps(qs),
        'quizFor': QuizService.basisOf(p),
      }));
    } else if (p['quizFor'] == QuizService.basisOf(p)) {
      final saved = QuizService.fromMaps(p['quizQuestions']);
      if (saved.length >= 2) {
        saved.shuffle();
        qs = saved;
      }
    }
    if (!mounted) return;

    if (qs == null) {
      setState(() {
        _loading = false;
        _loadError = 'Could not prepare your quiz.';
        _loadDetails = _quizService.lastError ?? 'No reply from AI.';
      });
      return;
    }

    setState(() {
      _questions = qs!;
      _index = 0;
      _selected = null;
      _results.clear();
      _finished = false;
      _saved = false;
      _errorText = null;
      _loading = false;
    });
    _startTimer();
  }

  void _startTimer({bool reset = true}) {
    _timer?.cancel();
    if (reset) _secondsLeft = secondsPerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        _next(); // time is over, an unanswered question counts as wrong
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _next() {
    if (_questions.isEmpty || _finished) return;
    final question = _questions[_index];
    _results.add(_selected == question.answer);

    if (_index == _questions.length - 1) {
      _timer?.cancel();
      setState(() => _finished = true);
      _saveResult();
    } else {
      setState(() {
        _index++;
        _selected = null;
      });
      _startTimer();
    }
  }

  // Har skill ke sahi aur kul jawab ginta hai.
  Map<String, List<int>> _bySkill() {
    final Map<String, List<int>> bySkill = {};
    for (int i = 0; i < _results.length; i++) {
      final skill = _questions[i].skill;
      bySkill.putIfAbsent(skill, () => [0, 0]);
      bySkill[skill]![1]++;
      if (_results[i]) bySkill[skill]![0]++;
    }
    return bySkill;
  }

  Future<void> _saveResult() async {
    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final Map<String, Map<String, int>> data = {};
    _bySkill().forEach((skill, v) {
      data[QuizService.cleanKey(skill)] = {'correct': v[0], 'total': v[1]};
    });

    final error = await _profileService.saveQuizResult(
      score: _results.where((r) => r).length,
      total: _results.length,
      bySkill: data,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _saved = error == null;
      _errorText = error;
    });
  }

  Future<void> _confirmSignOut() async {
    _timer?.cancel(); // dialog khula ho to timer ruk jaye
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: (_finished || _loading || _loadError != null)
            ? null
            : const Text(
            'Your quiz will start again with new questions when you sign in.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (!mounted) return;

    if (ok == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
      );
    } else if (!_finished &&
        !_loading &&
        _loadError == null &&
        _questions.isNotEmpty) {
      _startTimer(reset: false); // bacha hua time wahin se chale
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
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: _confirmSignOut,
            ),
          ],
        ),
        body: _loading
            ? _buildLoading()
            : _loadError != null
            ? _buildLoadError()
            : _finished
            ? _buildResult()
            : _buildQuestion(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('Preparing your quiz from your skills...',
              style: TextStyle(color: kMuted)),
        ],
      ),
    );
  }

  Widget _buildLoadError() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        AppCard(
          child: Column(
            children: [
              Text(_loadError!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center),
              if (_loadDetails != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_loadDetails!,
                      style: const TextStyle(color: kMuted, fontSize: 12),
                      textAlign: TextAlign.center),
                ),
              const SizedBox(height: 12),
              BigButton(text: 'Try again', onPressed: _start),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_index];
    final isLast = _index == _questions.length - 1;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                  'Question ${_index + 1} of ${_questions.length} · ${q.skill}',
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
            value: _index / _questions.length,
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
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
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
    final bySkill = _bySkill();

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
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700))),
                      Text('${entry.value[0]}/${entry.value[1]}',
                          style: const TextStyle(color: kMuted)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (_isSaving)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_errorText != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_errorText!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
          ),
          BigButton(text: 'Try again', onPressed: _saveResult),
        ] else if (_saved)
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