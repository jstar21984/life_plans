import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/task_card.dart';
import 'add_edit_task_screen.dart';
import 'calendar_screen.dart';

const String _appNameKey = 'app_name';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showCalendar = true;
  String _appName = 'Life Plans';

  @override
  void initState() {
    super.initState();
    _loadAppName();
  }

  Future<void> _loadAppName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_appNameKey) ?? 'Life Plans';
    if (mounted) {
      setState(() {
        _appName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _appName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showAboutDialog(context),
                    tooltip: 'About',
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.calendar_month),
                        tooltip: 'Calendar',
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.list),
                        tooltip: 'List',
                      ),
                    ],
                    selected: {_showCalendar},
                    onSelectionChanged: (Set<bool> selection) {
                      setState(() {
                        _showCalendar = selection.first;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (!_showCalendar) _buildFilterChips(context),
            Expanded(
              child: _showCalendar ? const CalendarScreen() : _buildTaskList(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: taskProvider.currentFilter == TaskFilter.all,
                onSelected: () => taskProvider.setFilter(TaskFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Today',
                selected: taskProvider.currentFilter == TaskFilter.today,
                onSelected: () => taskProvider.setFilter(TaskFilter.today),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Upcoming',
                selected: taskProvider.currentFilter == TaskFilter.upcoming,
                onSelected: () => taskProvider.setFilter(TaskFilter.upcoming),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Completed',
                selected: taskProvider.currentFilter == TaskFilter.completed,
                onSelected: () => taskProvider.setFilter(TaskFilter.completed),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskList(BuildContext context) {
    return Consumer2<TaskProvider, CategoryProvider>(
      builder: (context, taskProvider, categoryProvider, _) {
        if (taskProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = taskProvider.tasks;

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add your first task',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 80),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final category = categoryProvider.getCategoryById(task.categoryId);

            return TaskCard(
              task: task,
              category: category,
              onTap: () => _openEditTask(context, task),
              onToggleComplete: () => taskProvider.toggleTaskCompletion(task),
              onDelete: () => taskProvider.deleteTask(task.id),
            );
          },
        );
      },
    );
  }

  void _openAddTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddEditTaskScreen(),
    );
  }

  void _openEditTask(BuildContext context, task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditTaskScreen(task: task),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Life Plans',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.task_alt, size: 48),
      children: [
        const Text(
          'A privacy-focused task scheduler with calendar view, '
          'categories, recurring tasks, and cloud sync support.',
        ),
        const SizedBox(height: 16),
        const Text(
          'License: GNU General Public License v3.0\n'
          'Copyright (C) 2024',
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
