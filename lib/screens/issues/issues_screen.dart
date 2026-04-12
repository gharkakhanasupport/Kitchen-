import 'package:flutter/material.dart';
import '../../models/issue.dart';
import '../../utils/dummy_data.dart';

/// Issues Screen
/// Displays issues/complaints from admin users and delivery boys with filtering
class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  // Colors from the app design system
  static const Color primaryColor = Color(0xFFc1921a);
  static const Color secondaryColor = Color(0xFF2da832);
  static const Color backgroundLight = Color(0xFFfdf8ef);
  static const Color surfaceLight = Color(0xFFffffff);
  static const Color textMain = Color(0xFF171611);
  static const Color textSub = Color(0xFF877d64);
  static const Color borderLight = Color(0xFFe5e2dc);

  List<Issue> _allIssues = [];
  List<Issue> _filteredIssues = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  void _loadIssues() {
    _allIssues = DummyData.getSampleIssues();
    _filteredIssues = _allIssues;
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'All') {
        _filteredIssues = _allIssues;
      } else if (filter == 'Admin') {
        _filteredIssues = _allIssues
            .where((issue) => issue.reporterType == ReporterType.admin)
            .toList();
      } else if (filter == 'Users') {
        _filteredIssues = _allIssues
            .where((issue) => issue.reporterType == ReporterType.customer)
            .toList();
      } else if (filter == 'Delivery Boys') {
        _filteredIssues = _allIssues
            .where((issue) => issue.reporterType == ReporterType.deliveryBoy)
            .toList();
      }
    });
  }

  Color _getStatusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.open:
        return Colors.red;
      case IssueStatus.inProgress:
        return Colors.orange;
      case IssueStatus.resolved:
        return secondaryColor;
    }
  }

  Color _getPriorityColor(IssuePriority priority) {
    switch (priority) {
      case IssuePriority.low:
        return Colors.blue;
      case IssuePriority.medium:
        return Colors.orange;
      case IssuePriority.high:
        return Colors.red;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Issues',
          style: TextStyle(
            color: textMain,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: surfaceLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Admin'),
                const SizedBox(width: 8),
                _buildFilterChip('Users'),
                const SizedBox(width: 8),
                _buildFilterChip('Delivery Boys'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Issues List
          Expanded(
            child: _filteredIssues.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredIssues.length,
                    itemBuilder: (context, index) {
                      return _buildIssueCard(_filteredIssues[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _applyFilter(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? primaryColor : borderLight,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : textSub,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIssueCard(Issue issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and priority
            Row(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(issue.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    issue.statusText,
                    style: TextStyle(
                      color: _getStatusColor(issue.status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(
                      issue.priority,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag,
                        size: 12,
                        color: _getPriorityColor(issue.priority),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        issue.priorityText,
                        style: TextStyle(
                          color: _getPriorityColor(issue.priority),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Time ago
                Text(
                  _getTimeAgo(issue.createdAt),
                  style: const TextStyle(fontSize: 12, color: textSub),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              issue.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textMain,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              issue.description,
              style: const TextStyle(fontSize: 14, color: textSub, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Reporter info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: backgroundLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    issue.reporterType == ReporterType.admin
                        ? Icons.admin_panel_settings
                        : Icons.delivery_dining,
                    size: 16,
                    color: textSub,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.reportedBy,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                      Text(
                        issue.reporterTypeText,
                        style: const TextStyle(fontSize: 11, color: textSub),
                      ),
                    ],
                  ),
                ),
                if (issue.status == IssueStatus.resolved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: secondaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: secondaryColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Resolved',
                          style: TextStyle(
                            fontSize: 11,
                            color: secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: textSub.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No issues found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textSub.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No issues match the selected filter',
            style: TextStyle(
              fontSize: 14,
              color: textSub.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
