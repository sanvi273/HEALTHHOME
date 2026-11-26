import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class DoctorPrescriptionTemplateEditor extends StatefulWidget {
  const DoctorPrescriptionTemplateEditor({super.key});

  @override
  State<DoctorPrescriptionTemplateEditor> createState() =>
      _DoctorPrescriptionTemplateEditorState();
}

class _DoctorPrescriptionTemplateEditorState
    extends State<DoctorPrescriptionTemplateEditor> {
  static const _accent = Color(0xff14B8A6);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<_TemplateMedicineDraft> _medicines = [_TemplateMedicineDraft()];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    for (final medicine in _medicines) {
      medicine.dispose();
    }
    super.dispose();
  }

  void _addMedicine() {
    setState(() => _medicines.add(_TemplateMedicineDraft()));
  }

  void _removeMedicine(int index) {
    if (_medicines.length == 1) return;
    setState(() => _medicines.removeAt(index).dispose());
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_medicines.any((medicine) =>
        !medicine.morning && !medicine.afternoon && !medicine.night)) {
      _showMessage('Choose at least one time of day for each medicine.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await ApiService.createDoctorPrescriptionTemplate(
        template: {
          'name': _nameController.text.trim(),
          'medicines': _medicines
              .map((medicine) => {
                    'medicine': medicine.name.text.trim(),
                    'dose': medicine.dose.text.trim(),
                    'duration': medicine.duration.text.trim(),
                    'food': medicine.food,
                    'instruction': medicine.instruction.text.trim(),
                    'morning': medicine.morning,
                    'afternoon': medicine.afternoon,
                    'night': medicine.night,
                  })
              .toList(),
        },
      );
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Unable to save template.');
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _decoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, color: _accent),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
    );
  }

  Widget _buildMedicineCard(int index) {
    final medicine = _medicines[index];
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication_outlined, color: _accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Medicine ${index + 1}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_medicines.length > 1)
                  IconButton(
                    tooltip: 'Remove medicine',
                    onPressed: () => _removeMedicine(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: medicine.name,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration('Medicine name', icon: Icons.medication),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Enter the medicine name.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: medicine.dose,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Dosage', icon: Icons.medical_information_outlined),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Enter the dosage.'
                  : null,
            ),
            const SizedBox(height: 14),
            const Text('When to take', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Morning'),
                  selected: medicine.morning,
                  onSelected: (value) => setState(() => medicine.morning = value),
                ),
                FilterChip(
                  label: const Text('Afternoon'),
                  selected: medicine.afternoon,
                  onSelected: (value) => setState(() => medicine.afternoon = value),
                ),
                FilterChip(
                  label: const Text('Night'),
                  selected: medicine.night,
                  onSelected: (value) => setState(() => medicine.night = value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: medicine.food,
              decoration: _decoration('Food timing', icon: Icons.restaurant_outlined),
              items: const [
                DropdownMenuItem(value: 'Before Food', child: Text('Before Food')),
                DropdownMenuItem(value: 'After Food', child: Text('After Food')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => medicine.food = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: medicine.duration,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Duration', icon: Icons.calendar_month_outlined),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Enter the duration.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: medicine.instruction,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Instructions (optional)', icon: Icons.notes_outlined),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        title: const Text('Add Medicine Template'),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Save medicines you commonly prescribe, then choose this template when writing a prescription.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Template name', icon: Icons.bookmark_outline),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Enter a template name.'
                  : null,
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < _medicines.length; index++)
              _buildMedicineCard(index),
            OutlinedButton.icon(
              onPressed: _addMedicine,
              icon: const Icon(Icons.add),
              label: const Text('Add another medicine'),
              style: OutlinedButton.styleFrom(foregroundColor: _accent),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveTemplate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving template…' : 'Save template'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _TemplateMedicineDraft {
  final name = TextEditingController();
  final dose = TextEditingController();
  final duration = TextEditingController();
  final instruction = TextEditingController();
  bool morning = true;
  bool afternoon = false;
  bool night = true;
  String food = 'After Food';

  void dispose() {
    name.dispose();
    dose.dispose();
    duration.dispose();
    instruction.dispose();
  }
}
