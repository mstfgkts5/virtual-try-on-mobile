import 'dart:typed_data';

import 'package:see_it_on/models/wardrobe_item.dart';
import 'package:see_it_on/services/wardrobe_repository.dart';

class FakeWardrobeRepository implements WardrobeRepository {
  FakeWardrobeRepository({this.email = 'a@b.co', List<WardrobeItem>? items, this.failFetch = false})
      : items = items ?? [];

  final String? email;
  final List<WardrobeItem> items;
  bool failFetch;
  final deleted = <String>[];
  final added = <String>[]; // eklenen kategoriler

  @override
  String? get currentUserEmail => email;

  @override
  Future<List<WardrobeItem>> fetch() async {
    if (failFetch) throw Exception('offline');
    return List.of(items);
  }

  @override
  Future<void> add(Uint8List pngBytes, String category) async {
    if (email == null) throw const NotSignedInException();
    added.add(category);
  }

  @override
  Future<void> delete(WardrobeItem item) async {
    deleted.add(item.id);
    items.removeWhere((i) => i.id == item.id);
  }
}
