import 'package:flutter/material.dart';
import '../../models/pet.dart';
import '../../database/database_helper.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nothing_card.dart';
import '../../widgets/nothing_badge.dart';
import '../../widgets/nothing_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/pet_avatar.dart';
import '../../widgets/app_snackbar.dart';
import 'pet_form_screen.dart';
import 'pet_detail_screen.dart';
import '../pricing/pricing_screen.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  List<Pet> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    final pets = await DatabaseHelper.instance.getAllPets();
    setState(() {
      _pets = pets;
      _isLoading = false;
    });
  }

  Future<void> _openAddPet() async {
    final isPro = await DatabaseHelper.instance.isProUser();
    if (!isPro && _pets.length >= 2) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.brd(context)),
          ),
          title: const Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: AppColors.accentRed, size: 22),
              SizedBox(width: 8),
              Text(
                'FREE TIER PET LIMIT',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          content: const Text(
            'Free Starter tier supports up to 2 pet profiles.\n\nUpgrade to PetSync Pro for unlimited pet profiles, SyncAI emergency triage, and PDF medical record exports.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          actions: [
            NothingButton.secondary(
              label: 'NOT NOW',
              height: 38,
              onPressed: () => Navigator.pop(context),
            ),
            NothingButton(
              label: 'VIEW PRO PLANS',
              height: 38,
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const PricingScreen()))
                    .then((_) => _loadPets());
              },
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const PetFormScreen()),
    );
    if (result == true) {
      _loadPets();
    }
  }

  Future<void> _openPetDetail(Pet pet) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(petId: pet.id!),
      ),
    );
    _loadPets();
  }

  Future<void> _deletePet(Pet pet) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'DELETE PET',
      message: 'Delete ${pet.name}\'s profile and all associated care tasks and health records?',
      confirmLabel: 'DELETE',
      isDestructive: true,
    );

    if (confirmed) {
      await DatabaseHelper.instance.deletePet(pet.id!);
      _loadPets();
      if (mounted) {
        AppSnackBar.show(context, '${pet.name} deleted.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'PETS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfElevated(context),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.brd(context), width: 1),
              ),
              child: Text(
                '${_pets.length}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.txtSec(context),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'pets_fab',
        backgroundColor: AppColors.txt(context),
        foregroundColor: AppColors.bg(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'NEW PET',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        onPressed: _openAddPet,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.textPrimary),
              )
            : RefreshIndicator(
                color: AppColors.textPrimary,
                backgroundColor: AppColors.surface,
                onRefresh: _loadPets,
                child: _pets.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const SizedBox(height: 40),
                          EmptyState(
                            icon: Icons.pets,
                            title: 'NO PETS REGISTERED',
                            message: 'Create your first pet profile to track routines, nutrition, vaccinations, and health milestones.',
                            actionLabel: 'ADD PET',
                            onAction: _openAddPet,
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 12,
                          bottom: 90,
                        ),
                        itemCount: _pets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final pet = _pets[index];
                          return NothingCard(
                            onTap: () => _openPetDetail(pet),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PetAvatar(
                                  species: pet.species,
                                  imagePath: pet.imagePath,
                                  size: 48,
                                  borderRadius: 12,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            pet.name,
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.txt(context),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          NothingBadge(label: pet.species),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      if (pet.breed != null && pet.breed!.isNotEmpty) ...[
                                        Text(
                                          pet.breed!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Row(
                                        children: [
                                          if (pet.weight != null) ...[
                                            const Icon(Icons.monitor_weight_outlined, size: 12, color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${pet.weight} kg',
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          if (pet.dateOfBirth != null && pet.dateOfBirth!.isNotEmpty) ...[
                                            const Icon(Icons.cake_outlined, size: 12, color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              pet.dateOfBirth!,
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                                  color: AppColors.surfaceElevated,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: AppColors.border),
                                  ),
                                  onSelected: (action) {
                                    if (action == 'detail') {
                                      _openPetDetail(pet);
                                    } else if (action == 'edit') {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PetFormScreen(petToEdit: pet),
                                        ),
                                      ).then((_) => _loadPets());
                                    } else if (action == 'delete') {
                                      _deletePet(pet);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'detail',
                                      child: Text('View Details', style: TextStyle(color: AppColors.textPrimary)),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit Profile', style: TextStyle(color: AppColors.textPrimary)),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete', style: TextStyle(color: AppColors.danger)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
