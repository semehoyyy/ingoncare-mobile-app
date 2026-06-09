import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  List<dynamic> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getPets();
      setState(() {
        _pets = response['pets'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePet(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Hewan'),
        content: const Text('Yakin ingin menghapus hewan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deletePet(id);
      _loadPets();
    }
  }

  void _showCreateDialog() {
    _showPetForm(null);
  }

  void _showEditDialog(dynamic pet) {
    _showPetForm(pet);
  }

  void _showPetForm(dynamic pet) {
    final isEdit = pet != null;
    final nameC = TextEditingController(text: pet?['name'] ?? '');
    final speciesC = TextEditingController(text: pet?['species'] ?? '');
    final breedC = TextEditingController(text: pet?['breed'] ?? '');
    final weightC = TextEditingController(text: pet?['weight']?.toString() ?? '');
    final specialMarksC = TextEditingController(text: pet?['special_marks'] ?? '');
    final allergiesC = TextEditingController(text: pet?['allergies'] ?? '');
    String gender = pet?['gender'] ?? 'Jantan';
    bool isSteril = pet?['is_steril'] == true || pet?['is_steril'] == 1;
    DateTime? birthDate;
    if (pet?['birth_date'] != null) {
      birthDate = DateTime.tryParse(pet['birth_date']);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(isEdit ? 'Edit Hewan' : 'Tambah Hewan', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDarker)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: 'Nama Hewan *', prefixIcon: Icon(Icons.pets, color: AppColors.primaryLight)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: speciesC,
                  decoration: const InputDecoration(labelText: 'Jenis (Kucing, Anjing, dll) *', prefixIcon: Icon(Icons.category_outlined, color: AppColors.primaryLight)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: breedC,
                  decoration: const InputDecoration(labelText: 'Ras (opsional)', prefixIcon: Icon(Icons.info_outline, color: AppColors.primaryLight)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: const InputDecoration(labelText: 'Gender *', prefixIcon: Icon(Icons.male, color: AppColors.primaryLight)),
                  items: const [
                    DropdownMenuItem(value: 'Jantan', child: Text('Jantan')),
                    DropdownMenuItem(value: 'Betina', child: Text('Betina')),
                  ],
                  onChanged: (v) => setLocalState(() => gender = v!),
                ),
                const SizedBox(height: 12),
                // Birth Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: birthDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setLocalState(() => birthDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tanggal Lahir *', prefixIcon: Icon(Icons.calendar_today, color: AppColors.primaryLight)),
                    child: Text(
                      birthDate != null ? '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}' : 'Pilih tanggal',
                      style: TextStyle(color: birthDate != null ? AppColors.textBody : AppColors.textGray),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Berat (kg, opsional)', prefixIcon: Icon(Icons.monitor_weight_outlined, color: AppColors.primaryLight)),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Sudah Steril?'),
                  value: isSteril,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setLocalState(() => isSteril = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specialMarksC,
                  decoration: const InputDecoration(labelText: 'Ciri Khusus (opsional)', prefixIcon: Icon(Icons.star_outline, color: AppColors.primaryLight)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: allergiesC,
                  decoration: const InputDecoration(labelText: 'Alergi (opsional)', prefixIcon: Icon(Icons.warning_amber, color: AppColors.primaryLight)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameC.text.isEmpty || speciesC.text.isEmpty || birthDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nama, Jenis, dan Tanggal Lahir wajib diisi')),
                        );
                        return;
                      }
                      final data = <String, dynamic>{
                        'name': nameC.text,
                        'species': speciesC.text,
                        'gender': gender,
                        'birth_date': '${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}',
                        'is_steril': isSteril ? '1' : '0',
                      };
                      if (breedC.text.isNotEmpty) data['breed'] = breedC.text;
                      if (weightC.text.isNotEmpty) data['weight'] = weightC.text;
                      if (specialMarksC.text.isNotEmpty) data['special_marks'] = specialMarksC.text;
                      if (allergiesC.text.isNotEmpty) data['allergies'] = allergiesC.text;

                      try {
                        if (isEdit) {
                          await ApiService.updatePet(pet['id'], data);
                        } else {
                          await ApiService.createPet(data);
                        }
                        if (mounted) Navigator.pop(ctx);
                        _loadPets();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal menyimpan: $e')),
                          );
                        }
                      }
                    },
                    child: Text(isEdit ? 'Update' : 'Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: const Text('Hewan Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadPets,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _pets.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Stats
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryLighter, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Hewan', style: TextStyle(fontSize: 13, color: AppColors.textGray)),
                                const SizedBox(height: 4),
                                Text(
                                  '${_pets.length}',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDarker),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLighter,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.pets, color: AppColors.primary, size: 28),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pets List
                      ..._pets.map((pet) => _buildPetCard(pet)),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPetCard(dynamic pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLighter, width: 1.5),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: Text(
                      (pet['name'] ?? 'P').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet['name'] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDarker),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pet['species'] ?? ''}${pet['breed'] != null ? ' · ${pet['breed']}' : ''}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textGray),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (pet['gender'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLighter,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                pet['gender'],
                                style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                              ),
                            ),
                          if (pet['age'] != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLighter,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                pet['age'],
                                style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Info section
          if (pet['special_marks'] != null || pet['allergies'] != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLighter),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pet['special_marks'] != null) ...[
                    const Text('Ciri Khusus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text(pet['special_marks'], style: const TextStyle(fontSize: 13, color: AppColors.textBody)),
                  ],
                  if (pet['allergies'] != null) ...[
                    const SizedBox(height: 8),
                    const Text('Alergi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text(pet['allergies'], style: const TextStyle(fontSize: 13, color: AppColors.textBody)),
                  ],
                ],
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditDialog(pet),
                  icon: const Icon(Icons.edit, size: 16, color: AppColors.primaryDark),
                  label: const Text('Edit', style: TextStyle(color: AppColors.primaryDark)),
                ),
                TextButton.icon(
                  onPressed: () => _deletePet(pet['id']),
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                  label: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.pets, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Belum ada hewan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDarker)),
          const SizedBox(height: 8),
          const Text('Tambahkan hewan peliharaan pertama kamu!', style: TextStyle(color: AppColors.textGray)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Hewan'),
          ),
        ],
      ),
    );
  }
}
