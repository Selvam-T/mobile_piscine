import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/diary_date_formatter.dart';
import '../models/diary_emotion.dart';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';

class EntryDetailPage extends StatefulWidget {
  const EntryDetailPage({super.key, required this.entry, required this.user});

  final DiaryEntry entry;
  final User user;

  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  static const Color _pageBackground = Color(0xFF292929);
  static const Color _barBlue = Color(0xFF173865);
  static const Color _dangerRed = Color(0xFFB3261E);
  static const Color _errorText = Color(0xFFFFB4AB);

  final DiaryService _diaryService = DiaryService();

  bool _isDeleting = false;
  String? _errorMessage;

  Future<void> _confirmDelete() async {
    final bool shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF303030),
              title: const Text(
                'Delete this entry?',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'This cannot be undone.',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _dangerRed,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    await _deleteEntry();
  }

  Future<void> _deleteEntry() async {
    final String? entryId = widget.entry.id;

    if (entryId == null || entryId.isEmpty) {
      setState(() {
        _errorMessage =
            'Cannot delete this entry because it has no document ID.';
      });
      return;
    }

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await _diaryService.deleteEntry(entryId);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not delete this entry. $error';
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DiaryEntry entry = widget.entry;
    final DateTime entryDate = entry.date.toDate();

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: _barBlue,
        foregroundColor: Colors.white,
        title: const Text('Diary Entry'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    DiaryDateFormatter.fullDate(entryDate),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    DiaryEmotion.emojiFor(entry.icon),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 52),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    entry.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        entry.text,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _errorText),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: 230,
                      height: 58,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _dangerRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _isDeleting ? null : _confirmDelete,
                        child: _isDeleting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Delete this entry',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
