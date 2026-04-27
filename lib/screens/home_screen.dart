import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'categories/categories_tab.dart';
import 'collections/collections_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AppAuthProvider>().user?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? 'Collections' : 'Categories'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'signout') {
                await context.read<AppAuthProvider>().signOut();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(email, style: Theme.of(context).textTheme.bodySmall),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [CollectionsTab(), CategoriesTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark),
            label: 'Collections',
          ),
          NavigationDestination(
            icon: Icon(Icons.label_outline),
            selectedIcon: Icon(Icons.label),
            label: 'Categories',
          ),
        ],
      ),
    );
  }
}
