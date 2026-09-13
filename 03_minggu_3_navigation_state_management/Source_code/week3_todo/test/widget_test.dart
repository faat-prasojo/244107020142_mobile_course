import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Pastikan nama package ini sesuai dengan nama proyek di pubspec.yaml Anda
import 'package:week3_todo/main.dart'; 

void main() {
  testWidgets('menambah tugas baru', (tester) async {
    
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle(); 
    expect(find.text('Belum ada tugas'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Kerjakan PR minggu 3');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle(); 

    expect(find.text('Kerjakan PR minggu 3'), findsOneWidget);
  });
}