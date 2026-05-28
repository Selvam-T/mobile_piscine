import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: BottomBar());
  }
}

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  final TextEditingController searchController = TextEditingController();
  String locationText = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void updateLocationText(String text) {
    setState(() {
      locationText = text;
    });
  }

  void useGeolocation() {
    searchController.clear();
    updateLocationText('Geolocation');
  }

  Widget buildTabContent(String tabName) {
    final String displayText = locationText.isEmpty
        ? tabName
        : '$tabName\n$locationText';

    return Center(child: Text(displayText, textAlign: TextAlign.center));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 8,
          title: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.search),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: updateLocationText,
                        decoration: const InputDecoration(
                          hintText: 'Search location...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32, child: VerticalDivider(thickness: 1)),
              IconButton(
                icon: const Icon(Icons.near_me),
                onPressed: useGeolocation,
              ),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            buildTabContent('Currently'),
            buildTabContent('Today'),
            buildTabContent('Weekly'),
          ],
        ),

        bottomNavigationBar: BottomAppBar(
          child: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.settings), text: 'Currently'),
              Tab(icon: Icon(Icons.today), text: 'Today'),
              Tab(icon: Icon(Icons.view_week_outlined), text: 'Weekly'),
            ],
          ),
        ),
      ),
    );
  }
}
