class ReferenceObject {
  final String name;
  final double width;
  final double height;
  final String type;

  const ReferenceObject({
    required this.name,
    required this.width,
    required this.height,
    required this.type,
  });
}

class ReferenceObjectDatabase {
  static final Map<String, ReferenceObject> coins = {
    'NT_50': ReferenceObject(
      name: '50元硬幣',
      width: 2.8,
      height: 2.8,
      type: 'coin',
    ),
  };
}
