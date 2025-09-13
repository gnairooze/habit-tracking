import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AddEditHabitScreen extends StatefulWidget {
  final Habit? habit;

  const AddEditHabitScreen({super.key, this.habit});

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  ScheduleType _scheduleType = ScheduleType.daily;
  int _frequency = 1;
  List<TimeOfDay> _times = [const TimeOfDay(hour: 9, minute: 0)];
  List<String> _selectedDays = [];
  List<int> _selectedMonthDays = [];

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final habit = widget.habit!;
    _nameController.text = habit.name;
    _descriptionController.text = habit.description;
    _scheduleType = habit.schedule.type;
    _frequency = habit.schedule.frequency;

    // Parse times
    _times = habit.schedule.times.map((timeString) {
      final parts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }).toList();

    // Parse days
    if (habit.schedule.days != null) {
      if (_scheduleType == ScheduleType.weekly) {
        _selectedDays = List.from(habit.schedule.days!);
      } else if (_scheduleType == ScheduleType.monthly) {
        _selectedMonthDays = habit.schedule.days!.map(int.parse).toList();
      }
    }
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final schedule = HabitSchedule(
        type: _scheduleType,
        frequency: _frequency,
        times: _times
            .map((time) =>
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}')
            .toList(),
        days: _scheduleType == ScheduleType.daily
            ? null
            : _scheduleType == ScheduleType.weekly
                ? _selectedDays
                : _selectedMonthDays.map((day) => day.toString()).toList(),
      );

      final habit = widget.habit?.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            schedule: schedule,
            updatedAt: now,
          ) ??
          Habit(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            schedule: schedule,
            createdAt: now,
            updatedAt: now,
          );

      int habitId;
      if (widget.habit == null) {
        habitId = await DatabaseService.instance.insertHabit(habit);
      } else {
        await DatabaseService.instance.updateHabit(habit);
        habitId = habit.id!;
        // Cancel existing notifications
        await NotificationService.instance.cancelHabitNotifications(habitId);
      }

      // Schedule new notifications
      final savedHabit = habit.copyWith(id: habitId);
      await NotificationService.instance.scheduleHabitNotifications(savedHabit);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving habit: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addTime() {
    setState(() {
      _times.add(const TimeOfDay(hour: 9, minute: 0));
    });
  }

  void _removeTime(int index) {
    if (_times.length > 1) {
      setState(() {
        _times.removeAt(index);
      });
    }
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (picked != null) {
      setState(() {
        _times[index] = picked;
      });
    }
  }

  Widget _buildScheduleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Schedule Type
            DropdownButtonFormField<ScheduleType>(
              value: _scheduleType,
              decoration: const InputDecoration(
                labelText: 'Schedule Type',
                border: OutlineInputBorder(),
              ),
              items: ScheduleType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (ScheduleType? value) {
                if (value != null) {
                  setState(() {
                    _scheduleType = value;
                    _selectedDays.clear();
                    _selectedMonthDays.clear();
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Times
            Text(
              'Times',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._times.asMap().entries.map((entry) {
              final index = entry.key;
              final time = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(index),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(time.format(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_times.length > 1)
                      IconButton(
                        onPressed: () => _removeTime(index),
                        icon: const Icon(Icons.remove_circle),
                      ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addTime,
              icon: const Icon(Icons.add),
              label: const Text('Add Time'),
            ),

            // Days selection for weekly/monthly
            if (_scheduleType == ScheduleType.weekly) ...[
              const SizedBox(height: 16),
              Text(
                'Days of Week',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _weekDays.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],

            if (_scheduleType == ScheduleType.monthly) ...[
              const SizedBox(height: 16),
              Text(
                'Days of Month',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: List.generate(31, (index) {
                  final day = index + 1;
                  final isSelected = _selectedMonthDays.contains(day);
                  return FilterChip(
                    label: Text(day.toString()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedMonthDays.add(day);
                        } else {
                          _selectedMonthDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? 'Add Habit' : 'Edit Habit'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Habit Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a habit name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildScheduleSection(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveHabit,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      widget.habit == null ? 'Create Habit' : 'Update Habit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
