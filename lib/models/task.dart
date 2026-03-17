import 'package:uuid/uuid.dart';

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
}

class Task {
  final String id;
  final String title;
  final String? description;
  final String? categoryId;
  final DateTime? dueDate;
  final bool isCompleted;
  final RecurrenceType recurrenceType;
  final bool notificationEnabled;
  final DateTime createdAt;

  Task({
    String? id,
    required this.title,
    this.description,
    this.categoryId,
    this.dueDate,
    this.isCompleted = false,
    this.recurrenceType = RecurrenceType.none,
    this.notificationEnabled = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    DateTime? dueDate,
    bool? isCompleted,
    RecurrenceType? recurrenceType,
    bool? notificationEnabled,
    DateTime? createdAt,
    bool clearDescription = false,
    bool clearCategoryId = false,
    bool clearDueDate = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isCompleted: isCompleted ?? this.isCompleted,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'recurrenceType': recurrenceType.index,
      'notificationEnabled': notificationEnabled ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      categoryId: map['categoryId'] as String?,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      isCompleted: (map['isCompleted'] as int) == 1,
      recurrenceType: RecurrenceType.values[map['recurrenceType'] as int],
      notificationEnabled: (map['notificationEnabled'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Task getNextRecurrence() {
    if (recurrenceType == RecurrenceType.none || dueDate == null) {
      throw Exception('Task is not recurring');
    }

    DateTime nextDueDate;
    switch (recurrenceType) {
      case RecurrenceType.daily:
        nextDueDate = dueDate!.add(const Duration(days: 1));
        break;
      case RecurrenceType.weekly:
        nextDueDate = dueDate!.add(const Duration(days: 7));
        break;
      case RecurrenceType.monthly:
        nextDueDate = DateTime(
          dueDate!.year,
          dueDate!.month + 1,
          dueDate!.day,
          dueDate!.hour,
          dueDate!.minute,
        );
        break;
      case RecurrenceType.none:
        throw Exception('Task is not recurring');
    }

    return copyWith(
      dueDate: nextDueDate,
      isCompleted: false,
    );
  }
}
