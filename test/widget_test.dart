import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petsync/models/pet.dart';
import 'package:petsync/models/care_task.dart';
import 'package:petsync/models/health_entry.dart';
import 'package:petsync/models/vet_clinic.dart';
import 'package:petsync/widgets/petsync_logo.dart';
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

    test('VetClinic model serialization and emergency badge handling', () {
      const clinic = VetClinic(
        id: 3,
        name: 'Metro 24/7 Animal Hospital',
        phone: '+1 555-911-PETS',
        address: '404 North Central Ave',
        city: 'Metro City',
        distanceKm: 0.8,
        rating: 4.9,
        isEmergency: true,
        services: 'ICU, Surgery, Oxygen',
        isPrimary: true,
        createdAt: '2026-11-05',
      );

      final map = clinic.toMap();
      expect(map['name'], 'Metro 24/7 Animal Hospital');
      expect(map['is_emergency'], 1);
      expect(map['is_primary'], 1);
      expect(map['distance_km'], 0.8);

      final fromMap = VetClinic.fromMap(map);
      expect(fromMap.id, 3);
      expect(fromMap.name, clinic.name);
      expect(fromMap.isEmergency, true);
      expect(fromMap.isPrimary, true);

      final updated = clinic.copyWith(name: 'Metro Emergency Animal Hospital', isPrimary: false);
      expect(updated.name, 'Metro Emergency Animal Hospital');
      expect(updated.isPrimary, false);
      expect(updated.isEmergency, true);
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
      expect(find.text('DISCOVER'), findsOneWidget);
      expect(find.byType(PetSyncLogo), findsWidgets);
    });
  });
}
