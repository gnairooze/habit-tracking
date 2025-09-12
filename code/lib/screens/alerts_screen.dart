import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert.dart';
import '../services/database_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Alert> _alerts = [];
  bool _isLoading = true;
  bool _showPendingOnly = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final alerts = _showPendingOnly 
          ? await DatabaseService.getPendingAlerts()
          : await DatabaseService.getAlerts();
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading alerts: $e')),
        );
      }
    }
  }

  Future<void> _updateAlertStatus(Alert alert, AlertStatus status) async {
    try {
      final updatedAlert = alert.copyWith(
        status: status,
        completedDateTime: status != AlertStatus.pending ? DateTime.now() : null,
      );
      await DatabaseService.updateAlert(updatedAlert);
      _loadAlerts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == AlertStatus.done 
                  ? 'Habit marked as done!' 
                  : 'Habit skipped',
            ),
            backgroundColor: status == AlertStatus.done 
                ? Colors.green 
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating alert: $e')),
        );
      }
    }
  }

  void _showAlertDialog(Alert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.habitName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.habitDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Scheduled: ${DateFormat('MMM dd, yyyy - hh:mm a').format(alert.scheduledDateTime)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateAlertStatus(alert, AlertStatus.skipped);
            },
            child: const Text('SKIP'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateAlertStatus(alert, AlertStatus.done);
            },
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AlertStatus status) {
    switch (status) {
      case AlertStatus.pending:
        return Colors.blue;
      case AlertStatus.done:
        return Colors.green;
      case AlertStatus.skipped:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(AlertStatus status) {
    switch (status) {
      case AlertStatus.pending:
        return Icons.schedule;
      case AlertStatus.done:
        return Icons.check_circle;
      case AlertStatus.skipped:
        return Icons.skip_next;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<bool>(
            icon: const Icon(Icons.filter_list),
            onSelected: (showPendingOnly) {
              setState(() {
                _showPendingOnly = showPendingOnly;
              });
              _loadAlerts();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: _showPendingOnly ? Theme.of(context).primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Pending Only'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: false,
                child: Row(
                  children: [
                    Icon(
                      Icons.list,
                      color: !_showPendingOnly ? Theme.of(context).primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('All Alerts'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
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
                        _showPendingOnly 
                            ? 'No pending alerts' 
                            : 'No alerts found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _showPendingOnly
                            ? 'Great job! You\'re all caught up.'
                            : 'Create some habits to see alerts here.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAlerts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];
                      final isOverdue = alert.status == AlertStatus.pending &&
                          alert.scheduledDateTime.isBefore(DateTime.now());
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isOverdue ? Colors.red[50] : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(alert.status),
                            child: Icon(
                              _getStatusIcon(alert.status),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            alert.habitName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(alert.habitDescription),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy - hh:mm a')
                                    .format(alert.scheduledDateTime),
                                style: TextStyle(
                                  color: isOverdue ? Colors.red : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              if (alert.completedDateTime != null)
                                Text(
                                  'Completed: ${DateFormat('MMM dd - hh:mm a').format(alert.completedDateTime!)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: alert.status == AlertStatus.pending
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _updateAlertStatus(alert, AlertStatus.skipped),
                                      icon: const Icon(Icons.skip_next),
                                      color: Colors.orange,
                                    ),
                                    IconButton(
                                      onPressed: () => _updateAlertStatus(alert, AlertStatus.done),
                                      icon: const Icon(Icons.check),
                                      color: Colors.green,
                                    ),
                                  ],
                                )
                              : null,
                          onTap: alert.status == AlertStatus.pending
                              ? () => _showAlertDialog(alert)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
