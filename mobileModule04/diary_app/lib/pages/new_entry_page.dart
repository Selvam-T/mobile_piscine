import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/diary_emotion.dart';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';

class NewEntryPage extends StatefulWidget {
  const NewEntryPage({super.key, required this.user});

  final User user;

  @override
  State<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  static const Color _pageBackground = Color(0xFF292929);
  static const Color _barBlue = Color(0xFF173865);
  static const Color _diaryTeal = Color(0xFF79CBC8);
  static const Color _fieldFill = Color(0xFF303030);
  static const Color _errorText = Color(0xFFFFB4AB);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final DiaryService _diaryService = DiaryService();

  String _selectedEmotion = DiaryEmotion.options.first.value;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final User user = widget.user;
    final DiaryEntry entry = DiaryEntry(
      uid: user.uid,
      usermail: user.email ?? '',
      date: Timestamp.now(),
      icon: _selectedEmotion,
      title: _titleController.text.trim(),
      text: _textController.text.trim(),
    );

    try {
      await _diaryService.createEntry(entry);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not save this entry. $error';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: _barBlue,
        foregroundColor: Colors.white,
        title: const Text('New Diary Entry'),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      enabled: !_isSaving,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Title'),
                      textInputAction: TextInputAction.next,
                      validator: _requiredText,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedEmotion,
                      dropdownColor: _fieldFill,
                      decoration: _inputDecoration('Emotion'),
                      iconEnabledColor: _diaryTeal,
                      style: const TextStyle(color: Colors.white),
                      items: DiaryEmotion.options.map((DiaryEmotion emotion) {
                        return DropdownMenuItem<String>(
                          value: emotion.value,
                          child: Text('${emotion.emoji}  ${emotion.label}'),
                        );
                      }).toList(),
                      onChanged: _isSaving
                          ? null
                          : (String? value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _selectedEmotion = value;
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _textController,
                        enabled: !_isSaving,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Text'),
                        validator: _requiredText,
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
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        width: 230,
                        height: 58,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _diaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveEntry,
                          child: _isSaving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Entry',
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
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _diaryTeal),
      filled: true,
      fillColor: _fieldFill,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _diaryTeal, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorText, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorText, width: 2),
      ),
      errorStyle: const TextStyle(color: _errorText),
    );
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }
}
