class Alert {
  final int? id;
  final int habitId;
  final String habitName;
  final String habitDescription;
  final DateTime scheduledDateTime;
  final AlertStatus status;
  final DateTime? completedDateTime;

  Alert({
    this.id,
    required this.habitId,
    required this.habitName,
    required this.habitDescription,
    required this.scheduledDateTime,
    this.status = AlertStatus.pending,
    this.completedDateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'habit_name': habitName,
      'habit_description': habitDescription,
      'scheduled_date_time': scheduledDateTime.millisecondsSinceEpoch,
      'status': status.toString().split('.').last,
      'completed_date_time': completedDateTime?.millisecondsSinceEpoch,
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    final status = AlertStatus.values.firstWhere(
      (e) => e.toString().split('.').last == map['status'],
    );

    return Alert(
      id: map['id'],
      habitId: map['habit_id'],
      habitName: map['habit_name'],
      habitDescription: map['habit_description'],
      scheduledDateTime: DateTime.fromMillisecondsSinceEpoch(map['scheduled_date_time']),
      status: status,
      completedDateTime: map['completed_date_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_date_time'])
          : null,
    );
  }

  Alert copyWith({
    int? id,
    int? habitId,
    String? habitName,
    String? habitDescription,
    DateTime? scheduledDateTime,
    AlertStatus? status,
    DateTime? completedDateTime,
  }) {
    return Alert(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      habitName: habitName ?? this.habitName,
      habitDescription: habitDescription ?? this.habitDescription,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      status: status ?? this.status,
      completedDateTime: completedDateTime ?? this.completedDateTime,
    );
  }
}

enum AlertStatus {
  pending,
  done,
  skipped,
}
