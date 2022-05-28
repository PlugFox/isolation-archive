import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'author.dart';

@immutable
class Commit extends Equatable {
  const Commit({
    this.sha,
    this.author,
    this.message,
    this.distinct,
    this.url,
  });

  final String? sha;
  final Author? author;
  final String? message;
  final bool? distinct;
  final String? url;

  factory Commit.fromJson(Map<String, Object?> json) => Commit(
        sha: json['sha'] as String?,
        author: json['author'] == null
            ? null
            : Author.fromJson(json['author']! as Map<String, Object?>),
        message: json['message'] as String?,
        distinct: json['distinct'] as bool?,
        url: json['url'] as String?,
      );

  Map<String, Object?> toJson() => {
        'sha': sha,
        'author': author?.toJson(),
        'message': message,
        'distinct': distinct,
        'url': url,
      };

  Commit copyWith({
    String? sha,
    Author? author,
    String? message,
    bool? distinct,
    String? url,
  }) =>
      Commit(
        sha: sha ?? this.sha,
        author: author ?? this.author,
        message: message ?? this.message,
        distinct: distinct ?? this.distinct,
        url: url ?? this.url,
      );

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [sha, author, message, distinct, url];
}
