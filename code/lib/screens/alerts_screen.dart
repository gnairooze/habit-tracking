import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Alert> _pendingAlerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingAlerts();
  }

  Future<void> _loadPendingAlerts() async {
    setState(() => _isLoading = true);
    final alerts = await DatabaseService.instance.getPendingAlerts();
    setState(() {
      _pendingAlerts = alerts;
      _isLoading = false;
    });
  }

  Future<void> _markAsDone(Alert alert) async {
    final updatedAlert = alert.copyWith(
      status: AlertStatus.done,
      completedAt: DateTime.now(),
    );

    await DatabaseService.instance.updateAlert(updatedAlert);
    await NotificationService.instance.cancelNotification(alert.id!);
    await _loadPendingAlerts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked "${alert.habitName}" as done!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _markAsSkipped(Alert alert) async {
    final updatedAlert = alert.copyWith(
      status: AlertStatus.skipped,
      completedAt: DateTime.now(),
    );

    await DatabaseService.instance.updateAlert(updatedAlert);
    await NotificationService.instance.cancelNotification(alert.id!);
    await _loadPendingAlerts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Skipped "${alert.habitName}"'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final alertDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (alertDate == today) {
      return 'Today at ${DateFormat.jm().format(dateTime)}';
    } else if (alertDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at ${DateFormat.jm().format(dateTime)}';
    } else if (alertDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow at ${DateFormat.jm().format(dateTime)}';
    } else {
      return DateFormat('MMM d, y \'at\' h:mm a').format(dateTime);
    }
  }

  bool _isOverdue(DateTime scheduledDateTime) {
    return scheduledDateTime.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingAlerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending alerts',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All caught up! Great job!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingAlerts,
                  child: ListView.builder(
                    itemCount: _pendingAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = _pendingAlerts[index];
                      final isOverdue = _isOverdue(alert.scheduledDateTime);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: isOverdue ? Colors.red.shade50 : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      alert.habitName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (isOverdue)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'OVERDUE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                alert.habitDescription,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: isOverdue
                                        ? Colors.red
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDateTime(alert.scheduledDateTime),
                                    style: TextStyle(
                                      color: isOverdue
                                          ? Colors.red
                                          : Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: isOverdue
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _markAsSkipped(alert),
                                    icon: const Icon(Icons.skip_next),
                                    label: const Text('Skip'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _markAsDone(alert),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Done'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
