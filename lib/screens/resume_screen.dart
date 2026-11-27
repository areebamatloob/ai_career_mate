import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/profile_service.dart';
import '../services/resume_service.dart';
import '../theme.dart';

String _s(dynamic v) => (v ?? '').toString().trim();

List<String> _split(String text, RegExp sep) => text
    .split(sep)
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

// Profile ke woh hisse jinse resume banta hai. AI ka text tab hi dikhta
// hai jab profile iske baad badla na ho.
String _basis(Map<String, dynamic> p) => [
  p['type'],
  p['education'],
  p['field'],
  p['skills'],
  p['interests'],
  p['projects'],
  p['certs'],
  p['goalCareer'],
].map(_s).join('|');

class _ResumeData {
  String name = '';
  String contact = '';
  String education = '';
  String summary = '';
  List<String> skills = [];
  List<String> projects = [];
  List<String> certs = [];
  bool aiUsed = false;
}

// AI ke baghair, sirf facts se chhota summary.
String _basicSummary(Map<String, dynamic> p, List<String> skills) {
  final type = _s(p['type']);
  final edu = _s(p['education']);
  final field = _s(p['field']);
  final b = StringBuffer();
  b.write(type.isEmpty ? 'Candidate' : type);
  if (edu.isNotEmpty) {
    b.write(' with $edu');
    if (field.isNotEmpty) b.write(' in $field');
  }
  b.write('.');
  if (skills.isNotEmpty) b.write(' Skills include ${skills.take(5).join(', ')}.');
  final goal = _s(p['goalCareer']);
  if (goal.isNotEmpty) b.write(' Aiming for a career as $goal.');
  return b.toString();
}

_ResumeData _build(Map<String, dynamic> p) {
  final user = FirebaseAuth.instance.currentUser;
  final d = _ResumeData();

  d.name = _s(p['name']);
  if (d.name.isEmpty) d.name = user?.displayName ?? 'Your name';
  d.contact = user?.email ?? '';
  d.education = [_s(p['education']), _s(p['field'])]
      .where((e) => e.isNotEmpty)
      .join(' · ');
  d.skills = _split(_s(p['skills']), RegExp(r'[,\n]'));
  d.certs = _split(_s(p['certs']), RegExp(r'[,\n]'));

  final ai = p['resumeAi'];
  if (ai is Map && ai['basis'] == _basis(p)) {
    d.summary = _s(ai['summary']);
    final list = ai['projects'];
    if (list is List) {
      d.projects =
          list.map((e) => _s(e)).where((e) => e.isNotEmpty).toList();
    }
    d.aiUsed = d.summary.isNotEmpty;
  }
  if (d.summary.isEmpty) d.summary = _basicSummary(p, d.skills);
  if (d.projects.isEmpty) {
    d.projects = _split(_s(p['projects']), RegExp(r'\n'));
  }
  return d;
}

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final _profileService = ProfileService();
  final _ai = ResumeService();

  Map<String, dynamic>? _profile;
  _ResumeData? _data;
  bool _loading = true;
  bool _improving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _profileService.loadProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _data = p == null ? null : _build(p);
      _loading = false;
    });
  }

  Future<void> _improve() async {
    final p = _profile;
    if (p == null || _improving) return;
    setState(() {
      _improving = true;
      _errorText = null;
    });

    final result = await _ai.improve(p);
    if (!mounted) return;

    if (result == null) {
      setState(() {
        _improving = false;
        _errorText = _ai.lastError ?? 'Could not improve your resume.';
      });
      return;
    }

    final saved = {
      'summary': result['summary'],
      'projects': result['projects'],
      'basis': _basis(p),
    };
    await _profileService.saveProfile({'resumeAi': saved});
    if (!mounted) return;

    final updated = Map<String, dynamic>.from(p)..['resumeAi'] = saved;
    setState(() {
      _profile = updated;
      _data = _build(updated);
      _improving = false;
    });
  }

  // ---------- PDF ----------

  pw.Widget _pdfSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 14),
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800)),
        pw.Divider(thickness: 0.5),
        ...children,
      ],
    );
  }

  Future<Uint8List> _buildPdf(_ResumeData d) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(d.name,
              style:
              pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          if (d.education.isNotEmpty) pw.Text(d.education),
          if (d.contact.isNotEmpty) pw.Text(d.contact),
          _pdfSection('SUMMARY', [pw.Text(d.summary)]),
          if (d.skills.isNotEmpty)
            _pdfSection('SKILLS', [pw.Text(d.skills.join(', '))]),
          if (d.projects.isNotEmpty)
            _pdfSection('PROJECTS', [
              for (final p in d.projects) pw.Bullet(text: p),
            ]),
          if (d.education.isNotEmpty)
            _pdfSection('EDUCATION', [pw.Text(d.education)]),
          if (d.certs.isNotEmpty)
            _pdfSection('CERTIFICATIONS', [
              for (final c in d.certs) pw.Bullet(text: c),
            ]),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> _downloadPdf() async {
    final d = _data;
    if (d == null) return;
    try {
      await Printing.layoutPdf(
        name: 'resume.pdf',
        onLayout: (format) => _buildPdf(d),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not make the PDF: $e')),
      );
    }
  }

  // ---------- Screen ----------

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: kPrimary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resume')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Fill in and save your profile first. Your resume is built from it.',
              textAlign: TextAlign.center),
        ),
      )
          : _content(_data!),
    );
  }

  Widget _content(_ResumeData d) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              color: kAccentSoft, borderRadius: BorderRadius.circular(12)),
          child: Text(
            d.aiUsed
                ? 'Polished by AI using only the facts in your profile. Read it before you send it.'
                : 'Built only from the facts in your profile. Tap "Improve with AI" for better wording.',
            style: const TextStyle(fontSize: 13),
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
              Text(d.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              if (d.education.isNotEmpty) Text(d.education),
              if (d.contact.isNotEmpty)
                Text(d.contact, style: const TextStyle(color: kMuted)),
              _heading('SUMMARY'),
              Text(d.summary),
              if (d.skills.isNotEmpty) ...[
                _heading('SKILLS'),
                Text(d.skills.join(', ')),
              ],
              if (d.projects.isNotEmpty) ...[
                _heading('PROJECTS'),
                for (final p in d.projects) Text('• $p'),
              ],
              if (d.education.isNotEmpty) ...[
                _heading('EDUCATION'),
                Text(d.education),
              ],
              if (d.certs.isNotEmpty) ...[
                _heading('CERTIFICATIONS'),
                for (final c in d.certs) Text('• $c'),
              ],
            ],
          ),
        ),
        if (d.projects.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Tip: add your projects in your profile to make the resume stronger.',
              style: TextStyle(color: kMuted, fontSize: 13),
            ),
          ),
        const SizedBox(height: 14),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center),
          ),
        if (_improving)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else
          BigButton(
              text: d.aiUsed ? 'Improve again with AI' : 'Improve with AI',
              soft: true,
              onPressed: _improve),
        const SizedBox(height: 8),
        BigButton(text: 'Download PDF', onPressed: _downloadPdf),
      ],
    );
  }
}