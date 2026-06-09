import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<dynamic> _riwayats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getRiwayat();
      setState(() {
        _riwayats = response['riwayats'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRiwayat(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Yakin ingin menghapus riwayat ini?'),
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
      await ApiService.deleteRiwayat(id);
      _loadRiwayat();
    }
  }

  void _showCreateDialog() {
    final diagnosisC = TextEditingController();
    final tindakanC = TextEditingController();
    final dokterC = TextEditingController();
    final catatanC = TextEditingController();
    DateTime selectedDate = DateTime.now();

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
                const Text('Tambah Riwayat Kesehatan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDarker)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setLocalState(() => selectedDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tanggal Pemeriksaan', prefixIcon: Icon(Icons.calendar_today, color: AppColors.primaryLight)),
                    child: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diagnosisC,
                  decoration: const InputDecoration(labelText: 'Diagnosis', prefixIcon: Icon(Icons.medical_services_outlined, color: AppColors.primaryLight)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tindakanC,
                  decoration: const InputDecoration(labelText: 'Tindakan', prefixIcon: Icon(Icons.healing_outlined, color: AppColors.primaryLight)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dokterC,
                  decoration: const InputDecoration(labelText: 'Dokter', prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryLight)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: catatanC,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Catatan (opsional)', prefixIcon: Icon(Icons.notes, color: AppColors.primaryLight)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (diagnosisC.text.isEmpty || tindakanC.text.isEmpty || dokterC.text.isEmpty) return;
                      await ApiService.createRiwayat({
                        'tanggal_pemeriksaan': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        'diagnosis': diagnosisC.text,
                        'tindakan': tindakanC.text,
                        'dokter': dokterC.text,
                        'catatan': catatanC.text.isNotEmpty ? catatanC.text : null,
                      });
                      if (mounted) Navigator.pop(ctx);
                      _loadRiwayat();
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
        title: const Text('Riwayat Kesehatan'),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: AppColors.primary), onPressed: _showCreateDialog),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadRiwayat,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _riwayats.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _riwayats.length,
                    itemBuilder: (ctx, i) => _buildRiwayatCard(_riwayats[i]),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRiwayatCard(dynamic riwayat) {
    final pet = riwayat['pet'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLighter, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with pet info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primaryLighter, AppColors.primaryBg]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: const Icon(Icons.pets, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet?['name'] ?? 'Hewan',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDarker),
                      ),
                      Text(
                        pet?['species'] ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textGray),
                      ),
                    ],
                  ),
                ),
                // Date badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        riwayat['tanggal_pemeriksaan'] ?? '',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildDetailRow(Icons.medical_services_outlined, 'Diagnosis', riwayat['diagnosis'] ?? '-'),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.healing_outlined, 'Tindakan', riwayat['tindakan'] ?? '-'),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.person_outline, 'Dokter', riwayat['dokter'] ?? '-'),
                if (riwayat['catatan'] != null && riwayat['catatan'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.notes, 'Catatan', riwayat['catatan']),
                ],
              ],
            ),
          ),

          // Next schedule
          if (riwayat['jadwal_berikutnya'] != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                border: Border(top: BorderSide(color: AppColors.primaryLighter)),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.event, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jadwal Berikutnya', style: TextStyle(fontSize: 11, color: AppColors.textGray)),
                      Text(
                        riwayat['jadwal_berikutnya'],
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                    onPressed: () => _deleteRiwayat(riwayat['id']),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 14, bottom: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                  onPressed: () => _deleteRiwayat(riwayat['id']),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: AppColors.primaryLighter, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDarker)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.primaryLighter, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.medical_information_outlined, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Belum ada riwayat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDarker)),
          const SizedBox(height: 8),
          const Text('Tambahkan catatan pemeriksaan pertama', style: TextStyle(color: AppColors.textGray)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Riwayat'),
          ),
        ],
      ),
    );
  }
}
