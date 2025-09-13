class Habit {
  final int? id;
  final String name;
  final String description;
  final HabitSchedule schedule;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Habit({
    this.id,
    required this.name,
    required this.description,
    required this.schedule,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'schedule_type': schedule.type.toString(),
      'schedule_frequency': schedule.frequency,
      'schedule_times': schedule.times.join(','),
      'schedule_days': schedule.days?.join(','),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  static Habit fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      schedule: HabitSchedule(
        type: ScheduleType.values.firstWhere(
          (e) => e.toString() == map['schedule_type'],
        ),
        frequency: map['schedule_frequency'],
        times: map['schedule_times']
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList(),
        days: map['schedule_days']
            ?.split(',')
            .where((s) => s.isNotEmpty)
            .toList(),
      ),
      isActive: map['is_active'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    HabitSchedule? schedule,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      schedule: schedule ?? this.schedule,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum ScheduleType {
  daily,
  weekly,
  monthly,
}

class HabitSchedule {
  final ScheduleType type;
  final int
      frequency; // number of times (daily: 1-N times, weekly: 1-7 days, monthly: 1-31 days)
  final List<String> times; // time of day for each occurrence (HH:mm format)
  final List<String>? days; // for weekly: day names, for monthly: day numbers

  const HabitSchedule({
    required this.type,
    required this.frequency,
    required this.times,
    this.days,
  });

  HabitSchedule copyWith({
    ScheduleType? type,
    int? frequency,
    List<String>? times,
    List<String>? days,
  }) {
    return HabitSchedule(
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      days: days ?? this.days,
    );
  }
}
