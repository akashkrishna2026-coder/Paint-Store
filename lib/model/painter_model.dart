class Painter {
  final String key;
  final String name;
  final String location;
  final String? phone;
  final int dailyFare;
  final String? imageUrl; // ⭐ ADDED: Optional field for the image URL

  Painter({
    required this.key,
    required this.name,
    required this.location,
    this.phone,
    required this.dailyFare,
    this.imageUrl, // ⭐ ADDED
  });

  factory Painter.fromMap(String key, Map<dynamic, dynamic> data) {
    return Painter(
      key: key,
      name: data['name'] ?? 'No Name',
      location: data['location'] ?? 'No Location',
      phone: data['phone'],
      dailyFare: (data['dailyFare'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'], // ⭐ ADDED
    );
  }
}