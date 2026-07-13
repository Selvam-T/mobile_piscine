import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/diary_date_formatter.dart';
import '../models/diary_emotion.dart';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';
import 'entry_detail_page.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key, required this.user});

  final User user;

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  static const Color _pageBackground = Color(0xFF292929);
  static const Color _barBlue = Color(0xFF173865);
  static const Color _diaryTeal = Color(0xFF79CBC8);
  static const Color _cardBackground = Color(0xFF303030);
  static const Color _cardBorder = Color(0xFF69B8B3);

  final DiaryService _diaryService = DiaryService();
  final ScrollController _entryListController = ScrollController();

  late DateTime _focusedDay;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _entryListController.dispose();
    super.dispose();
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
    });
  }

  void _selectDate(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
      );
      _focusedDay = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _pageBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMonthNavigator(),
                    const SizedBox(height: 18),
                    _buildCalendarSection(),
                    const SizedBox(height: 24),
                    _buildSelectedDateEntriesSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNavigator() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _barBlue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder, width: 2),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _goToPreviousMonth,
            tooltip: 'Previous month',
            color: Colors.white,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              '${DiaryDateFormatter.month(_focusedDay)}, ${_focusedDay.year}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: _goToNextMonth,
            tooltip: 'Next month',
            color: Colors.white,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder, width: 2),
      ),
      child: TableCalendar<void>(
        firstDay: DateTime.utc(2020),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (DateTime day) => isSameDay(day, _selectedDate),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerVisible: false,
        availableGestures: AvailableGestures.horizontalSwipe,
        onDaySelected: _selectDate,
        onPageChanged: (DateTime focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
            color: _diaryTeal,
            fontWeight: FontWeight.w900,
          ),
          weekendStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
            color: _diaryTeal,
            fontWeight: FontWeight.w900,
          ),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          weekendTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          outsideTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: Colors.white.withValues(alpha: 0.28),
            fontWeight: FontWeight.w700,
          ),
          todayDecoration: BoxDecoration(
            color: _diaryTeal.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: _diaryTeal,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: _pageBackground,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDateEntriesSection() {
    return StreamBuilder<List<DiaryEntry>>(
      stream: _diaryService.getEntriesForDate(widget.user.uid, _selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _buildMessageCard(
            'Could not load entries for selected date. ${snapshot.error}',
          );
        }

        final List<DiaryEntry> entries = snapshot.data ?? <DiaryEntry>[];

        if (entries.isEmpty) {
          return _buildMessageCard('No diary entries for this date');
        }

        final double listHeight = (entries.length * 96 + 12)
            .clamp(120, 360)
            .toDouble();

        return SizedBox(
          height: listHeight,
          child: RawScrollbar(
            controller: _entryListController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 8,
            radius: const Radius.circular(999),
            thumbColor: _diaryTeal.withValues(alpha: 0.85),
            trackColor: Colors.transparent,
            trackBorderColor: Colors.transparent,
            child: ListView.separated(
              controller: _entryListController,
              padding: EdgeInsets.zero,
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _AgendaEntryListItem(
                  entry: entries[index],
                  onTap: () => _openEntryDetail(entries[index]),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageCard(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder, width: 2),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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

class _AgendaEntryListItem extends StatelessWidget {
  const _AgendaEntryListItem({required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF303030),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _AgendaPageState._cardBorder, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: _AgendaEntryDate(date: entry.date.toDate()),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 46,
                child: Text(
                  DiaryEmotion.emojiFor(entry.icon),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _AgendaPageState._diaryTeal,
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

class _AgendaEntryDate extends StatelessWidget {
  const _AgendaEntryDate({required this.date});

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
