/// Enum representing who reported the issue
enum ReporterType { admin, deliveryBoy, customer }

/// Enum representing issue status
enum IssueStatus { open, inProgress, resolved }

/// Enum representing issue priority
enum IssuePriority { low, medium, high }

/// Model class representing an Issue/Complaint
class Issue {
  final String id;
  final String title;
  final String description;
  final String reportedBy;
  final ReporterType reporterType;
  final IssueStatus status;
  final IssuePriority priority;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.reportedBy,
    required this.reporterType,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.resolvedAt,
  });

  /// Create Issue from Map
  factory Issue.fromMap(Map<String, dynamic> map) {
    return Issue(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      reportedBy: map['reportedBy'] ?? '',
      reporterType: ReporterType.values.firstWhere(
        (e) => e.toString() == 'ReporterType.${map['reporterType']}',
        orElse: () => ReporterType.customer,
      ),
      status: IssueStatus.values.firstWhere(
        (e) => e.toString() == 'IssueStatus.${map['status']}',
        orElse: () => IssueStatus.open,
      ),
      priority: IssuePriority.values.firstWhere(
        (e) => e.toString() == 'IssuePriority.${map['priority']}',
        orElse: () => IssuePriority.medium,
      ),
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.parse(map['resolvedAt'])
          : null,
    );
  }

  /// Convert Issue to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reportedBy': reportedBy,
      'reporterType': reporterType.toString().split('.').last,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  /// Create a copy of Issue with some fields updated
  Issue copyWith({
    String? id,
    String? title,
    String? description,
    String? reportedBy,
    ReporterType? reporterType,
    IssueStatus? status,
    IssuePriority? priority,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return Issue(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reportedBy: reportedBy ?? this.reportedBy,
      reporterType: reporterType ?? this.reporterType,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  /// Get status display text
  String get statusText {
    switch (status) {
      case IssueStatus.open:
        return 'Open';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.resolved:
        return 'Resolved';
    }
  }

  /// Get priority display text
  String get priorityText {
    switch (priority) {
      case IssuePriority.low:
        return 'Low';
      case IssuePriority.medium:
        return 'Medium';
      case IssuePriority.high:
        return 'High';
    }
  }

  /// Get reporter type display text
  String get reporterTypeText {
    switch (reporterType) {
      case ReporterType.admin:
        return 'Admin User';
      case ReporterType.deliveryBoy:
        return 'Delivery Boy';
      case ReporterType.customer:
        return 'Customer';
    }
  }
}
