import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'commit.dart';

@immutable
class Payload extends Equatable {
  const Payload({
    this.pushId,
    this.size,
    this.distinctSize,
    this.ref,
    this.head,
    this.before,
    this.commits,
  });

  final int? pushId;
  final int? size;
  final int? distinctSize;
  final String? ref;
  final String? head;
  final String? before;
  final List<Commit>? commits;

  factory Payload.fromJson(Map<String, Object?> json) => Payload(
        pushId: json['push_id'] as int?,
        size: json['size'] as int?,
        distinctSize: json['distinct_size'] as int?,
        ref: json['ref'] as String?,
        head: json['head'] as String?,
        before: json['before'] as String?,
        commits: (json['commits'] as List<Object?>?)
            ?.map((e) => Commit.fromJson(e as Map<String, Object?>))
            .toList(),
      );

  Map<String, Object?> toJson() => {
        'push_id': pushId,
        'size': size,
        'distinct_size': distinctSize,
        'ref': ref,
        'head': head,
        'before': before,
        'commits': commits?.map((e) => e.toJson()).toList(),
      };

  Payload copyWith({
    int? pushId,
    int? size,
    int? distinctSize,
    String? ref,
    String? head,
    String? before,
    List<Commit>? commits,
  }) =>
      Payload(
        pushId: pushId ?? this.pushId,
        size: size ?? this.size,
        distinctSize: distinctSize ?? this.distinctSize,
        ref: ref ?? this.ref,
        head: head ?? this.head,
        before: before ?? this.before,
        commits: commits ?? this.commits,
      );

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [
        pushId,
        size,
        distinctSize,
        ref,
        head,
        before,
        commits,
      ];
}
