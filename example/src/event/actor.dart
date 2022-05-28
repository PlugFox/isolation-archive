import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class Actor extends Equatable {
  const Actor({
    this.id,
    this.login,
    this.gravatarId,
    this.url,
    this.avatarUrl,
  });

  final int? id;
  final String? login;
  final String? gravatarId;
  final String? url;
  final String? avatarUrl;

  factory Actor.fromJson(Map<String, Object?> json) => Actor(
        id: json['id'] as int?,
        login: json['login'] as String?,
        gravatarId: json['gravatar_id'] as String?,
        url: json['url'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'login': login,
        'gravatar_id': gravatarId,
        'url': url,
        'avatar_url': avatarUrl,
      };

  Actor copyWith({
    int? id,
    String? login,
    String? gravatarId,
    String? url,
    String? avatarUrl,
  }) =>
      Actor(
        id: id ?? this.id,
        login: login ?? this.login,
        gravatarId: gravatarId ?? this.gravatarId,
        url: url ?? this.url,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [id, login, gravatarId, url, avatarUrl];
}
