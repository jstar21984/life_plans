import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  String? _selectedCategoryId;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  RecurrenceType _recurrenceType = RecurrenceType.none;
  bool _notificationEnabled = false;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    
    if (widget.task != null) {
      _selectedCategoryId = widget.task!.categoryId;
      _dueDate = widget.task!.dueDate;
      if (_dueDate != null) {
        _dueTime = TimeOfDay.fromDateTime(_dueDate!);
      }
      _recurrenceType = widget.task!.recurrenceType;
      _notificationEnabled = widget.task!.notificationEnabled;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isEditing ? 'Edit Task' : 'Add Task',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildCategorySelector(context),
                const SizedBox(height: 16),
                _buildDateTimePicker(context),
                const SizedBox(height: 16),
                _buildRecurrenceSelector(context),
                const SizedBox(height: 16),
                _buildNotificationToggle(context),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saveTask,
                    child: Text(isEditing ? 'Save Changes' : 'Add Task'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, _) {
        final categories = categoryProvider.categories;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('No Category'),
                ),
                ...categories.map((cat) => DropdownMenuItem(
                  value: cat.id,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(cat.colorValue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(cat.name),
                    ],
                  ),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateTimePicker(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Due Date & Time', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _dueDate != null
                      ? DateFormat('MMM d, yyyy').format(_dueDate!)
                      : 'Select Date',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _dueDate != null ? () => _selectTime(context) : null,
                icon: const Icon(Icons.access_time),
                label: Text(
                  _dueTime != null
                      ? _dueTime!.format(context)
                      : 'Select Time',
                ),
              ),
            ),
            if (_dueDate != null)
              IconButton(
                onPressed: () {
                  setState(() {
                    _dueDate = null;
                    _dueTime = null;
                  });
                },
                icon: const Icon(Icons.clear),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecurrenceSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Repeat', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<RecurrenceType>(
          segments: const [
            ButtonSegment(value: RecurrenceType.none, label: Text('None')),
            ButtonSegment(value: RecurrenceType.daily, label: Text('Daily')),
            ButtonSegment(value: RecurrenceType.weekly, label: Text('Weekly')),
            ButtonSegment(value: RecurrenceType.monthly, label: Text('Monthly')),
          ],
          selected: {_recurrenceType},
          onSelectionChanged: (Set<RecurrenceType> selection) {
            setState(() {
              _recurrenceType = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotificationToggle(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      title: const Text('Reminder'),
      subtitle: Text(
        _notificationEnabled
            ? 'Get notified 15 minutes before'
            : 'No reminder',
        style: theme.textTheme.bodySmall,
      ),
      value: _notificationEnabled,
      onChanged: (value) {
        setState(() {
          _notificationEnabled = value;
        });
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _dueDate = date;
        _dueTime ??= const TimeOfDay(hour: 9, minute: 0);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _dueTime = time;
      });
    }
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    DateTime? finalDueDate;
    if (_dueDate != null && _dueTime != null) {
      finalDueDate = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime!.hour,
        _dueTime!.minute,
      );
    }

    final taskProvider = context.read<TaskProvider>();

    if (isEditing) {
      final updatedTask = widget.task!.copyWith(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        categoryId: _selectedCategoryId,
        dueDate: finalDueDate,
        recurrenceType: _recurrenceType,
        notificationEnabled: _notificationEnabled,
        clearDescription: _descriptionController.text.isEmpty,
        clearCategoryId: _selectedCategoryId == null,
        clearDueDate: finalDueDate == null,
      );
      taskProvider.updateTask(updatedTask);
    } else {
      final newTask = Task(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        categoryId: _selectedCategoryId,
        dueDate: finalDueDate,
        recurrenceType: _recurrenceType,
        notificationEnabled: _notificationEnabled,
      );
      taskProvider.addTask(newTask);
    }

    Navigator.pop(context);
  }
}
