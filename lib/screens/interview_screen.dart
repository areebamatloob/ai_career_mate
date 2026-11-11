import 'package:flutter/material.dart';
import '../sample_data.dart';
import '../theme.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final _answerController = TextEditingController();
  int _index = 0;
  bool _showFeedback = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _getFeedback() {
    if (_answerController.text.trim().length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a real answer first (a sentence or two).')),
      );
      return;
    }
    // TODO: send the answer to the AI backend and show its real feedback.
    setState(() => _showFeedback = true);
  }

  void _nextQuestion() {
    setState(() {
      _index = (_index + 1) % sampleInterviewQuestions.length;
      _showFeedback = false;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmallTag('Question ${_index + 1} of ${sampleInterviewQuestions.length}'),
              const SizedBox(height: 10),
              Text(sampleInterviewQuestions[_index],
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        TextField(
          controller: _answerController,
          maxLines: 5,
          readOnly: _showFeedback,
          decoration: const InputDecoration(hintText: 'Type your answer'),
        ),
        const SizedBox(height: 10),
        if (!_showFeedback) BigButton(text: 'Get feedback', onPressed: _getFeedback),
        if (_showFeedback) _feedbackCard(),
      ],
    );
  }

  Widget _feedbackCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                  child: Text('Feedback',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              Text('–/10',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: kPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          const SmallTag('Layout preview'),
          const SizedBox(height: 8),
          const Text(
              'When the AI is connected, it will read your real answer here, give a score, and explain what worked and what to improve.'),
          const SizedBox(height: 12),
          const Text('What worked', style: TextStyle(fontWeight: FontWeight.w800)),
          const Text('• Points from your answer will appear here.'),
          const SizedBox(height: 8),
          const Text('Improve', style: TextStyle(fontWeight: FontWeight.w800)),
          const Text('• Tips for a better answer will appear here.'),
          const SizedBox(height: 14),
          BigButton(text: 'Next question', onPressed: _nextQuestion),
          const SizedBox(height: 8),
          BigButton(
            text: 'Try this question again',
            soft: true,
            onPressed: () => setState(() => _showFeedback = false),
          ),
        ],
      ),
    );
  }
}
