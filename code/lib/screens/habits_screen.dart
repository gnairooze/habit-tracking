import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'add_edit_habit_screen.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Habit> _habits = [];
  List<Habit> _filteredHabits = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
    _searchController.addListener(_filterHabits);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    try {
      final habits = await DatabaseService.getHabits();
      setState(() {
        _habits = habits;
        _filteredHabits = habits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading habits: $e')),
        );
      }
    }
  }

  void _filterHabits() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHabits = _habits.where((habit) {
        return habit.name.toLowerCase().contains(query) ||
               habit.description.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService.deleteHabit(habit.id!);
        await NotificationService.cancelHabitNotifications(habit.id!);
        _loadHabits();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Habit deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting habit: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Habits'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search habits',
                hintText: 'Search by name or description',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHabits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.list_alt,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No habits yet. Add your first habit!'
                                  : 'No habits found matching your search.',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHabits,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredHabits.length,
                          itemBuilder: (context, index) {
                            final habit = _filteredHabits[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  habit.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(habit.description),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getScheduleDescription(habit.schedule),
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => AddEditHabitScreen(habit: habit),
                                        ),
                                      ).then((_) => _loadHabits());
                                    } else if (value == 'delete') {
                                      _deleteHabit(habit);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: habit.alertEnabled
                                      ? Colors.green
                                      : Colors.grey,
                                  child: Icon(
                                    habit.alertEnabled
                                        ? Icons.notifications_active
                                        : Icons.notifications_off,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditHabitScreen(),
            ),
          ).then((_) => _loadHabits());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getScheduleDescription(HabitSchedule schedule) {
    String frequency = '';
    switch (schedule.type) {
      case ScheduleType.daily:
        frequency = 'Daily';
        break;
      case ScheduleType.weekly:
        frequency = 'Weekly';
        break;
      case ScheduleType.monthly:
        frequency = 'Monthly';
        break;
    }
    
    final times = schedule.times.map((t) => t.formatted).join(', ');
    return '$frequency • ${schedule.occurrencesPerPeriod}x • $times';
  }
}
