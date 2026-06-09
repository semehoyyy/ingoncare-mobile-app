import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';

class PengingatScreen extends StatefulWidget {
  const PengingatScreen({super.key});

  @override
  State<PengingatScreen> createState() => _PengingatScreenState();
}

class _PengingatScreenState extends State<PengingatScreen> {
  List<dynamic> _aktif = [];
  List<dynamic> _selesai = [];
  List<dynamic> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        ApiService.getPengingat(),
        ApiService.getPets(),
      ]);
      setState(() {
        _aktif = responses[0]['aktif'] ?? [];
        _selesai = responses[0]['selesai'] ?? [];
        _pets = responses[1]['pets'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markSelesai(int id) async {
    await ApiService.selesaiPengingat(id);
    _loadData();
  }

  Future<void> _deletePengingat(int id) async {
    await ApiService.deletePengingat(id);
    _loadData();
  }

  void _showCreateDialog() {
    if (_pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan hewan terlebih dahulu di menu Hewan')),
      );
      return;
    }

    final deskripsiC = TextEditingController();
    int? selectedPetId = _pets.first['id'];
    String kategori = 'Vaksinasi';
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

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
                const Text('Tambah Pengingat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDarker)),
                const SizedBox(height: 20),
                // Pilih Hewan
                DropdownButtonFormField<int>(
                  value: selectedPetId,
                  decoration: const InputDecoration(labelText: 'Pilih Hewan *', prefixIcon: Icon(Icons.pets, color: AppColors.primaryLight)),
                  items: _pets.map<DropdownMenuItem<int>>((pet) {
                    return DropdownMenuItem<int>(
                      value: pet['id'],
                      child: Text(pet['name'] ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (v) => setLocalState(() => selectedPetId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: kategori,
                  decoration: const InputDecoration(labelText: 'Kategori *', prefixIcon: Icon(Icons.category_outlined, color: AppColors.primaryLight)),
                  items: const [
                    DropdownMenuItem(value: 'Vaksinasi', child: Text('Vaksinasi')),
                    DropdownMenuItem(value: 'Grooming', child: Text('Grooming')),
                    DropdownMenuItem(value: 'Kontrol', child: Text('Kontrol')),
                    DropdownMenuItem(value: 'Obat', child: Text('Obat')),
                    DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                  ],
                  onChanged: (v) => setLocalState(() => kategori = v!),
                ),
                const SizedBox(height: 12),
                // Tanggal
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setLocalState(() => selectedDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tanggal *', prefixIcon: Icon(Icons.calendar_today, color: AppColors.primaryLight)),
                    child: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  ),
                ),
                const SizedBox(height: 12),
                // Waktu
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: selectedTime);
                    if (time != null) setLocalState(() => selectedTime = time);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Waktu *', prefixIcon: Icon(Icons.access_time, color: AppColors.primaryLight)),
                    child: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deskripsiC,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Deskripsi (opsional)', prefixIcon: Icon(Icons.notes, color: AppColors.primaryLight)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedPetId == null) return;
                      await ApiService.createPengingat({
                        'pet_id': selectedPetId,
                        'kategori': kategori,
                        'tanggal': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        'waktu': '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        'deskripsi': deskripsiC.text.isNotEmpty ? deskripsiC.text : null,
                      });
                      if (mounted) Navigator.pop(ctx);
                      _loadData();
                    },
                    child: const Text('Simpan'),
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
        title: const Text('Pengingat'),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: AppColors.primary), onPressed: _showCreateDialog),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Aktif Section
                  _buildSectionHeader('Pengingat Aktif', '${_aktif.length}', Icons.notifications_active_outlined),
                  const SizedBox(height: 8),
                  if (_aktif.isEmpty)
                    _buildEmptySection('Tidak ada pengingat aktif')
                  else
                    ..._aktif.map((item) => _buildPengingatCard(item, isAktif: true)),

                  const SizedBox(height: 24),

                  // Selesai Section
                  _buildSectionHeader('Riwayat Selesai', '${_selesai.length}', Icons.check_circle_outline),
                  const SizedBox(height: 8),
                  if (_selesai.isEmpty)
                    _buildEmptySection('Belum ada riwayat selesai')
                  else
                    ..._selesai.map((item) => _buildPengingatCard(item, isAktif: false)),
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

  Widget _buildSectionHeader(String title, String count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryLighter, AppColors.primaryLight]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildPengingatCard(dynamic item, {required bool isAktif}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLighter, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama_hewan'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isAktif ? AppColors.primaryDarker : AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['kategori'] ?? '',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(item['tanggal'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(item['waktu'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                  ],
                ),
                if (item['deskripsi'] != null && item['deskripsi'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(item['deskripsi'], style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                ],
              ],
            ),
          ),
          Column(
            children: [
              if (isAktif)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.primaryLighter, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.check, size: 18, color: AppColors.primary),
                  ),
                  onPressed: () => _markSelesai(item['id']),
                ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                ),
                onPressed: () => _deletePengingat(item['id']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLighter),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: AppColors.textGray, fontSize: 13)),
      ),
    );
  }
}
