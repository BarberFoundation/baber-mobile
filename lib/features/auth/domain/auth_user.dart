import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final String? cpf;

  const AuthUser({required this.id, required this.name, this.phone, this.email, this.cpf});

  bool get needsName => name == null;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: json['name'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        cpf: json['cpf'] as String?,
      );

  @override
  List<Object?> get props => [id, name, phone, email, cpf];
}

class AuthResult extends Equatable {
  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  const AuthResult({required this.accessToken, required this.refreshToken, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}
