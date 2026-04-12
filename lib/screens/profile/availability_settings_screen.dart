import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/profile_service.dart';

class AvailabilitySettingsScreen extends StatefulWidget {
  const AvailabilitySettingsScreen({super.key});

  @override
  State<AvailabilitySettingsScreen> createState() =>
      _AvailabilitySettingsScreenState();
}

class _AvailabilitySettingsScreenState
    extends State<AvailabilitySettingsScreen> {
  final _profileService = ProfileService();
  bool _isOnline = true;
  bool _isLoading = true;

  // Mock schedule data
  final Map<String, TimeRange> _schedule = {
    'Monday': const TimeRange(start: '10:00 AM', end: '10:00 PM', isOpen: true),
    'Tuesday': const TimeRange(
      start: '10:00 AM',
      end: '10:00 PM',
      isOpen: true,
    ),
    'Wednesday': const TimeRange(
      start: '10:00 AM',
      end: '10:00 PM',
      isOpen: true,
    ),
    'Thursday': const TimeRange(
      start: '10:00 AM',
      end: '10:00 PM',
      isOpen: true,
    ),
    'Friday': const TimeRange(start: '10:00 AM', end: '11:00 PM', isOpen: true),
    'Saturday': const TimeRange(
      start: '11:00 AM',
      end: '11:00 PM',
      isOpen: true,
    ),
    'Sunday': const TimeRange(start: '11:00 AM', end: '10:00 PM', isOpen: true),
  };

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final profile = await _profileService.getCurrentProfile();
    if (mounted) {
      setState(() {
        _isOnline = profile?.isAvailable ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStatus(bool value) async {
    setState(() => _isOnline = value);
    await _profileService.toggleAvailability();
  }

  Future<void> _editSchedule(String day, TimeRange range) async {
    final result = await showModalBottomSheet<TimeRange>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ScheduleEditor(day: day, initialRange: range),
    );

    if (result != null) {
      setState(() {
        _schedule[day] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text(
          'Kitchen Availability',
          style: TextStyle(
            color: Color(0xFF111814),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111814)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Master Switch
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isOnline
                                ? AppColors.secondary.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.power_settings_new,
                            color: _isOnline
                                ? AppColors.secondary
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isOnline
                                    ? 'Accepting Orders'
                                    : 'Kitchen Offline',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111814),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isOnline
                                    ? 'Customers can place orders now'
                                    : 'You will appear offline to customers',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isOnline,
                          onChanged: _toggleStatus,
                          activeTrackColor: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Weekly Schedule
                  const Text(
                    'Weekly Schedule',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111814),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set your standard operating hours. You can always toggle availability manually.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _schedule.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final day = _schedule.keys.elementAt(index);
                        final timeRange = _schedule[day]!;
                        return ListTile(
                          title: Text(
                            day,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timeRange.isOpen
                                    ? '${timeRange.start} - ${timeRange.end}'
                                    : 'Closed',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: timeRange.isOpen
                                      ? const Color(0xFF111814)
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Color(0xFF9CA3AF),
                              ),
                            ],
                          ),
                          onTap: () => _editSchedule(day, timeRange),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ScheduleEditor extends StatefulWidget {
  final String day;
  final TimeRange initialRange;

  const _ScheduleEditor({required this.day, required this.initialRange});

  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  late bool _isOpen;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.initialRange.isOpen;
    _startTime = _parseTime(widget.initialRange.start);
    _endTime = _parseTime(widget.initialRange.end);
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(' '); // "10:00 AM"
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      if (parts[1] == 'PM' && hour != 12) hour += 12;
      if (parts[1] == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Schedule - ${widget.day}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111814),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Open for Business',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Switch(
                value: _isOpen,
                onChanged: (value) => setState(() => _isOpen = value),
                activeTrackColor: AppColors.secondary,
              ),
            ],
          ),
          if (_isOpen) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Open Time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(_startTime),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Close Time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(_endTime),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  TimeRange(
                    start: _formatTime(_startTime),
                    end: _formatTime(_endTime),
                    isOpen: _isOpen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class TimeRange {
  final String start;
  final String end;
  final bool isOpen;

  const TimeRange({
    required this.start,
    required this.end,
    required this.isOpen,
  });
}
