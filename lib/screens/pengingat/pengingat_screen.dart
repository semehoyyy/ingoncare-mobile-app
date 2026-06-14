import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/theme.dart';
import '../../services/api_service.dart';

class PengingatScreen extends StatefulWidget {
  const PengingatScreen({super.key});

  @override
  State<PengingatScreen> createState() => _PengingatScreenState();
}

class _PengingatScreenState extends State<PengingatScreen> {
  static const String _cachedPengingatKey = 'cached_pengingat';
  static const String _pendingDeletePengingatKey = 'pending_delete_pengingat';
  static const String _pendingSelesaiPengingatKey = 'pending_selesai_pengingat';
  static const String _cachedPetsKey = 'cached_pets';

  List<dynamic> _aktif = [];
  List<dynamic> _selesai = [];
  List<dynamic> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<Map<String, dynamic>> _getCachedPengingat() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cachedPengingatKey);

    if (jsonString == null || jsonString.isEmpty) {
      return {
        'aktif': <dynamic>[],
        'selesai': <dynamic>[],
      };
    }

    try {
      final decoded = jsonDecode(jsonString);

      if (decoded is Map<String, dynamic>) {
        return {
          'aktif': decoded['aktif'] is List ? decoded['aktif'] : <dynamic>[],
          'selesai':
              decoded['selesai'] is List ? decoded['selesai'] : <dynamic>[],
        };
      }

      return {
        'aktif': <dynamic>[],
        'selesai': <dynamic>[],
      };
    } catch (e) {
      return {
        'aktif': <dynamic>[],
        'selesai': <dynamic>[],
      };
    }
  }

  Future<void> _saveCachedPengingat({
    required List<dynamic> aktif,
    required List<dynamic> selesai,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _cachedPengingatKey,
      jsonEncode({
        'aktif': aktif,
        'selesai': selesai,
      }),
    );
  }

  Future<List<dynamic>> _getCachedPets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cachedPetsKey);

    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) return decoded;
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<int>> _getPendingDeleteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pendingDeletePengingatKey);

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

  Future<void> _savePendingDeleteIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingDeletePengingatKey, jsonEncode(ids));
  }

  Future<void> _addPendingDeleteId(int id) async {
    final ids = await _getPendingDeleteIds();

    if (!ids.contains(id)) {
      ids.add(id);
    }

    await _savePendingDeleteIds(ids);
  }

  Future<List<int>> _getPendingSelesaiIds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pendingSelesaiPengingatKey);

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

  Future<void> _savePendingSelesaiIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingSelesaiPengingatKey, jsonEncode(ids));
  }

  Future<void> _addPendingSelesaiId(int id) async {
    final ids = await _getPendingSelesaiIds();

    if (!ids.contains(id)) {
      ids.add(id);
    }

    await _savePendingSelesaiIds(ids);
  }

  Future<void> _removePendingSelesaiId(int id) async {
    final ids = await _getPendingSelesaiIds();

    ids.removeWhere((item) => item == id);

    await _savePendingSelesaiIds(ids);
  }

  int _parseId(dynamic value) {
    return int.tryParse(value.toString()) ?? 0;
  }

  int? _extractCreatedPengingatId(Map<String, dynamic> response) {
    final possibleSources = [
      response['pengingat'],
      response['data'],
      response['reminder'],
      response,
    ];

    for (final source in possibleSources) {
      if (source is Map && source['id'] != null) {
        final id = int.tryParse(source['id'].toString());
        if (id != null && id > 0) return id;
      }
    }

    return null;
  }

  String _getPetNameById(int? petId) {
    if (petId == null) return 'Unknown';

    final found = _pets.where((pet) {
      return pet['id'].toString() == petId.toString();
    }).toList();

    if (found.isEmpty) return 'Unknown';

    return found.first['name']?.toString() ?? 'Unknown';
  }

  Map<String, dynamic> _buildApiData(dynamic item) {
    return {
      'pet_id': item['pet_id'],
      'kategori': item['kategori'],
      'tanggal': item['tanggal'],
      'waktu': item['waktu'],
      'deskripsi': item['deskripsi'],
    };
  }

  Future<void> _setStateFromCache() async {
    final cached = await _getCachedPengingat();
    final cachedPets = await _getCachedPets();

    if (!mounted) return;

    setState(() {
      _aktif = cached['aktif'] ?? [];
      _selesai = cached['selesai'] ?? [];
      if (cachedPets.isNotEmpty) {
        _pets = cachedPets;
      }
    });
  }

  Future<void> _syncUnsyncedPengingat() async {
    final cached = await _getCachedPengingat();

    final cachedAktif = List<dynamic>.from(cached['aktif'] ?? []);
    final cachedSelesai = List<dynamic>.from(cached['selesai'] ?? []);

    final unsyncedAktif = cachedAktif.where((item) {
      return item['is_synced'] == false;
    }).toList();

    final unsyncedSelesai = cachedSelesai.where((item) {
      return item['is_synced'] == false;
    }).toList();

    if (unsyncedAktif.isEmpty && unsyncedSelesai.isEmpty) return;

    final stillUnsyncedAktif = <dynamic>[];
    final stillUnsyncedSelesai = <dynamic>[];

    for (final item in unsyncedAktif) {
      try {
        final petId = _parseId(item['pet_id']);

        if (petId <= 0) {
          throw Exception('Hewan belum tersinkron ke server.');
        }

        await ApiService.createPengingat(_buildApiData(item));
      } catch (e) {
        stillUnsyncedAktif.add(item);
      }
    }

    for (final item in unsyncedSelesai) {
      try {
        final petId = _parseId(item['pet_id']);

        if (petId <= 0) {
          throw Exception('Hewan belum tersinkron ke server.');
        }

        final response = await ApiService.createPengingat(_buildApiData(item));
        final createdId = _extractCreatedPengingatId(response);

        if (createdId != null) {
          await ApiService.selesaiPengingat(createdId);
        } else {
          throw Exception('ID pengingat baru tidak ditemukan.');
        }
      } catch (e) {
        stillUnsyncedSelesai.add(item);
      }
    }

    final syncedAktif = cachedAktif.where((item) {
      return item['is_synced'] != false;
    }).toList();

    final syncedSelesai = cachedSelesai.where((item) {
      return item['is_synced'] != false;
    }).toList();

    await _saveCachedPengingat(
      aktif: [
        ...syncedAktif,
        ...stillUnsyncedAktif,
      ],
      selesai: [
        ...syncedSelesai,
        ...stillUnsyncedSelesai,
      ],
    );
  }

  Future<void> _syncPendingSelesai() async {
    final ids = await _getPendingSelesaiIds();

    if (ids.isEmpty) return;

    final stillPending = <int>[];

    for (final id in ids) {
      try {
        await ApiService.selesaiPengingat(id);
      } catch (e) {
        stillPending.add(id);
      }
    }

    await _savePendingSelesaiIds(stillPending);
  }

  Future<void> _syncPendingDelete() async {
    final ids = await _getPendingDeleteIds();

    if (ids.isEmpty) return;

    final stillPending = <int>[];

    for (final id in ids) {
      try {
        await ApiService.deletePengingat(id);
        await _removePendingSelesaiId(id);
      } catch (e) {
        stillPending.add(id);
      }
    }

    await _savePendingDeleteIds(stillPending);
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    await _setStateFromCache();

    try {
      await _syncUnsyncedPengingat();
    } catch (e) {}

    try {
      await _syncPendingSelesai();
    } catch (e) {}

    try {
      await _syncPendingDelete();
    } catch (e) {}

    try {
      final responses = await Future.wait([
        ApiService.getPengingat(),
        ApiService.getPets(),
      ]);

      final pengingatResponse = responses[0];
      final petsResponse = responses[1];

      final serverAktif = List<dynamic>.from(pengingatResponse['aktif'] ?? []);
      final serverSelesai =
          List<dynamic>.from(pengingatResponse['selesai'] ?? []);
      final serverPets = List<dynamic>.from(petsResponse['pets'] ?? []);

      final pendingDeleteIds = await _getPendingDeleteIds();
      final pendingSelesaiIds = await _getPendingSelesaiIds();

      final filteredServerAktif = serverAktif.where((item) {
        final id = _parseId(item['id']);
        return !pendingDeleteIds.contains(id) &&
            !pendingSelesaiIds.contains(id);
      }).toList();

      final filteredServerSelesai = serverSelesai.where((item) {
        final id = _parseId(item['id']);
        return !pendingDeleteIds.contains(id);
      }).toList();

      final latestCached = await _getCachedPengingat();

      final unsyncedAktif =
          List<dynamic>.from(latestCached['aktif'] ?? []).where((item) {
        return item['is_synced'] == false;
      }).toList();

      final localSelesaiPending =
          List<dynamic>.from(latestCached['selesai'] ?? []).where((item) {
        return item['is_synced'] == false ||
            item['is_pending_selesai'] == true;
      }).toList();

      final mergedAktif = [
        ...unsyncedAktif,
        ...filteredServerAktif,
      ];

      final mergedSelesai = [
        ...localSelesaiPending,
        ...filteredServerSelesai,
      ];

      await _saveCachedPengingat(
        aktif: mergedAktif,
        selesai: mergedSelesai,
      );

      if (!mounted) return;

      setState(() {
        _aktif = mergedAktif;
        _selesai = mergedSelesai;
        _pets = serverPets;
        _isLoading = false;
      });
    } catch (e) {
      final cached = await _getCachedPengingat();
      final cachedPets = await _getCachedPets();

      if (!mounted) return;

      setState(() {
        _aktif = cached['aktif'] ?? [];
        _selesai = cached['selesai'] ?? [];
        if (cachedPets.isNotEmpty) {
          _pets = cachedPets;
        }
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode offline: menampilkan pengingat lokal.'),
        ),
      );
    }
  }

  Future<void> _markSelesai(dynamic item) async {
    final id = _parseId(item['id']);
    final isLocalOnly = item['is_synced'] == false || id < 0;

    final cached = await _getCachedPengingat();
    final cachedAktif = List<dynamic>.from(cached['aktif'] ?? []);
    final cachedSelesai = List<dynamic>.from(cached['selesai'] ?? []);

    final updatedAktif = cachedAktif.where((aktifItem) {
      return aktifItem['id'].toString() != item['id'].toString();
    }).toList();

    final movedItem = {
      ...Map<String, dynamic>.from(item),
      'is_synced': isLocalOnly ? false : true,
      'is_pending_selesai': !isLocalOnly,
    };

    final updatedSelesai = [
      movedItem,
      ...cachedSelesai,
    ];

    if (isLocalOnly) {
      await _saveCachedPengingat(
        aktif: updatedAktif,
        selesai: updatedSelesai,
      );

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengingat offline ditandai selesai. Akan disinkronkan saat online.',
          ),
        ),
      );
      return;
    }

    try {
      await ApiService.selesaiPengingat(id);
      await _removePendingSelesaiId(id);
      await _loadData();
    } catch (e) {
      await _addPendingSelesaiId(id);

      await _saveCachedPengingat(
        aktif: updatedAktif,
        selesai: updatedSelesai,
      );

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengingat ditandai selesai secara offline. Akan disinkronkan saat online.',
          ),
        ),
      );
    }
  }

  Future<void> _deletePengingat(dynamic item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengingat'),
        content: const Text('Yakin ingin menghapus pengingat ini?'),
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

    final id = _parseId(item['id']);
    final isLocalOnly = item['is_synced'] == false || id < 0;

    final cached = await _getCachedPengingat();
    final cachedAktif = List<dynamic>.from(cached['aktif'] ?? []);
    final cachedSelesai = List<dynamic>.from(cached['selesai'] ?? []);

    final updatedAktif = cachedAktif.where((aktifItem) {
      return aktifItem['id'].toString() != item['id'].toString();
    }).toList();

    final updatedSelesai = cachedSelesai.where((selesaiItem) {
      return selesaiItem['id'].toString() != item['id'].toString();
    }).toList();

    if (isLocalOnly) {
      await _saveCachedPengingat(
        aktif: updatedAktif,
        selesai: updatedSelesai,
      );

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengingat offline berhasil dihapus.'),
        ),
      );
      return;
    }

    try {
      await ApiService.deletePengingat(id);
      await _removePendingSelesaiId(id);

      await _saveCachedPengingat(
        aktif: updatedAktif,
        selesai: updatedSelesai,
      );

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengingat berhasil dihapus.'),
        ),
      );
    } catch (e) {
      await _addPendingDeleteId(id);
      await _removePendingSelesaiId(id);

      await _saveCachedPengingat(
        aktif: updatedAktif,
        selesai: updatedSelesai,
      );

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengingat dihapus secara offline. Akan disinkronkan saat online.',
          ),
        ),
      );
    }
  }

  void _showCreateDialog() {
    if (_pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan hewan terlebih dahulu di menu Hewan'),
        ),
      );
      return;
    }

    final deskripsiC = TextEditingController();

    int? selectedPetId = _parseId(_pets.first['id']);
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
                const Text(
                  'Tambah Pengingat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDarker,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: selectedPetId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Hewan *',
                    prefixIcon: Icon(
                      Icons.pets,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  items: _pets.map<DropdownMenuItem<int>>((pet) {
                    final petId = _parseId(pet['id']);

                    return DropdownMenuItem<int>(
                      value: petId,
                      child: Text(pet['name']?.toString() ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setLocalState(() => selectedPetId = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: kategori,
                  decoration: const InputDecoration(
                    labelText: 'Kategori *',
                    prefixIcon: Icon(
                      Icons.category_outlined,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Vaksinasi',
                      child: Text('Vaksinasi'),
                    ),
                    DropdownMenuItem(
                      value: 'Grooming',
                      child: Text('Grooming'),
                    ),
                    DropdownMenuItem(
                      value: 'Kontrol',
                      child: Text('Kontrol'),
                    ),
                    DropdownMenuItem(
                      value: 'Obat',
                      child: Text('Obat'),
                    ),
                    DropdownMenuItem(
                      value: 'Lainnya',
                      child: Text('Lainnya'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setLocalState(() => kategori = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                    );

                    if (date != null) {
                      setLocalState(() => selectedDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal *',
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
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );

                    if (time != null) {
                      setLocalState(() => selectedTime = time);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Waktu *',
                      prefixIcon: Icon(
                        Icons.access_time,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    child: Text(
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deskripsiC,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
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
                      if (selectedPetId == null) return;

                      final data = <String, dynamic>{
                        'pet_id': selectedPetId,
                        'nama_hewan': _getPetNameById(selectedPetId),
                        'kategori': kategori,
                        'tanggal':
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        'waktu':
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        'deskripsi': deskripsiC.text.trim().isNotEmpty
                            ? deskripsiC.text.trim()
                            : null,
                      };

                      try {
                        if ((selectedPetId ?? 0) <= 0) {
                          throw Exception('Hewan belum tersinkron ke server.');
                        }

                        await ApiService.createPengingat({
                          'pet_id': data['pet_id'],
                          'kategori': data['kategori'],
                          'tanggal': data['tanggal'],
                          'waktu': data['waktu'],
                          'deskripsi': data['deskripsi'],
                        });

                        if (mounted) Navigator.pop(ctx);
                        await _loadData();
                      } catch (e) {
                        final cached = await _getCachedPengingat();

                        final localPengingat = {
                          'id': DateTime.now().millisecondsSinceEpoch * -1,
                          ...data,
                          'is_synced': false,
                          'sync_action': 'create',
                        };

                        final updatedAktif = [
                          localPengingat,
                          ...List<dynamic>.from(cached['aktif'] ?? []),
                        ];

                        final updatedSelesai = List<dynamic>.from(
                          cached['selesai'] ?? [],
                        );

                        await _saveCachedPengingat(
                          aktif: updatedAktif,
                          selesai: updatedSelesai,
                        );

                        if (mounted) {
                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pengingat disimpan offline. Akan disinkronkan saat online.',
                              ),
                            ),
                          );

                          await _loadData();
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
        title: const Text('Pengingat'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader(
                    'Pengingat Aktif',
                    '${_aktif.length}',
                    Icons.notifications_active_outlined,
                  ),
                  const SizedBox(height: 8),
                  if (_aktif.isEmpty)
                    _buildEmptySection('Tidak ada pengingat aktif')
                  else
                    ..._aktif.map(
                      (item) => _buildPengingatCard(item, isAktif: true),
                    ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    'Riwayat Selesai',
                    '${_selesai.length}',
                    Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 8),
                  if (_selesai.isEmpty)
                    _buildEmptySection('Belum ada riwayat selesai')
                  else
                    ..._selesai.map(
                      (item) => _buildPengingatCard(item, isAktif: false),
                    ),
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
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryLighter,
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPengingatCard(dynamic item, {required bool isAktif}) {
    final bool isUnsynced =
        item['is_synced'] == false || item['is_pending_selesai'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnsynced ? Colors.orange : AppColors.primaryLighter,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama_hewan']?.toString() ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color:
                        isAktif ? AppColors.primaryDarker : AppColors.textGray,
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
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['kategori']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['tanggal']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['waktu']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
                if (item['deskripsi'] != null &&
                    item['deskripsi'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item['deskripsi'].toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
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
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  onPressed: () => _markSelesai(item),
                ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.danger,
                  ),
                ),
                onPressed: () => _deletePengingat(item),
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
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textGray,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}