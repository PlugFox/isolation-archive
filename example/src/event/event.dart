import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'actor.dart';
import 'payload.dart';
import 'repo.dart';

@immutable
class Event extends Equatable {
  const Event({
    this.id,
    this.type,
    this.actor,
    this.repo,
    this.payload,
    this.public,
    this.createdAt,
  });

  final String? id;
  final String? type;
  final Actor? actor;
  final Repo? repo;
  final Payload? payload;
  final bool? public;
  final DateTime? createdAt;

  factory Event.fromJson(Map<String, Object?> json) => Event(
        id: json['id'] as String?,
        type: json['type'] as String?,
        actor: json['actor'] == null
            ? null
            : Actor.fromJson(json['actor']! as Map<String, Object?>),
        repo: json['repo'] == null
            ? null
            : Repo.fromJson(json['repo']! as Map<String, Object?>),
        payload: json['payload'] == null
            ? null
            : Payload.fromJson(json['payload']! as Map<String, Object?>),
        public: json['public'] as bool?,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at']! as String),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type,
        'actor': actor?.toJson(),
        'repo': repo?.toJson(),
        'payload': payload?.toJson(),
        'public': public,
        'created_at': createdAt?.toIso8601String(),
      };

  Event copyWith({
    String? id,
    String? type,
    Actor? actor,
    Repo? repo,
    Payload? payload,
    bool? public,
    DateTime? createdAt,
  }) =>
      Event(
        id: id ?? this.id,
        type: type ?? this.type,
        actor: actor ?? this.actor,
        repo: repo ?? this.repo,
        payload: payload ?? this.payload,
        public: public ?? this.public,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [
        id,
        type,
        actor,
        repo,
        payload,
        public,
        createdAt,
      ];
}
