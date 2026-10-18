import 'package:flutter/material.dart';
import '../../models/pet.dart';
import '../../models/care_task.dart';
import '../../database/database_helper.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nothing_card.dart';
import '../../widgets/nothing_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/section_header.dart';
import '../../widgets/app_snackbar.dart';
import 'care_task_form_dialog.dart';

class CareScreen extends StatefulWidget {
  const CareScreen({super.key});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  List<Pet> _pets = [];
  List<CareTask> _tasks = [];
  int? _selectedPetFilter; // null means 'ALL'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final pets = await DatabaseHelper.instance.getAllPets();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final tasks = await DatabaseHelper.instance.getTasksForDate(
      today,
      petId: _selectedPetFilter,
    );

    setState(() {
      _pets = pets;
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _toggleTask(CareTask task) async {
    await DatabaseHelper.instance.toggleCareTask(task.id!, !task.isCompleted);
    _loadData();
  }

  Future<void> _deleteTask(CareTask task) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'DELETE TASK',
      message: 'Are you sure you want to delete "${task.title}"?',
      confirmLabel: 'DELETE',
      isDestructive: true,
    );

    if (confirmed) {
      await DatabaseHelper.instance.deleteCareTask(task.id!);
      _loadData();
      if (mounted) {
        AppSnackBar.show(context, 'Task deleted.');
      }
    }
  }

  Future<void> _openAddTask() async {
    if (_pets.isEmpty) {
      AppSnackBar.show(context, 'Please add a pet first to assign care tasks.');
      return;
    }

    final created = await CareTaskFormDialog.show(
      context,
      preselectedPetId: _selectedPetFilter,
    );
    if (created == true) {
      _loadData();
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'feeding':
        return Icons.restaurant_outlined;
      case 'walking':
        return Icons.directions_walk_outlined;
      case 'grooming':
        return Icons.brush_outlined;
      default:
        return Icons.task_alt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingTasks = _tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = _tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'DAILY CARE',
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
                '${completedTasks.length}/${_tasks.length}',
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
        heroTag: 'care_fab',
        backgroundColor: AppColors.txt(context),
        foregroundColor: AppColors.bg(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'NEW TASK',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        onPressed: _openAddTask,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppColors.txt(context)),
              )
            : RefreshIndicator(
                color: AppColors.txt(context),
                backgroundColor: AppColors.surf(context),
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 8,
                    bottom: 90,
                  ),
                  children: [
                    // Pet Filter Chips
                    if (_pets.isNotEmpty) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text('ALL PETS'),
                                labelStyle: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedPetFilter == null
                                      ? AppColors.bg(context)
                                      : AppColors.txtSec(context),
                                ),
                                selected: _selectedPetFilter == null,
                                selectedColor: AppColors.txt(context),
                                backgroundColor: AppColors.surfElevated(context),
                                side: BorderSide(
                                  color: _selectedPetFilter == null
                                      ? AppColors.txt(context)
                                      : AppColors.brd(context),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _selectedPetFilter = null);
                                    _loadData();
                                  }
                                },
                              ),
                            ),
                            ..._pets.map((p) {
                              final isSelected = _selectedPetFilter == p.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(p.name.toUpperCase()),
                                  labelStyle: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.bg(context)
                                        : AppColors.txtSec(context),
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppColors.txt(context),
                                  backgroundColor: AppColors.surfElevated(context),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.txt(context)
                                        : AppColors.brd(context),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  onSelected: (sel) {
                                    setState(() {
                                      _selectedPetFilter = sel ? p.id : null;
                                    });
                                    _loadData();
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Empty State if no tasks
                    if (_tasks.isEmpty)
                      EmptyState(
                        icon: Icons.checklist_outlined,
                        title: 'NO TASKS FOR TODAY',
                        message: _pets.isEmpty
                            ? 'Add a pet profile first, then schedule daily feedings, walks, and medications.'
                            : 'All clear! Schedule daily feeding, walking, or grooming tasks to keep track.',
                        actionLabel: _pets.isNotEmpty ? 'SCHEDULE TASK' : null,
                        onAction: _pets.isNotEmpty ? _openAddTask : null,
                      )
                    else ...[
                      // PENDING TASKS SECTION
                      SectionHeader(
                        codePrefix: '// 01',
                        title: 'PENDING (${pendingTasks.length})',
                      ),
                      const SizedBox(height: 6),
                      if (pendingTasks.isEmpty)
                        NothingCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: AppColors.txt(context)),
                              const SizedBox(width: 10),
                              Text(
                                'All routines completed for today!',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: AppColors.txtSec(context),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...pendingTasks.map((t) => _buildTaskCard(t)),

                      const SizedBox(height: 24),

                      // COMPLETED TASKS SECTION
                      if (completedTasks.isNotEmpty) ...[
                        SectionHeader(
                          codePrefix: '// 02',
                          title: 'COMPLETED (${completedTasks.length})',
                        ),
                        const SizedBox(height: 6),
                        ...completedTasks.map((t) => _buildTaskCard(t)),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTaskCard(CareTask task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NothingCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Checkbox(
              value: task.isCompleted,
              activeColor: AppColors.txt(context),
              checkColor: AppColors.bg(context),
              side: BorderSide(color: AppColors.brd(context), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (_) => _toggleTask(task),
            ),
            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: task.isCompleted ? AppColors.txtMut(context) : AppColors.txt(context),
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      NothingBadge(
                        label: task.category,
                        icon: _getCategoryIcon(task.category),
                      ),
                      const SizedBox(width: 6),
                      if (task.petName != null) ...[
                        Text(
                          task.petName!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.txtSec(context),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (task.scheduledTime != null) ...[
                        Icon(Icons.access_time, size: 11, color: AppColors.txtMut(context)),
                        const SizedBox(width: 3),
                        Text(
                          task.scheduledTime!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.txtMut(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (task.notes != null && task.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.txtMut(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: AppColors.txtMut(context)),
              tooltip: 'Delete Task',
              onPressed: () => _deleteTask(task),
            ),
          ],
        ),
      ),
    );
  }
}
