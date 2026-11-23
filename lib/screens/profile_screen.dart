import 'package:flutter/material.dart';
import '../theme.dart';
import 'quiz_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  /// true when opened later from Home to edit the profile.
  final bool isEdit;
  const ProfileScreen({super.key, this.isEdit = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fieldController = TextEditingController();
  final _skillsController = TextEditingController();
  final _interestsController = TextEditingController();
  final _goalController = TextEditingController();
  final _projectsController = TextEditingController();
  final _certsController = TextEditingController();

  String _type = 'Student';
  String _education = 'High school';
  final _profileService = ProfileService();
  bool _isSaving = false;
  String? _errorText;
  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final data = await _profileService.loadProfile();
    if (!mounted) return;
    setState(() {
      _nameController.text = data?['name'] ??
          FirebaseAuth.instance.currentUser?.displayName ??
          '';
      if (data != null) {
        _type = data['type'] ?? _type;
        _education = data['education'] ?? _education;
        _fieldController.text = data['field'] ?? '';
        _skillsController.text = data['skills'] ?? '';
        _interestsController.text = data['interests'] ?? '';
        _goalController.text = data['goal'] ?? '';
        _projectsController.text = data['projects'] ?? '';
        _certsController.text = data['certs'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fieldController.dispose();
    _skillsController.dispose();
    _interestsController.dispose();
    _goalController.dispose();
    _projectsController.dispose();
    _certsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final error = await _profileService.saveProfile({
      'name': _nameController.text.trim(),
      'type': _type,
      'education': _education,
      'field': _fieldController.text.trim(),
      'skills': _skillsController.text.trim(),
      'interests': _interestsController.text.trim(),
      'goal': _goalController.text.trim(),
      'projects': _projectsController.text.trim(),
      'certs': _certsController.text.trim(),
      'profileComplete': true,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    if (widget.isEdit) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const QuizScreen()),
      );
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
    );
  }


  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Name'),
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your name'
                          : null,
                    ),
                    _label('I am a'),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_type),
                      initialValue: _type,
                      items: ['Student', 'Job seeker']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                    _label('Education level'),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_education),
                      initialValue: _education,
                      items: [
                        'High school',
                        'Diploma',
                        'Bachelor (in progress)',
                        'Bachelor (completed)',
                        'Master',
                      ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _education = v!),
                    ),
                    _label('Field of study'),
                    TextFormField(
                      controller: _fieldController,
                      decoration:
                          const InputDecoration(hintText: 'e.g. Computer Science'),
                    ),
                    _label('Skills (comma separated)'),
                    TextFormField(
                      controller: _skillsController,
                      decoration: const InputDecoration(
                          hintText: 'e.g. Python, Excel, Communication'),
                      validator: (v) {
                        final skills = (v ?? '')
                            .split(',')
                            .where((s) => s.trim().isNotEmpty)
                            .toList();
                        return skills.length < 2
                            ? 'List at least 2 skills, separated by commas'
                            : null;
                      },
                    ),
                    _label('Interests'),
                    TextFormField(
                      controller: _interestsController,
                      decoration: const InputDecoration(
                          hintText: 'e.g. data, design, helping people'),
                    ),
                    _label('Career goal (optional)'),
                    TextFormField(
                      controller: _goalController,
                      decoration: const InputDecoration(
                          hintText: 'e.g. work at a tech company'),
                    ),
                    _label('Projects'),
                    TextFormField(
                      controller: _projectsController,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(hintText: 'What did you build or do?'),
                    ),
                    _label('Certifications'),
                    TextFormField(controller: _certsController),
                  ],
                ),
              ),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_errorText!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center),
                ),
              if (_isSaving)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                BigButton(
                  text: widget.isEdit
                      ? 'Save profile'
                      : 'Save and start skills quiz',
                  onPressed: _save,
                ),
              if (widget.isEdit)
                Center(
                  child: TextButton(
                    onPressed: _signOut,
                    child: const Text('Sign out',
                        style: TextStyle(color: Colors.red)),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
