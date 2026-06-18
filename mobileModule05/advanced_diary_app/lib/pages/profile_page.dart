import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/diary_date_formatter.dart';
import '../models/diary_emotion.dart';
import '../models/diary_entry.dart';
import '../services/auth_service.dart';
import '../services/diary_service.dart';
import 'agenda_page.dart';
import 'entry_detail_page.dart';
import 'new_entry_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.user});

  final User user;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _pageBackground = Color(0xFF292929);
  static const Color _barBlue = Color(0xFF173865);
  static const Color _diaryTeal = Color(0xFF79CBC8);
  static const Color _cardBorder = Color(0xFF69B8B3);

  final AuthService _authService = AuthService();
  final DiaryService _diaryService = DiaryService();
  bool _isSigningOut = false;
  String? _errorMessage;
  int _selectedTabIndex = 0;

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
      _errorMessage = null;
    });

    try {
      await _authService.signOut();
    } on FirebaseAuthException catch (error) {
      _showError(_signOutErrorMessage(error));
    } catch (error) {
      _showError('Sign out failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = message;
    });
  }

  String _signOutErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'network-request-failed':
        return 'Network error. Check your connection and try signing out again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return error.message ?? 'Sign out failed. Code: ${error.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(child: _buildSelectedTab()),
      bottomNavigationBar: NavigationBar(
        backgroundColor: _barBlue,
        indicatorColor: _diaryTeal.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(color: Colors.white),
        ),
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person, color: _diaryTeal),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month, color: _diaryTeal),
            selectedIcon: Icon(Icons.calendar_month, color: Colors.white),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTab() {
    if (_selectedTabIndex == 1) {
      return AgendaPage(user: widget.user);
    }

    return _buildEntryListTab();
  }

  Widget _buildEntryListTab() {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      _buildErrorText(_errorMessage!),
                      const SizedBox(height: 14),
                    ],
                    _buildLastEntriesSection(),
                    const SizedBox(height: 30),
                    _buildFeelingsSection(),
                    const SizedBox(height: 24),
                    _buildNewEntryButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final User user = widget.user;
    final String userLabel = _userDisplayLabel(user);

    return SizedBox(
      height: 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/profile_bg.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.48)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: _diaryTeal,
                    backgroundImage: AssetImage('assets/images/dog.jpg'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 92),
                  child: Center(
                    child: Text(
                      userLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: _isSigningOut ? null : _signOut,
                    tooltip: 'Logout',
                    color: Colors.white,
                    icon: _isSigningOut
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.logout),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _userDisplayLabel(User user) {
    final String? displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final String? email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'Signed-in user';
  }

  Widget _buildLastEntriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Last 2 Entries',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<DiaryEntry>>(
          stream: _diaryService.getLastEntries(widget.user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorText(
                'Could not load diary entries. ${snapshot.error}',
              );
            }

            final List<DiaryEntry> entries = snapshot.data ?? <DiaryEntry>[];

            if (entries.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                for (int index = 0; index < entries.length; index++) ...[
                  if (index > 0) const SizedBox(height: 12),
                  _DiaryEntryListItem(
                    entry: entries[index],
                    onTap: () => _openEntryDetail(entries[index]),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeelingsSection() {
    return StreamBuilder<List<DiaryEntry>>(
      stream: _diaryService.getEntries(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorText(
            'Could not load feeling ratios. ${snapshot.error}',
          );
        }

        final List<DiaryEntry> entries = snapshot.data ?? <DiaryEntry>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Feeling ratio for ${entries.length} entries',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeelingRatios(entries),
          ],
        );
      },
    );
  }

  Widget _buildFeelingRatios(List<DiaryEntry> entries) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF303030),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _cardBorder, width: 2),
        ),
        child: Text(
          'No feelings yet',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    final Map<String, int> feelingCounts = <String, int>{};
    for (final DiaryEntry entry in entries) {
      final String feeling = entry.icon.trim().toLowerCase();
      feelingCounts[feeling] = (feelingCounts[feeling] ?? 0) + 1;
    }

    final List<DiaryEmotion> usedFeelings = DiaryEmotion.options
        .where(
          (DiaryEmotion emotion) => feelingCounts.containsKey(emotion.value),
        )
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder, width: 2),
      ),
      child: Column(
        children: [
          for (int index = 0; index < usedFeelings.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            _FeelingRatioChip(
              emoji: usedFeelings[index].emoji,
              percentage:
                  ((feelingCounts[usedFeelings[index].value]! /
                              entries.length) *
                          100)
                      .round(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNewEntryButton() {
    return Center(
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
          onPressed: _openNewEntry,
          child: const Text(
            'New Diary Entry',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder, width: 2),
      ),
      child: Text(
        'No diary entries yet',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildErrorText(String message) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFFFFB4AB)),
    );
  }

  Future<void> _openNewEntry() async {
    final bool? wasCreated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => NewEntryPage(user: widget.user)),
    );

    if (!mounted || wasCreated != true) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Diary entry saved.')));
  }

  Future<void> _openEntryDetail(DiaryEntry entry) async {
    final bool? wasDeleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EntryDetailPage(entry: entry, user: widget.user),
      ),
    );

    if (!mounted || wasDeleted != true) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Diary entry deleted.')));
  }
}

class _DiaryEntryListItem extends StatelessWidget {
  const _DiaryEntryListItem({required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF303030),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _ProfilePageState._cardBorder, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              SizedBox(width: 70, child: _EntryDate(date: entry.date.toDate())),
              const SizedBox(width: 14),
              SizedBox(
                width: 46,
                child: Text(
                  DiaryEmotion.emojiFor(entry.icon),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _ProfilePageState._diaryTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(width: 1.4, height: 58, color: Colors.white),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeelingRatioChip extends StatelessWidget {
  const _FeelingRatioChip({required this.emoji, required this.percentage});

  final String emoji;
  final int percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 8),
        Text(
          '$percentage%',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _EntryDate extends StatelessWidget {
  const _EntryDate({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${date.day}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 0.95,
          ),
        ),
        Text(
          DiaryDateFormatter.month(date),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        Text(
          '${date.year}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}
