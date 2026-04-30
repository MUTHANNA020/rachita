import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:rachita/features/medicine/domain/entities/medicine_entity.dart';
import 'package:rachita/features/medicine/domain/repositories/medicine_repository.dart';

class MockMedicineRepository extends Mock implements MedicineRepository {}

void main() {
  late MockMedicineRepository mockRepo;

  setUp(() {
    mockRepo = MockMedicineRepository();
  });

  test('Search medicines returns list of medicines', () async {
    final tMedicines = [
      MedicineEntity(nameAr: 'باراسيتامول', updatedAt: DateTime.now()),
    ];
    
    when(() => mockRepo.searchMedicines(any()))
        .thenAnswer((_) async => Right(tMedicines));

    final result = await mockRepo.searchMedicines('بارا');
    
    expect(result, Right(tMedicines));
    verify(() => mockRepo.searchMedicines('بارا')).called(1);
  });
}
