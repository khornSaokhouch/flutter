import 'dart:convert';

/// Shops API Response
class ShopsResponse {
  final String message;
  final List<Shop> data;

  ShopsResponse({
    required this.message,
    required this.data,
  });

  factory ShopsResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>?; // nullable
    return ShopsResponse(
      message: json['message'] ?? '',
      data: dataList != null
          ? dataList
          .map((e) => Shop.fromJson(e as Map<String, dynamic>))
          .toList()
          : [], // default empty list if null
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'data': data.map((e) => e.toJson()).toList(),
  };
}

/// Shop model
class Shop {
  final int id;
  final String name;
  final String? location;
  final int status;
  final int ownerUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String? googleMapUrl;
  final String? openTime;  // ✅ added
  final String? closeTime; // ✅ added
  final Owner owner;
  double? distanceInKm;

  Shop({
    required this.id,
    required this.name,
    this.location,
    required this.status,
    required this.ownerUserId,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.googleMapUrl,
    this.openTime,
    this.closeTime,
    required this.owner,
    this.distanceInKm,
  });

  /// Safe parsing for latitude/longitude
  static double? parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
    id: json['id'] is int
        ? json['id']
        : int.tryParse(json['id'].toString()) ?? 0,
    name: json['name']?.toString() ?? '',
    location: json['location']?.toString(),
    status: json['status'] is int
        ? json['status']
        : int.tryParse(json['status'].toString()) ?? 0,
    ownerUserId: json['owner_user_id'] is int
        ? json['owner_user_id']
        : int.tryParse(json['owner_user_id'].toString()) ?? 0,
    createdAt:
    DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
    updatedAt:
    DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
        DateTime.now(),
    latitude: parseToDouble(json['latitude']),
    longitude: parseToDouble(json['longitude']),
    imageUrl: json['image_url']?.toString(),
    googleMapUrl: json['google_map_url']?.toString(),
    openTime: json['open_time']?.toString(), // ✅ added
    closeTime: json['close_time']?.toString(), // ✅ added
    owner: json['owner'] != null
        ? Owner.fromJson(json['owner'] as Map<String, dynamic>)
        : Owner.defaultOwner(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'status': status,
    'owner_user_id': ownerUserId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'image_url': imageUrl,
    'google_map_url': googleMapUrl,
    'open_time': openTime,   // ✅ added
    'close_time': closeTime, // ✅ added
    'owner': owner.toJson(),
  };
}

/// Owner model
class Owner {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? firebaseUid;
  final String? profileImage;
  final String role;
  final String? emailVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Owner({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.firebaseUid,
    this.profileImage,
    required this.role,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Owner.fromJson(Map<String, dynamic> json) => Owner(
    id: json['id'] is int
        ? json['id']
        : int.tryParse(json['id'].toString()) ?? 0,
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    phone: json['phone']?.toString(),
    firebaseUid: json['firebase_uid']?.toString(),
    profileImage: json['profile_image']?.toString(),
    role: json['role']?.toString() ?? 'user',
    emailVerifiedAt: json['email_verified_at']?.toString(),
    createdAt:
    DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
    updatedAt:
    DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
        DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'firebase_uid': firebaseUid,
    'profile_image': profileImage,
    'role': role,
    'email_verified_at': emailVerifiedAt,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Owner.defaultOwner() => Owner(
    id: 0,
    name: 'Unknown',
    email: '',
    phone: null,
    role: 'user',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
