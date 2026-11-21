import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class ReconsultationOfferDialog extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const ReconsultationOfferDialog({
    super.key,
    required this.appointment,
  });

  @override
  State<ReconsultationOfferDialog> createState() =>
      _ReconsultationOfferDialogState();
}

class _ReconsultationOfferDialogState extends State<ReconsultationOfferDialog> {
  static const int _maxSlots = 6;

  final List<Map<String, String>> _slots = [];
  DateTime? _selectedDate;
  String? _selectedTime;
  List<Map<String, dynamic>> _availableSlots = [];
  bool _loadingSlots = false;
  bool _saving = false;

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year, now.month, now.day + 90),
      helpText: 'Choose an available follow-up date',
    );
    if (selected == null || !mounted) return;

    setState(() {
      _selectedDate = selected;
      _selectedTime = null;
      _availableSlots = [];
      _loadingSlots = true;
    });

    try {
      final doctorId = widget.appointment['doctorId']?.toString().trim() ?? '';
      final consultationType =
          widget.appointment['consultationType']?.toString().trim() ??
              'Hospital Visit';
      final available = await ApiService.getAvailableSlots(
        doctorId: doctorId,
        date: _dateKey(selected),
        consultationType: consultationType,
      );
      if (!mounted) return;
      setState(() {
        _availableSlots = available
            .where((slot) => slot['available'] == true)
            .toList();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load available times: $error')),
      );
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  void _addSelectedTime() {
    final date = _selectedDate;
    final time = _selectedTime;
    if (date == null || time == null) return;
    if (_slots.length >= _maxSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can offer up to six time options.')),
      );
      return;
    }

    final slot = <String, String>{'date': _dateKey(date), 'time': time};
    if (_slots.any((item) => item['date'] == slot['date'] && item['time'] == time)) {
      return;
    }
    setState(() {
      _slots.add(slot);
      _selectedTime = null;
    });
  }

  Future<void> _sendOffer() async {
    if (_saving || _slots.isEmpty) return;
    final appointmentId = widget.appointment['_id']?.toString().trim() ?? '';
    if (appointmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment ID is missing.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiService.createOrUpdateReconsultationOffer(
        appointmentId: appointmentId,
        slots: List<Map<String, String>>.from(_slots),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to send reconsultation offer: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _selectedDate;
    final consultationType =
        widget.appointment['consultationType']?.toString().trim() ??
            'Hospital Visit';

    return AlertDialog(
      title: const Text('Offer free reconsultation'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose up to six available $consultationType times. The patient will select one and send a free appointment request.',
                style: const TextStyle(height: 1.35, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadingSlots || _saving ? null : _chooseDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  selectedDate == null
                      ? 'Choose a date'
                      : _formatDate(selectedDate),
                ),
              ),
              if (_loadingSlots) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ] else if (selectedDate != null) ...[
                const SizedBox(height: 12),
                if (_availableSlots.isEmpty)
                  const Text(
                    'No available times on this date. Choose another date.',
                    style: TextStyle(color: Colors.black54),
                  )
                else ...[
                  const Text(
                    'Available times',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _availableSlots.map((slot) {
                      final time = slot['time']?.toString() ?? '';
                      return ChoiceChip(
                        label: Text(time),
                        selected: _selectedTime == time,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _selectedTime = time),
                      );
                    }).toList(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed:
                          _selectedTime == null || _saving ? null : _addSelectedTime,
                      icon: const Icon(Icons.add),
                      label: const Text('Add time'),
                    ),
                  ),
                ],
              ],
              const Divider(height: 24),
              Text(
                'Offered times (${_slots.length}/$_maxSlots)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_slots.isEmpty)
                const Text(
                  'Add at least one time for the patient to choose.',
                  style: TextStyle(color: Colors.black54),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _slots.map((slot) {
                    final date = DateTime.parse(slot['date']!);
                    return InputChip(
                      label: Text('${_formatDate(date)} • ${slot['time']}'),
                      onDeleted: _saving
                          ? null
                          : () => setState(() => _slots.remove(slot)),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _saving || _slots.isEmpty ? null : _sendOffer,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(_saving ? 'Sending...' : 'Send offer'),
        ),
      ],
    );
  }
}
