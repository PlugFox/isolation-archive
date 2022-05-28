import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class Repo extends Equatable {
  const Repo({this.id, this.name, this.url});

  final int? id;
  final String? name;
  final String? url;

  factory Repo.fromJson(Map<String, Object?> json) => Repo(
        id: json['id'] as int?,
        name: json['name'] as String?,
        url: json['url'] as String?,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'url': url,
      };

  Repo copyWith({
    int? id,
    String? name,
    String? url,
  }) =>
      Repo(
        id: id ?? this.id,
        name: name ?? this.name,
        url: url ?? this.url,
      );

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [id, name, url];
}
