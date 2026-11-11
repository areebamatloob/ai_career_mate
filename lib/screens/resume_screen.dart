import 'package:flutter/material.dart';
import '../theme.dart';

class ResumeScreen extends StatelessWidget {
  const ResumeScreen({super.key});

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: kPrimary)),
    );
  }

  void _soon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resume')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: kAccentSoft, borderRadius: BorderRadius.circular(12)),
            child: const Text(
              'Sample preview. The real resume will be built only from the facts in your profile.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Name',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const Text('Education · Field of study'),
                _heading('SUMMARY'),
                const Text('A short summary about you will appear here.'),
                _heading('SKILLS'),
                const Text('Your skills will appear here.'),
                _heading('PROJECTS'),
                const Text('Your projects will appear here.'),
                _heading('EDUCATION'),
                const Text('Your education will appear here.'),
                _heading('CERTIFICATIONS'),
                const Text('Your certifications will appear here.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BigButton(
              text: 'Improve with AI',
              soft: true,
              onPressed: () => _soon(context, 'AI will be connected later.')),
          const SizedBox(height: 8),
          BigButton(
              text: 'Download PDF',
              onPressed: () => _soon(context, 'Download will be added later.')),
        ],
      ),
    );
  }
}
