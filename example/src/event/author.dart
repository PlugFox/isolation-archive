import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class Author extends Equatable {
  const Author({this.email, this.name});

  final String? email;
  final String? name;

  factory Author.fromJson(Map<String, Object?> json) => Author(
        email: json['email'] as String?,
        name: json['name'] as String?,
      );

  Map<String, Object?> toJson() => {
        'email': email,
        'name': name,
      };

  Author copyWith({
    String? email,
    String? name,
  }) =>
      Author(
        email: email ?? this.email,
        name: name ?? this.name,
      );

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [email, name];
}
