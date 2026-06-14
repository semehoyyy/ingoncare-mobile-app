import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/theme.dart';
import '../../services/api_service.dart';

class RiwayatScreen extends StatefulWidget {
  final int petId;
  final String? petName;

  const RiwayatScreen({
    super.key,
    required this.petId,
    this.petName,
  });

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  static const String _cachedAllRiwayatKey = 'cached_all_riwayat';
  static const String _pendingDeleteRiwayatKey = 'pending_delete_riwayat';

  List<dynamic> _riwayats = [];
  bool _isLoading = true;

  String get _petName {
    final name = widget.petName;

    if (name == null || name.trim().isEmpty) {
      return 'Hewan';
    }

    return name;
  }

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<List<dynamic>> _getCachedAllRiwayats() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cachedAllRiwayatKey);

    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) return decoded;
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveCachedAllRiwayats(List<dynamic> riwayats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedAllRiwayatKey, jsonEncode(riwayats));
  }

  List<dynamic> _filterRiwayatsForCurrentPet(List<dynamic> allRiwayats) {
    return allRiwayats.where((riwayat) {
      final pet = riwayat['pet'];
      final petIdFromData = riwayat['pet_id'] ?? pet?['id'];

      return petIdFromData.toString() == widget.petId.toString();
    }).toList();
  }

  Future<List<int>> _getPendingDeleteRiwayatIds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pendingDeleteRiwayatKey);

    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded
            .map((item) => int.tryParse(item.toString()) ?? 0)
            .where((id) => id > 0)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _savePendingDeleteRiwayatIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingDeleteRiwayatKey, jsonEncode(ids));
  }

  Future<void> _addPendingDeleteRiwayatId(int id) async {
    final ids = await _getPendingDeleteRiwayatIds();

    if (!ids.contains(id)) {
      ids.add(id);
    }

    await _savePendingDeleteRiwayatIds(ids);
  }

  Future<void> _syncPendingDeletedRiwayats() async {
    final ids = await _getPendingDeleteRiwayatIds();

    if (ids.isEmpty) return;

    final stillPending = <int>[];

    for (final id in ids) {
      try {
        await ApiService.deleteRiwayat(id);
      } catch (e) {
        stillPending.add(id);
      }
    }

    await _savePendingDeleteRiwayatIds(stillPending);
  }

  Future<void> _addRiwayatToLocal(Map<String, dynamic> data) async {
    final cachedAllRiwayats = await _getCachedAllRiwayats();

    final localRiwayat = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch * -1,
      'pet_id': widget.petId,
      'pet': {
        'id': widget.petId,
        'name': _petName,
        'species': '',
      },
      'tanggal_pemeriksaan': data['tanggal_pemeriksaan'],
      'diagnosis': data['diagnosis'],
      'tindakan': data['tindakan'],
      'dokter': data['dokter'],
      'catatan': data['catatan'],
      'jadwal_berikutnya': data['jadwal_berikutnya'],
      'is_synced': false,
      'sync_action': 'create',
    };

    cachedAllRiwayats.add(localRiwayat);
    await _saveCachedAllRiwayats(cachedAllRiwayats);
  }

  Future<void> _deleteLocalRiwayat(dynamic riwayat) async {
    final cachedAllRiwayats = await _getCachedAllRiwayats();
    final id = riwayat['id'];

    final updatedRiwayats = cachedAllRiwayats.where((item) {
      return item['id'].toString() != id.toString();
    }).toList();

    await _saveCachedAllRiwayats(updatedRiwayats);
  }

  Future<void> _syncUnsyncedRiwayats() async {
    final cachedAllRiwayats = await _getCachedAllRiwayats();

    final unsyncedRiwayats = cachedAllRiwayats.where((riwayat) {
      return riwayat['is_synced'] == false;
    }).toList();

    if (unsyncedRiwayats.isEmpty) return;

    final stillUnsynced = <dynamic>[];

    for (final riwayat in unsyncedRiwayats) {
      try {
        final petId = int.tryParse(riwayat['pet_id'].toString()) ?? 0;

        if (petId <= 0) {
          throw Exception('Pet belum tersinkron ke server.');
        }

        final data = <String, dynamic>{
          'pet_id': petId,
          'tanggal_pemeriksaan': riwayat['tanggal_pemeriksaan'],
          'diagnosis': riwayat['diagnosis'],
          'tindakan': riwayat['tindakan'],
          'dokter': riwayat['dokter'],
          'catatan': riwayat['catatan'],
        };

        if (riwayat['jadwal_berikutnya'] != null) {
          data['jadwal_berikutnya'] = riwayat['jadwal_berikutnya'];
        }

        await ApiService.createRiwayat(data);
      } catch (e) {
        stillUnsynced.add(riwayat);
      }
    }

    final syncedRiwayats = cachedAllRiwayats.where((riwayat) {
      return riwayat['is_synced'] != false;
    }).toList();

    await _saveCachedAllRiwayats([
      ...syncedRiwayats,
      ...stillUnsynced,
    ]);
  }

  Future<void> _loadRiwayat() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    final cachedAllRiwayats = await _getCachedAllRiwayats();
    final cachedCurrentPetRiwayats = _filterRiwayatsForCurrentPet(
      cachedAllRiwayats,
    );

    if (mounted) {
      setState(() {
        _riwayats = cachedCurrentPetRiwayats;
      });
    }

    try {
      await _syncUnsyncedRiwayats();
    } catch (e) {
      // Sync tambah offline gagal, lanjut load server.
    }

    try {
      await _syncPendingDeletedRiwayats();
    } catch (e) {
      // Sync hapus offline gagal, tetap pending.
    }

    try {
      final response = await ApiService.getRiwayat();
      final allServerRiwayats = response['riwayats'] ?? [];

      final pendingDeleteIds = await _getPendingDeleteRiwayatIds();

      final filteredServerRiwayats = allServerRiwayats.where((riwayat) {
        final riwayatId = int.tryParse(riwayat['id'].toString()) ?? 0;
        return !pendingDeleteIds.contains(riwayatId);
      }).toList();

      final latestCachedAllRiwayats = await _getCachedAllRiwayats();

      final unsyncedRiwayats = latestCachedAllRiwayats.where((riwayat) {
        return riwayat['is_synced'] == false;
      }).toList();

      final mergedAllRiwayats = [
        ...unsyncedRiwayats,
        ...filteredServerRiwayats,
      ];

      await _saveCachedAllRiwayats(mergedAllRiwayats);

      final currentPetRiwayats = _filterRiwayatsForCurrentPet(
        mergedAllRiwayats,
      );

      if (!mounted) return;

      setState(() {
        _riwayats = currentPetRiwayats;
        _isLoading = false;
      });
    } catch (e) {
      final latestCachedAllRiwayats = await _getCachedAllRiwayats();
      final latestCurrentPetRiwayats = _filterRiwayatsForCurrentPet(
        latestCachedAllRiwayats,
      );

      if (!mounted) return;

      setState(() {
        _riwayats = latestCurrentPetRiwayats.isNotEmpty
            ? latestCurrentPetRiwayats
            : cachedCurrentPetRiwayats;
        _isLoading = false;
      });

      if (_riwayats.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mode offline: menampilkan riwayat lokal.'),
          ),
        );
      }
    }
  }

  Future<void> _deleteRiwayat(dynamic riwayat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Yakin ingin menghapus riwayat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final riwayatId = int.tryParse(riwayat['id'].toString()) ?? 0;
    final isLocalOnly = riwayat['is_synced'] == false || riwayatId < 0;

    if (isLocalOnly) {
      await _deleteLocalRiwayat(riwayat);
      await _loadRiwayat();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Riwayat offline berhasil dihapus.'),
        ),
      );
      return;
    }

    try {
      await ApiService.deleteRiwayat(riwayatId);

      final cachedAllRiwayats = await _getCachedAllRiwayats();
      final updatedRiwayats = cachedAllRiwayats.where((item) {
        return item['id'].toString() != riwayatId.toString();
      }).toList();

      await _saveCachedAllRiwayats(updatedRiwayats);
      await _loadRiwayat();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Riwayat berhasil dihapus.'),
        ),
      );
    } catch (e) {
      await _addPendingDeleteRiwayatId(riwayatId);

      final cachedAllRiwayats = await _getCachedAllRiwayats();
      final updatedRiwayats = cachedAllRiwayats.where((item) {
        return item['id'].toString() != riwayatId.toString();
      }).toList();

      await _saveCachedAllRiwayats(updatedRiwayats);

      if (!mounted) return;

      setState(() {
        _riwayats = _riwayats.where((item) {
          return item['id'].toString() != riwayatId.toString();
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Riwayat dihapus secara offline. Akan disinkronkan saat online.',
          ),
        ),
      );
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
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tambah Riwayat $_petName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDarker,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );

                    if (date != null) {
                      setLocalState(() => selectedDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Pemeriksaan',
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    child: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diagnosisC,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis',
                    prefixIcon: Icon(
                      Icons.medical_services_outlined,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tindakanC,
                  decoration: const InputDecoration(
                    labelText: 'Tindakan',
                    prefixIcon: Icon(
                      Icons.healing_outlined,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dokterC,
                  decoration: const InputDecoration(
                    labelText: 'Dokter',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: catatanC,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    prefixIcon: Icon(
                      Icons.notes,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (diagnosisC.text.trim().isEmpty ||
                          tindakanC.text.trim().isEmpty ||
                          dokterC.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Diagnosis, tindakan, dan dokter wajib diisi',
                            ),
                          ),
                        );
                        return;
                      }

                      final data = <String, dynamic>{
                        'pet_id': widget.petId,
                        'tanggal_pemeriksaan':
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        'diagnosis': diagnosisC.text.trim(),
                        'tindakan': tindakanC.text.trim(),
                        'dokter': dokterC.text.trim(),
                        'catatan': catatanC.text.trim().isNotEmpty
                            ? catatanC.text.trim()
                            : null,
                      };

                      try {
                        if (widget.petId <= 0) {
                          throw Exception('Pet belum tersinkron ke server.');
                        }

                        await ApiService.createRiwayat(data);

                        if (mounted) Navigator.pop(ctx);
                        await _loadRiwayat();
                      } catch (e) {
                        await _addRiwayatToLocal(data);

                        if (mounted) {
                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Riwayat disimpan offline. Akan disinkronkan saat online.',
                              ),
                            ),
                          );

                          await _loadRiwayat();
                        }
                      }
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
        title: Text('Riwayat $_petName'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadRiwayat,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
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
    final bool isUnsynced = riwayat['is_synced'] == false;
    final pet = riwayat['pet'];
    final petNameFromData = pet?['name']?.toString() ?? _petName;
    final petSpeciesFromData = pet?['species']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnsynced ? Colors.orange : AppColors.primaryLighter,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLighter,
                  AppColors.primaryBg,
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
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
                  child: const Icon(
                    Icons.pets,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        petNameFromData,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primaryDarker,
                        ),
                      ),
                      Text(
                        petSpeciesFromData,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                      ),
                      if (isUnsynced) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Belum sinkron',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        riwayat['tanggal_pemeriksaan']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.medical_services_outlined,
                  'Diagnosis',
                  riwayat['diagnosis']?.toString() ?? '-',
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  Icons.healing_outlined,
                  'Tindakan',
                  riwayat['tindakan']?.toString() ?? '-',
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  Icons.person_outline,
                  'Dokter',
                  riwayat['dokter']?.toString() ?? '-',
                ),
                if (riwayat['catatan'] != null &&
                    riwayat['catatan'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    Icons.notes,
                    'Catatan',
                    riwayat['catatan'].toString(),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14, bottom: 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.danger,
                ),
                onPressed: () => _deleteRiwayat(riwayat),
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
          decoration: BoxDecoration(
            color: AppColors.primaryLighter,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDarker,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.medical_information_outlined,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Belum ada riwayat $_petName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDarker,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tambahkan catatan pemeriksaan pertama',
                  style: TextStyle(color: AppColors.textGray),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Riwayat'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}