import '../user.dart';

class Shop {
  final int id;
  final String name;
  final String location;
  final int status;
  final int ownerUserId;
  final String openTime;
  final String closeTime;
  final String image;
  final String createdAt;
  final String updatedAt;
  final String latitude;
  final String longitude;
  final String imageUrl;
  final User owner; // ✅ FIXED

  Shop({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.ownerUserId,
    required this.openTime,
    required this.closeTime,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.owner,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      status: json['status'],
      ownerUserId: json['owner_user_id'],
      openTime: json['open_time'],
      closeTime: json['close_time'],
      image: json['image'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      imageUrl: json['image_url'],
      owner: User.fromJson(json['owner']), // ✅ FIXED
    );
  }
}
