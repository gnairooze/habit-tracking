class Alert {
  final int? id;
  final int habitId;
  final String habitName;
  final String habitDescription;
  final DateTime scheduledDateTime;
  final AlertStatus status;
  final DateTime? completedAt;
  final DateTime createdAt;

  const Alert({
    this.id,
    required this.habitId,
    required this.habitName,
    required this.habitDescription,
    required this.scheduledDateTime,
    this.status = AlertStatus.pending,
    this.completedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'habit_name': habitName,
      'habit_description': habitDescription,
      'scheduled_date_time': scheduledDateTime.millisecondsSinceEpoch,
      'status': status.toString(),
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  static Alert fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'],
      habitId: map['habit_id'],
      habitName: map['habit_name'],
      habitDescription: map['habit_description'],
      scheduledDateTime:
          DateTime.fromMillisecondsSinceEpoch(map['scheduled_date_time']),
      status: AlertStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
      ),
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Alert copyWith({
    int? id,
    int? habitId,
    String? habitName,
    String? habitDescription,
    DateTime? scheduledDateTime,
    AlertStatus? status,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return Alert(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      habitName: habitName ?? this.habitName,
      habitDescription: habitDescription ?? this.habitDescription,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum AlertStatus {
  pending,
  done,
  skipped,
}
