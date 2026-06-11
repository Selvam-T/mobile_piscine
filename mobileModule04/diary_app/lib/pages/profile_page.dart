import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/diary_entry.dart';
import '../services/auth_service.dart';
import '../services/diary_service.dart';

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
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: _barBlue,
        foregroundColor: Colors.white,
        title: const Text('Your Diary Entries'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        actions: [
          TextButton(
            onPressed: _isSigningOut ? null : _signOut,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: _isSigningOut
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Sign out'),
          ),
        ],
      ),
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
      return _buildCalendarPlaceholder();
    }

    return _buildEntryListTab();
  }

  Widget _buildEntryListTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUserSummary(),
              const SizedBox(height: 18),
              if (_errorMessage != null) ...[
                _buildErrorText(_errorMessage!),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: StreamBuilder<List<DiaryEntry>>(
                  stream: _diaryService.getEntries(widget.user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return _buildErrorText(
                        'Could not load diary entries. ${snapshot.error}',
                      );
                    }

                    final List<DiaryEntry> entries =
                        snapshot.data ?? <DiaryEntry>[];

                    if (entries.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _DiaryEntryListItem(
                          entry: entries[index],
                          onTap: () =>
                              _showEntryDetailPlaceholder(entries[index]),
                        );
                      },
                    );
                  },
                ),
              ),
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
                    onPressed: _showNewEntryPlaceholder,
                    child: const Text(
                      'New Diary Entry',
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
    );
  }

  Widget _buildUserSummary() {
    final User user = widget.user;
    final String userEmail = user.email ?? 'Signed-in user';

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _diaryTeal,
          backgroundImage: const AssetImage('assets/images/dog.jpg'),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            userEmail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/diary.png',
            height: 160,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          Text(
            'No diary entries yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPlaceholder() {
    return const Center(
      child: Text(
        'Calendar view coming later',
        style: TextStyle(color: Colors.white),
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

  void _showNewEntryPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New entry page comes in Step 7')),
    );
  }

  void _showEntryDetailPlaceholder(DiaryEntry entry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Detail page for "${entry.title}" comes later')),
    );
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
                  entry.icon,
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
          _monthName(date),
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

  String _monthName(DateTime date) {
    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[date.month - 1];
  }
}
