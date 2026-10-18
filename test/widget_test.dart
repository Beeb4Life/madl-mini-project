import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petsync/models/pet.dart';
import 'package:petsync/models/care_task.dart';
import 'package:petsync/models/health_entry.dart';
import 'package:petsync/theme/theme_controller.dart';
import 'package:petsync/main.dart';

void main() {
  group('PetSync Model Unit Tests', () {
    test('Pet model serialization with imagePath and copyWith', () {
      final pet = Pet(
        id: 1,
        name: 'Luna',
        species: 'Dog',
        breed: 'Border Collie',
        dateOfBirth: '2023-04-12',
        weight: 18.5,
        notes: 'High energy',
        imagePath: 'avatar:dog',
      );

      final map = pet.toMap();
      expect(map['id'], 1);
      expect(map['name'], 'Luna');
      expect(map['species'], 'Dog');
      expect(map['weight'], 18.5);
      expect(map['image_path'], 'avatar:dog');

      final fromMap = Pet.fromMap(map);
      expect(fromMap.id, pet.id);
      expect(fromMap.name, pet.name);
      expect(fromMap.species, pet.species);
      expect(fromMap.weight, pet.weight);
      expect(fromMap.imagePath, 'avatar:dog');

      final updated = pet.copyWith(name: 'Luna Star', weight: 19.0, imagePath: '/path/to/pic.jpg');
      expect(updated.name, 'Luna Star');
      expect(updated.weight, 19.0);
      expect(updated.species, 'Dog');
      expect(updated.imagePath, '/path/to/pic.jpg');
    });

    test('CareTask model serialization and category handling', () {
      final task = CareTask(
        id: 10,
        petId: 1,
        title: 'Morning Walk',
        category: 'walking',
        scheduledTime: '07:30',
        isCompleted: false,
        taskDate: '2026-10-18',
      );

      final map = task.toMap();
      expect(map['title'], 'Morning Walk');
      expect(map['category'], 'walking');
      expect(map['is_completed'], 0);

      final fromMap = CareTask.fromMap(map);
      expect(fromMap.title, 'Morning Walk');
      expect(fromMap.isCompleted, false);

      final completed = task.copyWith(isCompleted: true);
      expect(completed.isCompleted, true);
      expect(completed.toMap()['is_completed'], 1);
    });

    test('HealthEntry model serialization with image attachment', () {
      final entry = HealthEntry(
        id: 5,
        petId: 1,
        entryType: 'vaccination',
        entryDate: '2026-10-18',
        title: 'Rabies Booster',
        veterinarian: 'Dr. Vance',
        notes: 'Next booster in 1 year',
        imagePath: '/path/to/receipt.jpg',
      );

      final map = entry.toMap();
      expect(map['entry_type'], 'vaccination');
      expect(map['veterinarian'], 'Dr. Vance');
      expect(map['image_path'], '/path/to/receipt.jpg');

      final fromMap = HealthEntry.fromMap(map);
      expect(fromMap.title, 'Rabies Booster');
      expect(fromMap.entryType, 'vaccination');
      expect(fromMap.imagePath, '/path/to/receipt.jpg');
    });

    test('ThemeController toggles theme mode', () {
      final controller = ThemeController.instance;
      controller.themeModeNotifier.value = ThemeMode.dark;
      expect(controller.isDarkMode, true);

      controller.themeModeNotifier.value = ThemeMode.light;
      expect(controller.isDarkMode, false);
      expect(controller.themeMode, ThemeMode.light);
    });
  });

  group('PetSync Widget Smoke Tests', () {
    testWidgets('App renders main navigation bar, tabs, and theme toggle', (WidgetTester tester) async {
      await tester.pumpWidget(const PetSyncApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PETSYNC'), findsOneWidget);
      expect(find.text('OVERVIEW'), findsOneWidget);
      expect(find.text('PETS'), findsOneWidget);
      expect(find.text('CARE'), findsOneWidget);
      expect(find.text('HEALTH'), findsOneWidget);
    });
  });
}
