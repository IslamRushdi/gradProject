import 'dart:convert';

class UserData {
  String? phoneNumber;
  String? avatarURL;
  String? displayName;
  bool?   isBlind;
  String? email;

  UserData({
    this.phoneNumber,
    this.avatarURL,
    this.isBlind,
    this.email,
    this.displayName,
  });

  UserData copyWith({
    String? phoneNumber,
    String? avatarURL,
    bool?   isBlind,
    String? email,
    String? displayName,
  }) {
    return UserData(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarURL: avatarURL ?? this.avatarURL,
      isBlind: isBlind ?? this.isBlind,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'avatarURL': avatarURL,
      'isBlind': isBlind,
      'email': email,
      'displayName': displayName,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      phoneNumber: map['phoneNumber'],
      avatarURL: map['avatarURL'],
      isBlind: map['isBlind'],
      email: map['email'],
      displayName: map['displayName'],
    );
  }

  String toJson() => json.encode(toMap());

  factory UserData.fromJson(String source) => UserData.fromMap(json.decode(source));

  @override
  String toString() {
    return 'UserData(phoneNumber: $phoneNumber, avatarURL: $avatarURL, isBlind: $isBlind, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserData &&
        other.phoneNumber == phoneNumber &&
        other.avatarURL == avatarURL &&
        other.isBlind == isBlind &&
        other.email == email &&
        other.displayName == displayName;

  }

  @override
  int get hashCode {
    return phoneNumber.hashCode ^
    avatarURL.hashCode ^
    isBlind.hashCode ^
    email.hashCode ^
    displayName.hashCode;
  }
}