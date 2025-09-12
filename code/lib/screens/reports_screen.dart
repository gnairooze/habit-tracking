import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert.dart';
import '../services/database_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Alert> _alerts = [];
  bool _isLoading = false;
  
  final TextEditingController _habitNameController = TextEditingController();
  final TextEditingController _habitDescriptionController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadAllAlerts();
  }

  @override
  void dispose() {
    _habitNameController.dispose();
    _habitDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAllAlerts() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await DatabaseService.getAlerts();
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    }
  }

  Future<void> _searchAlerts() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await DatabaseService.searchAlerts(
        fromDate: _fromDate,
        toDate: _toDate,
        habitName: _habitNameController.text.trim().isEmpty 
            ? null 
            : _habitNameController.text.trim(),
        habitDescription: _habitDescriptionController.text.trim().isEmpty 
            ? null 
            : _habitDescriptionController.text.trim(),
      );
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching alerts: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate ?? DateTime.now() : _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _habitNameController.clear();
      _habitDescriptionController.clear();
    });
    _loadAllAlerts();
  }

  Map<AlertStatus, int> _getStatusCounts() {
    final counts = <AlertStatus, int>{
      AlertStatus.pending: 0,
      AlertStatus.done: 0,
      AlertStatus.skipped: 0,
    };
    
    for (final alert in _alerts) {
      counts[alert.status] = (counts[alert.status] ?? 0) + 1;
    }
    
    return counts;
  }

  double _getCompletionRate() {
    if (_alerts.isEmpty) return 0.0;
    final doneCount = _alerts.where((a) => a.status == AlertStatus.done).length;
    final totalCompleted = _alerts.where((a) => a.status != AlertStatus.pending).length;
    return totalCompleted > 0 ? (doneCount / totalCompleted) * 100 : 0.0;
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

  @override
  Widget build(BuildContext context) {
    final statusCounts = _getStatusCounts();
    final completionRate = _getCompletionRate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Search Filters
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Filters',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _habitNameController,
                          decoration: const InputDecoration(
                            labelText: 'Habit Name',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _habitDescriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'From Date',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            child: Text(
                              _fromDate != null 
                                  ? DateFormat('MMM dd, yyyy').format(_fromDate!)
                                  : 'Select date',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'To Date',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            child: Text(
                              _toDate != null 
                                  ? DateFormat('MMM dd, yyyy').format(_toDate!)
                                  : 'Select date',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _searchAlerts,
                          icon: const Icon(Icons.search),
                          label: const Text('Search'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Statistics
          if (!_isLoading && _alerts.isNotEmpty)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistics',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Total',
                          _alerts.length.toString(),
                          Colors.blue,
                        ),
                        _buildStatItem(
                          'Done',
                          statusCounts[AlertStatus.done].toString(),
                          Colors.green,
                        ),
                        _buildStatItem(
                          'Skipped',
                          statusCounts[AlertStatus.skipped].toString(),
                          Colors.orange,
                        ),
                        _buildStatItem(
                          'Completion',
                          '${completionRate.toStringAsFixed(1)}%',
                          Colors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _alerts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No alerts found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search filters or create some habits.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _alerts.length,
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(alert.status),
                                radius: 16,
                                child: Icon(
                                  alert.status == AlertStatus.done
                                      ? Icons.check
                                      : alert.status == AlertStatus.skipped
                                          ? Icons.skip_next
                                          : Icons.schedule,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                alert.habitName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(alert.habitDescription),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Scheduled: ${DateFormat('MMM dd, yyyy - hh:mm a').format(alert.scheduledDateTime)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (alert.completedDateTime != null)
                                    Text(
                                      'Completed: ${DateFormat('MMM dd, yyyy - hh:mm a').format(alert.completedDateTime!)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(
                                  alert.status.toString().split('.').last.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: _getStatusColor(alert.status).withOpacity(0.2),
                                side: BorderSide(color: _getStatusColor(alert.status)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
