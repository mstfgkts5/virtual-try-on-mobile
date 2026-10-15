class GarmentItem {
  final String id;
  final String name;
  final String designer;
  final String assetPath;
  final String category; // 'Outerwear', 'Tops', 'Dresses', etc.
  final String price;

  const GarmentItem({
    required this.id,
    required this.name,
    required this.designer,
    required this.assetPath,
    required this.category,
    this.price = '\$890',
  });
}
