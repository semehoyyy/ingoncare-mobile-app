import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../riwayat/riwayat_screen.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  static const String _cachedPetsKey = 'cached_pets';
  static const String _pendingDeletePetsKey = 'pending_delete_pets';

  List<dynamic> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  // ===============================
  // PHOTO SUPPORT
  // ===============================

  Future<String?> _pickAndSavePetPhoto() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'pet_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');

    return savedImage.path;
  }

  Map<String, dynamic> _petDataForApi(Map<String, dynamic> data) {
    final apiData = Map<String, dynamic>.from(data);

    apiData.remove('local_photo_path');
    apiData.remove('sync_action');
    apiData.remove('is_synced');

    return apiData;
  }

  // ===============================
  // LOCAL STORAGE / OFFLINE SUPPORT
  // ===============================

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

  Future<void> _saveCachedPets(List<dynamic> pets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedPetsKey, jsonEncode(pets));
  }

  Future<List<int>> _getPendingDeletePetIds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pendingDeletePetsKey);

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

  Future<void> _savePendingDeletePetIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingDeletePetsKey, jsonEncode(ids));
  }

  Future<void> _addPendingDeletePetId(int id) async {
    final ids = await _getPendingDeletePetIds();

    if (!ids.contains(id)) {
      ids.add(id);
    }

    await _savePendingDeletePetIds(ids);
  }

  Future<void> _syncPendingDeletedPets() async {
    final ids = await _getPendingDeletePetIds();

    if (ids.isEmpty) return;

    final stillPending = <int>[];

    for (final id in ids) {
      try {
        await ApiService.deletePet(id);
      } catch (e) {
        stillPending.add(id);
      }
    }

    await _savePendingDeletePetIds(stillPending);
  }

  Future<void> _addPetToLocal(Map<String, dynamic> data) async {
    final cachedPets = await _getCachedPets();

    final localPet = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch * -1,
      'user_id': 0,
      'name': data['name'],
      'species': data['species'],
      'breed': data['breed'],
      'gender': data['gender'],
      'birth_date': data['birth_date'],
      'weight': data['weight'],
      'photo': null,
      'local_photo_path': data['local_photo_path'],
      'special_marks': data['special_marks'],
      'is_steril': data['is_steril'],
      'allergies': data['allergies'],
      'health_notes': data['health_notes'],
      'age': null,
      'is_synced': false,
      'sync_action': 'create',
    };

    cachedPets.add(localPet);
    await _saveCachedPets(cachedPets);
  }

  Future<void> _updateLocalPet(dynamic oldPet, Map<String, dynamic> data) async {
    final cachedPets = await _getCachedPets();
    final oldId = oldPet['id'];

    final updatedPets = cachedPets.map((item) {
      if (item['id'].toString() == oldId.toString()) {
        return {
          ...Map<String, dynamic>.from(item),
          ...data,
          'id': oldId,
          'is_synced': false,
          'sync_action': item['sync_action'] ?? 'create',
        };
      }

      return item;
    }).toList();

    await _saveCachedPets(updatedPets);
  }

  Future<void> _updateServerPetOffline(
    dynamic oldPet,
    Map<String, dynamic> data,
  ) async {
    final cachedPets = await _getCachedPets();
    final oldId = oldPet['id'];

    final updatedPet = {
      ...Map<String, dynamic>.from(oldPet),
      ...data,
      'id': oldId,
      'is_synced': false,
      'sync_action': 'update',
    };

    bool found = false;

    final updatedPets = cachedPets.map((item) {
      if (item['id'].toString() == oldId.toString()) {
        found = true;
        return updatedPet;
      }
      return item;
    }).toList();

    if (!found) {
      updatedPets.add(updatedPet);
    }

    await _saveCachedPets(updatedPets);
  }

  Future<void> _deleteLocalPet(dynamic pet) async {
    final cachedPets = await _getCachedPets();
    final petId = pet['id'];

    final updatedPets = cachedPets.where((item) {
      return item['id'].toString() != petId.toString();
    }).toList();

    await _saveCachedPets(updatedPets);
  }

  Future<void> _syncUnsyncedPets() async {
    final cachedPets = await _getCachedPets();

    final unsyncedPets = cachedPets.where((pet) {
      return pet['is_synced'] == false;
    }).toList();

    if (unsyncedPets.isEmpty) return;

    final stillUnsynced = <dynamic>[];

    for (final pet in unsyncedPets) {
      try {
        final data = <String, dynamic>{
          'name': pet['name'],
          'species': pet['species'],
          'gender': pet['gender'],
          'birth_date': pet['birth_date'],
          'is_steril': pet['is_steril'],
        };

        if (pet['breed'] != null && pet['breed'].toString().isNotEmpty) {
          data['breed'] = pet['breed'];
        }

        if (pet['weight'] != null && pet['weight'].toString().isNotEmpty) {
          data['weight'] = pet['weight'];
        }

        if (pet['special_marks'] != null &&
            pet['special_marks'].toString().isNotEmpty) {
          data['special_marks'] = pet['special_marks'];
        }

        if (pet['allergies'] != null &&
            pet['allergies'].toString().isNotEmpty) {
          data['allergies'] = pet['allergies'];
        }

        final photoPath = pet['local_photo_path']?.toString();

        if (pet['sync_action'] == 'update') {
          final petId = int.tryParse(pet['id'].toString()) ?? 0;

          if (petId <= 0) {
            throw Exception('ID hewan tidak valid untuk update.');
          }

          await ApiService.updatePet(
            petId,
            data,
            photoPath: photoPath != null && photoPath.isNotEmpty
                ? photoPath
                : null,
          );
        } else {
          await ApiService.createPet(
            data,
            photoPath: photoPath != null && photoPath.isNotEmpty
                ? photoPath
                : null,
          );
        }
      } catch (e) {
        stillUnsynced.add(pet);
      }
    }

    final syncedPets = cachedPets.where((pet) {
      return pet['is_synced'] != false;
    }).toList();

    await _saveCachedPets([
      ...syncedPets,
      ...stillUnsynced,
    ]);
  }

  // ===============================
  // LOAD DATA
  // ===============================

  Future<void> _loadPets() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    final cachedPets = await _getCachedPets();

    if (mounted) {
      setState(() {
        _pets = cachedPets;
      });
    }

    try {
      await _syncUnsyncedPets();
    } catch (e) {
      // Sync tambah/edit offline gagal, tetap lanjut load server.
    }

    try {
      await _syncPendingDeletedPets();
    } catch (e) {
      // Sync hapus offline gagal, tetap pending.
    }

    try {
      final response = await ApiService.getPets();
      final serverPets = response['pets'] ?? [];

      final pendingDeleteIds = await _getPendingDeletePetIds();

      final filteredServerPets = serverPets.where((pet) {
        final petId = int.tryParse(pet['id'].toString()) ?? 0;
        return !pendingDeleteIds.contains(petId);
      }).toList();

      final latestCachedPets = await _getCachedPets();

      final unsyncedPets = latestCachedPets.where((pet) {
        return pet['is_synced'] == false;
      }).toList();

      final mergedPets = [
        ...unsyncedPets,
        ...filteredServerPets,
      ];

      await _saveCachedPets(mergedPets);

      if (!mounted) return;

      setState(() {
        _pets = mergedPets;
        _isLoading = false;
      });
    } catch (e) {
      final latestCachedPets = await _getCachedPets();

      if (!mounted) return;

      setState(() {
        _pets = latestCachedPets.isNotEmpty ? latestCachedPets : cachedPets;
        _isLoading = false;
      });

      if (_pets.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mode offline: menampilkan data lokal.'),
          ),
        );
      }
    }
  }

  // ===============================
  // DELETE PET
  // ===============================

  Future<void> _deletePet(dynamic pet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Hewan'),
        content: const Text('Yakin ingin menghapus hewan ini?'),
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

    final petId = int.tryParse(pet['id'].toString()) ?? 0;
    final isLocalOnly = pet['is_synced'] == false || petId < 0;

    if (isLocalOnly) {
      await _deleteLocalPet(pet);
      await _loadPets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hewan offline berhasil dihapus.'),
        ),
      );
      return;
    }

    try {
      await ApiService.deletePet(petId);

      final cachedPets = await _getCachedPets();
      final updatedPets = cachedPets.where((item) {
        return item['id'].toString() != petId.toString();
      }).toList();

      await _saveCachedPets(updatedPets);
      await _loadPets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hewan berhasil dihapus.'),
        ),
      );
    } catch (e) {
      await _addPendingDeletePetId(petId);

      final cachedPets = await _getCachedPets();
      final updatedPets = cachedPets.where((item) {
        return item['id'].toString() != petId.toString();
      }).toList();

      await _saveCachedPets(updatedPets);

      if (!mounted) return;

      setState(() {
        _pets = _pets.where((item) {
          return item['id'].toString() != petId.toString();
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hewan dihapus secara offline. Akan disinkronkan saat online.',
          ),
        ),
      );
    }
  }

  // ===============================
  // FORM
  // ===============================

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
    final weightC = TextEditingController(
      text: pet?['weight']?.toString() ?? '',
    );
    final specialMarksC = TextEditingController(
      text: pet?['special_marks'] ?? '',
    );
    final allergiesC = TextEditingController(text: pet?['allergies'] ?? '');

    String? selectedPhotoPath = pet?['local_photo_path']?.toString();

    String gender = pet?['gender'] ?? 'Jantan';
    bool isSteril = pet?['is_steril'] == true ||
        pet?['is_steril'] == 1 ||
        pet?['is_steril'] == '1';

    DateTime? birthDate;
    if (pet?['birth_date'] != null) {
      birthDate = DateTime.tryParse(pet['birth_date'].toString());
    }

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
                  isEdit ? 'Edit Hewan' : 'Tambah Hewan',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDarker,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final photoPath = await _pickAndSavePetPhoto();

                    if (photoPath != null) {
                      setLocalState(() {
                        selectedPhotoPath = photoPath;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryLighter),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primarySurface,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 58,
                            height: 58,
                            child: selectedPhotoPath != null &&
                                    selectedPhotoPath!.isNotEmpty
                                ? Image.file(
                                    File(selectedPhotoPath!),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return _buildPhotoPlaceholder();
                                    },
                                  )
                                : _buildPhotoPlaceholder(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedPhotoPath != null &&
                                    selectedPhotoPath!.isNotEmpty
                                ? 'Foto dipilih'
                                : 'Pilih Foto Hewan',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(
                    labelText: 'Nama Hewan *',
                    prefixIcon: Icon(
                      Icons.pets,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: speciesC,
                  decoration: const InputDecoration(
                    labelText: 'Jenis (Kucing, Anjing, dll) *',
                    prefixIcon: Icon(
                      Icons.category_outlined,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: breedC,
                  decoration: const InputDecoration(
                    labelText: 'Ras (opsional)',
                    prefixIcon: Icon(
                      Icons.info_outline,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender *',
                    prefixIcon: Icon(
                      Icons.male,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Jantan', child: Text('Jantan')),
                    DropdownMenuItem(value: 'Betina', child: Text('Betina')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setLocalState(() => gender = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
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
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Lahir *',
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    child: Text(
                      birthDate != null
                          ? '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}'
                          : 'Pilih tanggal',
                      style: TextStyle(
                        color: birthDate != null
                            ? AppColors.textBody
                            : AppColors.textGray,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Berat (kg, opsional)',
                    prefixIcon: Icon(
                      Icons.monitor_weight_outlined,
                      color: AppColors.primaryLight,
                    ),
                  ),
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
                  decoration: const InputDecoration(
                    labelText: 'Ciri Khusus (opsional)',
                    prefixIcon: Icon(
                      Icons.star_outline,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: allergiesC,
                  decoration: const InputDecoration(
                    labelText: 'Alergi (opsional)',
                    prefixIcon: Icon(
                      Icons.warning_amber,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameC.text.trim().isEmpty ||
                          speciesC.text.trim().isEmpty ||
                          birthDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Nama, Jenis, dan Tanggal Lahir wajib diisi',
                            ),
                          ),
                        );
                        return;
                      }

                      final data = <String, dynamic>{
                        'name': nameC.text.trim(),
                        'species': speciesC.text.trim(),
                        'gender': gender,
                        'birth_date':
                            '${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}',
                        'is_steril': isSteril ? '1' : '0',
                      };

                      if (breedC.text.trim().isNotEmpty) {
                        data['breed'] = breedC.text.trim();
                      }

                      if (weightC.text.trim().isNotEmpty) {
                        data['weight'] = weightC.text.trim();
                      }

                      if (specialMarksC.text.trim().isNotEmpty) {
                        data['special_marks'] = specialMarksC.text.trim();
                      }

                      if (allergiesC.text.trim().isNotEmpty) {
                        data['allergies'] = allergiesC.text.trim();
                      }

                      if (selectedPhotoPath != null &&
                          selectedPhotoPath!.isNotEmpty) {
                        data['local_photo_path'] = selectedPhotoPath;
                      }

                      final petId = isEdit
                          ? int.tryParse(pet['id'].toString()) ?? 0
                          : 0;

                      final isLocalOnly =
                          isEdit && (pet['is_synced'] == false || petId < 0);

                      try {
                        if (isEdit) {
                          if (isLocalOnly) {
                            await _updateLocalPet(pet, data);

                            if (mounted) Navigator.pop(ctx);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Perubahan disimpan offline.',
                                ),
                              ),
                            );

                            await _loadPets();
                          } else {
                            try {
                              await ApiService.updatePet(
                                petId,
                                _petDataForApi(data),
                                photoPath: selectedPhotoPath,
                              );

                              if (mounted) Navigator.pop(ctx);
                              await _loadPets();
                            } catch (e) {
                              await _updateServerPetOffline(pet, data);

                              if (mounted) {
                                Navigator.pop(ctx);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Perubahan disimpan offline. Akan disinkronkan saat online.',
                                    ),
                                  ),
                                );

                                await _loadPets();
                              }
                            }
                          }
                        } else {
                          await ApiService.createPet(
                            _petDataForApi(data),
                            photoPath: selectedPhotoPath,
                          );

                          if (mounted) Navigator.pop(ctx);
                          await _loadPets();
                        }
                      } catch (e) {
                        if (!isEdit) {
                          await _addPetToLocal(data);

                          if (mounted) {
                            Navigator.pop(ctx);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Hewan disimpan offline. Akan disinkronkan saat online.',
                                ),
                              ),
                            );

                            await _loadPets();
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menyimpan: $e'),
                              ),
                            );
                          }
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

  void _openRiwayat(dynamic pet) {
    final int petId = int.tryParse(pet['id'].toString()) ?? 0;
    final String petName = (pet['name'] ?? 'Hewan').toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiwayatScreen(
          petId: petId,
          petName: petName,
        ),
      ),
    );
  }

  // ===============================
  // UI
  // ===============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: const Text('Hewan Saya'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadPets,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _pets.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryLighter,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Hewan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textGray,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_pets.length}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDarker,
                                  ),
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
                              child: const Icon(
                                Icons.pets,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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
    final bool isUnsynced = pet['is_synced'] == false;
    final String? localPhotoPath = pet['local_photo_path']?.toString();
    final String? photoUrl = pet['photo']?.toString();

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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: localPhotoPath != null && localPhotoPath.isNotEmpty
                        ? Image.file(
                            File(localPhotoPath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPetInitialAvatar(pet);
                            },
                          )
                        : photoUrl != null && photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPetInitialAvatar(pet);
                                },
                              )
                            : _buildPetInitialAvatar(pet),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDarker,
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
                      const SizedBox(height: 2),
                      Text(
                        '${pet['species'] ?? ''}${pet['breed'] != null ? ' · ${pet['breed']}' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textGray,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (pet['gender'] != null)
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
                                pet['gender'].toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (pet['age'] != null) ...[
                            const SizedBox(width: 6),
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
                                pet['age'].toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
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
                    const Text(
                      'Ciri Khusus',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pet['special_marks'].toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                  if (pet['allergies'] != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Alergi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pet['allergies'].toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _openRiwayat(pet),
                  icon: const Icon(
                    Icons.medical_information_outlined,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                  label: const Text(
                    'Riwayat',
                    style: TextStyle(color: AppColors.primaryDark),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showEditDialog(pet),
                  icon: const Icon(
                    Icons.edit,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                  label: const Text(
                    'Edit',
                    style: TextStyle(color: AppColors.primaryDark),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _deletePet(pet),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppColors.danger,
                  ),
                  label: const Text(
                    'Hapus',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetInitialAvatar(dynamic pet) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: Text(
          (pet['name'] ?? 'P').toString().substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: AppColors.primaryLighter,
      child: const Icon(
        Icons.photo_camera_outlined,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
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
                    Icons.pets,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Belum ada hewan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDarker,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tambahkan hewan peliharaan pertama kamu!',
                  style: TextStyle(color: AppColors.textGray),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Hewan'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}