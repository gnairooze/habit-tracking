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
  int _occurrences = 1;
  List<int> _selectedDays = [];
  List<TimeOfDay> _times = [const TimeOfDay(hour: 9, minute: 0)];
  bool _alertEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _nameController.text = widget.habit!.name;
      _descriptionController.text = widget.habit!.description;
      _scheduleType = widget.habit!.schedule.type;
      _occurrences = widget.habit!.schedule.occurrencesPerPeriod;
      _selectedDays = widget.habit!.schedule.selectedDays ?? [];
      _times = List.from(widget.habit!.schedule.times);
      _alertEnabled = widget.habit!.alertEnabled;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final schedule = HabitSchedule(
        type: _scheduleType,
        occurrencesPerPeriod: _occurrences,
        selectedDays: _selectedDays.isEmpty ? null : _selectedDays,
        times: _times,
      );

      final habit = Habit(
        id: widget.habit?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        schedule: schedule,
        alertEnabled: _alertEnabled,
      );

      if (widget.habit == null) {
        final id = await DatabaseService.insertHabit(habit);
        final savedHabit = habit.copyWith(id: id);
        if (_alertEnabled) {
          await NotificationService.scheduleHabitNotifications(savedHabit);
        }
      } else {
        await DatabaseService.updateHabit(habit);
        if (_alertEnabled) {
          await NotificationService.scheduleHabitNotifications(habit);
        } else {
          await NotificationService.cancelHabitNotifications(habit.id!);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.habit == null 
                ? 'Habit created successfully' 
                : 'Habit updated successfully'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving habit: $e')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? 'Add Habit' : 'Edit Habit'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            TextButton(
              onPressed: _saveHabit,
              child: const Text('SAVE'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 24),
            Text(
              'Schedule',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ScheduleType>(
              value: _scheduleType,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: ScheduleType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _scheduleType = value!;
                  _selectedDays.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _occurrences.toString(),
              decoration: InputDecoration(
                labelText: 'Occurrences per ${_scheduleType.toString().split('.').last}',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter number of occurrences';
                }
                final num = int.tryParse(value);
                if (num == null || num <= 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onChanged: (value) {
                final num = int.tryParse(value);
                if (num != null) {
                  _occurrences = num;
                }
              },
            ),
            if (_scheduleType != ScheduleType.daily) ...[
              const SizedBox(height: 16),
              Text(
                _scheduleType == ScheduleType.weekly 
                    ? 'Select Days of Week' 
                    : 'Select Days of Month',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildDaySelector(),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reminder Times',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: _addTime,
                  icon: const Icon(Icons.add_circle),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._times.asMap().entries.map((entry) {
              final index = entry.key;
              final time = entry.value;
              return Card(
                child: ListTile(
                  title: Text(time.formatted),
                  trailing: _times.length > 1
                      ? IconButton(
                          onPressed: () => _removeTime(index),
                          icon: const Icon(Icons.remove_circle),
                        )
                      : null,
                  onTap: () => _selectTime(index),
                ),
              );
            }),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Get reminders for this habit'),
              value: _alertEnabled,
              onChanged: (value) {
                setState(() {
                  _alertEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    if (_scheduleType == ScheduleType.weekly) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return Wrap(
        spacing: 8,
        children: List.generate(7, (index) {
          final dayNumber = index + 1;
          final isSelected = _selectedDays.contains(dayNumber);
          return FilterChip(
            label: Text(weekdays[index]),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedDays.add(dayNumber);
                } else {
                  _selectedDays.remove(dayNumber);
                }
              });
            },
          );
        }),
      );
    } else {
      // Monthly - days 1-31
      return Wrap(
        spacing: 4,
        children: List.generate(31, (index) {
          final dayNumber = index + 1;
          final isSelected = _selectedDays.contains(dayNumber);
          return FilterChip(
            label: Text(dayNumber.toString()),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedDays.add(dayNumber);
                } else {
                  _selectedDays.remove(dayNumber);
                }
              });
            },
          );
        }),
      );
    }
  }
}
