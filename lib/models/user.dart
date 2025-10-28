class UserModel {
  String? message;
  User? user;
  String? token;        // JWT token from backend
  bool? needsPhone;     // Does the user need phone verification?
  String? tempToken;


  UserModel({this.message, this.user, this.token, this.needsPhone, this.tempToken});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      message: json['message'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      token: json['token'],
      needsPhone: json['needs_phone'],
      tempToken: json['tempToken'],
    );
  }


  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['message'] = message;
    if (user != null) data['user'] = user!.toJson();
    data['token'] = token;
    data['needs_phone'] = needsPhone;
    data['tempToken'] = tempToken;
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
  String? role;
  String? emailVerifiedAt;
  String? createdAt;
  String? updatedAt;

  User({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.firebaseUid,
    this.profileImage,
    this.role,
    this.emailVerifiedAt,
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
      role: json['role'],
      emailVerifiedAt: json['email_verified_at'],
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
      'role': role,
      'email_verified_at': emailVerifiedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}