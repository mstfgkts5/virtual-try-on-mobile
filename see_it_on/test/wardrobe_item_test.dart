import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/models/wardrobe_item.dart';
import 'package:see_it_on/services/wardrobe_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const url =
      'https://x.supabase.co/storage/v1/object/public/wardrobe_images/uid-1/1730000000000.png';

  test('satırdan öğe: kategori ve tarih okunur', () {
    final item = WardrobeItem.fromRow({
      'id': 7,
      'image_url': url,
      'category': 'lower',
      'created_at': '2026-11-01T10:00:00+00:00',
    });
    expect(item.id, '7');
    expect(item.category, 'lower');
    expect(item.createdAt, DateTime.utc(2026, 11, 1, 10));
    expect(item.storagePath, 'uid-1/1730000000000.png');
  });

  test('kategori sütunu yoksa üst giyim varsayılır', () {
    final item = WardrobeItem.fromRow({'id': 'a', 'image_url': url, 'created_at': null});
    expect(item.category, 'upper');
    expect(item.createdAt, isNull);
  });

  test('eski kök dizin yolları da çözülür', () {
    final item = WardrobeItem.fromRow({
      'id': 1,
      'image_url': 'https://x.supabase.co/storage/v1/object/public/wardrobe_images/uid_123.png',
    });
    expect(item.storagePath, 'uid_123.png');
  });

  test('gün farkı', () {
    final now = DateTime(2026, 11, 4, 12);
    expect(daysAgo(DateTime(2026, 11, 4, 1), now), 0);
    expect(daysAgo(DateTime(2026, 11, 3, 23), now), 1);
    expect(daysAgo(DateTime(2026, 10, 28), now), 7);
  });

  test('hiç satır silinmediyse hata', () {
    expect(() => ensureDeleted(const []), throwsA(isA<NothingDeletedException>()));
    ensureDeleted(const [
      {'id': 1},
    ]); // fırlatmaz
  });

  test('eksik sütun hatası tanınır', () {
    expect(isMissingColumnError(const PostgrestException(message: 'x', code: '42703')), isTrue);
    expect(
        isMissingColumnError(const PostgrestException(
            message: "Could not find the 'category' column of 'wardrobe' in the schema cache", code: 'PGRST204')),
        isTrue);
    expect(isMissingColumnError(const PostgrestException(message: 'denied', code: '42501')), isFalse);
    expect(
        isMissingColumnError(const PostgrestException(
            message: 'null value in column "user_id" violates not-null constraint', code: '23502')),
        isFalse);
    expect(isMissingColumnError(Exception('x')), isFalse);
  });
}
