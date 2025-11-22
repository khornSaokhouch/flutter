class UserModel {
  String? message;
  User? user;
  String? token;        // JWT token from backend
  bool? needsPhone;     // Does the user need phone verification?
  String? tempToken;
  String? rememberToken; // 🔹 Added remember_token



  UserModel({this.message, this.user, this.token, this.needsPhone, this.tempToken, this.rememberToken,});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      message: json['message'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      token: json['token'],
      needsPhone: json['needs_phone'],
      tempToken: json['tempToken'],
      rememberToken: json['remember_token'], // 🔹 parse from backend
    );
  }


  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['message'] = message;
    if (user != null) data['user'] = user!.toJson();
    data['token'] = token;
    data['needs_phone'] = needsPhone;
    data['tempToken'] = tempToken;
    data['remember_token'] = rememberToken; // 🔹 include in toJson
    return data;
  }

  operator [](String other) {}
}

class User {
  int? id;
  String? name;
  String? email;
  String? phone;
  String? firebaseUid;
  String? profileImage;

  String? imageUrl;
  String? role;
  String? emailVerifiedAt;
  String? createdAt;
  String? updatedAt;
  String? rememberToken; // 🔹 Added remember_token

  User({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.firebaseUid,
    this.profileImage,
    this.imageUrl,
    this.role,
    this.emailVerifiedAt,
    this.rememberToken,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      firebaseUid: json['firebase_uid'],
      profileImage: json['profile_image'],
      imageUrl: json['image_url'],
      role: json['role'],
      emailVerifiedAt: json['email_verified_at'],
      rememberToken: json['remember_token'], // 🔹 parse from backend
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'firebase_uid': firebaseUid,
      'profile_image': profileImage,
      'image_url': imageUrl,
      'role': role,
      'email_verified_at': emailVerifiedAt,
      'remember_token': rememberToken, // 🔹 parse from backend'
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}