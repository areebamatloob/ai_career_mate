import 'package:flutter/material.dart';
import '../sample_data.dart';
import '../theme.dart';
import 'profile_screen.dart';
import 'resume_screen.dart';

class HomeScreen extends StatelessWidget {
  /// Tells the main shell to switch to another tab.
  final void Function(int) onOpenTab;
  const HomeScreen({super.key, required this.onOpenTab});

  Widget _tile(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: kSoft, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: kPrimary),
            ),
            const Spacer(),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: kMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = sampleCareers.first;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
              color: kPrimary, borderRadius: BorderRadius.circular(26)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hi $sampleName',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Your goal: ${top.title} · ${top.match}% match',
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => onOpenTab(2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: const Color(0xFF2B1A00),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Continue roadmap'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: [
            _tile(context, Icons.track_changes, 'Career matches',
                'Fit and skill gaps', () => onOpenTab(1)),
            _tile(context, Icons.map_outlined, 'Roadmap',
                'Plan, resources, progress', () => onOpenTab(2)),
            _tile(context, Icons.description_outlined, 'Resume',
                'Built from your facts', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ResumeScreen()));
            }),
            _tile(context, Icons.mic_none, 'Interview prep', 'Real feedback',
                () => onOpenTab(3)),
            _tile(context, Icons.smart_toy_outlined, 'Ask career mate',
                'Questions anytime', () => onOpenTab(4)),
            _tile(context, Icons.person_outline, 'My profile',
                'Edit your details', () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProfileScreen(isEdit: true)));
            }),
          ],
        ),
      ],
    );
  }
}
