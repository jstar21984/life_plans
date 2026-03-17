import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

enum TaskFilter { all, today, upcoming, completed }

class TaskProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  
  List<Task> _tasks = [];
  bool _isLoading = false;
  TaskFilter _currentFilter = TaskFilter.all;
  String? _selectedCategoryId;

  List<Task> get tasks => _getFilteredTasks();
  List<Task> get allTasks => _tasks;
  bool get isLoading => _isLoading;
  TaskFilter get currentFilter => _currentFilter;
  String? get selectedCategoryId => _selectedCategoryId;

  List<Task> _getFilteredTasks() {
    List<Task> filtered = List.from(_tasks);

    if (_selectedCategoryId != null) {
      filtered = filtered.where((t) => t.categoryId == _selectedCategoryId).toList();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    switch (_currentFilter) {
      case TaskFilter.all:
        break;
      case TaskFilter.today:
        filtered = filtered.where((t) {
          if (t.dueDate == null) return false;
          return t.dueDate!.isAfter(today.subtract(const Duration(seconds: 1))) &&
              t.dueDate!.isBefore(tomorrow);
        }).toList();
        break;
      case TaskFilter.upcoming:
        filtered = filtered.where((t) {
          if (t.dueDate == null) return false;
          return t.dueDate!.isAfter(tomorrow.subtract(const Duration(seconds: 1)));
        }).toList();
        break;
      case TaskFilter.completed:
        filtered = filtered.where((t) => t.isCompleted).toList();
        break;
    }

    filtered.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) {
        return b.createdAt.compareTo(a.createdAt);
      }
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return filtered;
  }

  void setFilter(TaskFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void setSelectedCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    _tasks = await _db.getTasks();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    await _db.insertTask(task);
    _tasks.add(task);
    if (task.notificationEnabled && task.dueDate != null) {
      await _notificationService.scheduleTaskNotification(task);
    }
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
    await _notificationService.cancelTaskNotification(task.id);
    if (task.notificationEnabled && task.dueDate != null) {
      await _notificationService.scheduleTaskNotification(task);
    }
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    
    if (updatedTask.isCompleted && 
        task.recurrenceType != RecurrenceType.none && 
        task.dueDate != null) {
      final nextRecurrence = task.getNextRecurrence();
      await addTask(nextRecurrence);
    }
    
    await updateTask(updatedTask);
  }

  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
    await _notificationService.cancelTaskNotification(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  List<Task> getTasksByCategory(String categoryId) {
    return _tasks.where((t) => t.categoryId == categoryId).toList();
  }
}
