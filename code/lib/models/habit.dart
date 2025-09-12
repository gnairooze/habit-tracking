class Habit {
  final int? id;
  final String name;
  final String description;
  final HabitSchedule schedule;
  final bool alertEnabled;

  Habit({
    this.id,
    required this.name,
    required this.description,
    required this.schedule,
    this.alertEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'schedule_type': schedule.type.toString().split('.').last,
      'occurrences_per_period': schedule.occurrencesPerPeriod,
      'selected_days': schedule.selectedDays?.join(','),
      'times': schedule.times.map((t) => '${t.hour}:${t.minute}').join(','),
      'alert_enabled': alertEnabled ? 1 : 0,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    final scheduleType = ScheduleType.values.firstWhere(
      (e) => e.toString().split('.').last == map['schedule_type'],
    );
    
    final selectedDays = map['selected_days'] != null 
        ? (map['selected_days'] as String).split(',').map(int.parse).toList()
        : null;
    
    final times = (map['times'] as String).split(',').map((timeStr) {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();

    return Habit(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      schedule: HabitSchedule(
        type: scheduleType,
        occurrencesPerPeriod: map['occurrences_per_period'],
        selectedDays: selectedDays,
        times: times,
      ),
      alertEnabled: map['alert_enabled'] == 1,
    );
  }

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    HabitSchedule? schedule,
    bool? alertEnabled,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      schedule: schedule ?? this.schedule,
      alertEnabled: alertEnabled ?? this.alertEnabled,
    );
  }
}

class HabitSchedule {
  final ScheduleType type;
  final int occurrencesPerPeriod;
  final List<int>? selectedDays; // For weekly/monthly: days of week/month
  final List<TimeOfDay> times;

  HabitSchedule({
    required this.type,
    required this.occurrencesPerPeriod,
    this.selectedDays,
    required this.times,
  });
}

enum ScheduleType {
  daily,
  weekly,
  monthly,
}

class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  String get formatted {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => formatted;
}
