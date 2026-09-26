// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nas_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NasEntry {

 String get path; String get name; bool get isDir; NasFileType get type; int? get size; DateTime? get mtime; NasPerm? get perm;/// Nur bei `getinfo` (Info-Sheet) befüllt.
 DateTime? get crtime;/// Letzte Statusänderung; im Papierkorb ungefähr der Löschzeitpunkt.
 DateTime? get ctime; String? get owner; String? get group; int? get posix;
/// Create a copy of NasEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NasEntryCopyWith<NasEntry> get copyWith => _$NasEntryCopyWithImpl<NasEntry>(this as NasEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as NasEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NasEntry&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.isDir, _this.isDir) || other.isDir == _this.isDir)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.mtime, _this.mtime) || other.mtime == _this.mtime)&&(identical(other.perm, _this.perm) || other.perm == _this.perm)&&(identical(other.crtime, _this.crtime) || other.crtime == _this.crtime)&&(identical(other.ctime, _this.ctime) || other.ctime == _this.ctime)&&(identical(other.owner, _this.owner) || other.owner == _this.owner)&&(identical(other.group, _this.group) || other.group == _this.group)&&(identical(other.posix, _this.posix) || other.posix == _this.posix));
}


@override
int get hashCode {
  final _this = this as NasEntry;
  return Object.hash(runtimeType,_this.path,_this.name,_this.isDir,_this.type,_this.size,_this.mtime,_this.perm,_this.crtime,_this.ctime,_this.owner,_this.group,_this.posix);
}

@override
String toString() {
  final _this = this as NasEntry;
  return 'NasEntry(path: ${_this.path}, name: ${_this.name}, isDir: ${_this.isDir}, type: ${_this.type}, size: ${_this.size}, mtime: ${_this.mtime}, perm: ${_this.perm}, crtime: ${_this.crtime}, ctime: ${_this.ctime}, owner: ${_this.owner}, group: ${_this.group}, posix: ${_this.posix})';
}


}

/// @nodoc
abstract mixin class $NasEntryCopyWith<$Res>  {
  factory $NasEntryCopyWith(NasEntry value, $Res Function(NasEntry) _then) = _$NasEntryCopyWithImpl;
@useResult
$Res call({
 String path, String name, bool isDir, NasFileType type, int? size, DateTime? mtime, NasPerm? perm, DateTime? crtime, DateTime? ctime, String? owner, String? group, int? posix
});




}
/// @nodoc
class _$NasEntryCopyWithImpl<$Res>
    implements $NasEntryCopyWith<$Res> {
  _$NasEntryCopyWithImpl(this._self, this._then);

  final NasEntry _self;
  final $Res Function(NasEntry) _then;

/// Create a copy of NasEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? name = null,Object? isDir = null,Object? type = null,Object? size = freezed,Object? mtime = freezed,Object? perm = freezed,Object? crtime = freezed,Object? ctime = freezed,Object? owner = freezed,Object? group = freezed,Object? posix = freezed,}) {
  return _then(NasEntry(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isDir: null == isDir ? _self.isDir : isDir // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NasFileType,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,mtime: freezed == mtime ? _self.mtime : mtime // ignore: cast_nullable_to_non_nullable
as DateTime?,perm: freezed == perm ? _self.perm : perm // ignore: cast_nullable_to_non_nullable
as NasPerm?,crtime: freezed == crtime ? _self.crtime : crtime // ignore: cast_nullable_to_non_nullable
as DateTime?,ctime: freezed == ctime ? _self.ctime : ctime // ignore: cast_nullable_to_non_nullable
as DateTime?,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String?,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String?,posix: freezed == posix ? _self.posix : posix // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [NasEntry].
extension NasEntryPatterns on NasEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NasEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NasEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NasEntry value)  $default,){
final _that = this;
switch (_that) {
case _NasEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NasEntry value)?  $default,){
final _that = this;
switch (_that) {
case _NasEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String name,  bool isDir,  NasFileType type,  int? size,  DateTime? mtime,  NasPerm? perm,  DateTime? crtime,  DateTime? ctime,  String? owner,  String? group,  int? posix)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NasEntry() when $default != null:
return $default(_that.path,_that.name,_that.isDir,_that.type,_that.size,_that.mtime,_that.perm,_that.crtime,_that.ctime,_that.owner,_that.group,_that.posix);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String name,  bool isDir,  NasFileType type,  int? size,  DateTime? mtime,  NasPerm? perm,  DateTime? crtime,  DateTime? ctime,  String? owner,  String? group,  int? posix)  $default,) {final _that = this;
switch (_that) {
case _NasEntry():
return $default(_that.path,_that.name,_that.isDir,_that.type,_that.size,_that.mtime,_that.perm,_that.crtime,_that.ctime,_that.owner,_that.group,_that.posix);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String name,  bool isDir,  NasFileType type,  int? size,  DateTime? mtime,  NasPerm? perm,  DateTime? crtime,  DateTime? ctime,  String? owner,  String? group,  int? posix)?  $default,) {final _that = this;
switch (_that) {
case _NasEntry() when $default != null:
return $default(_that.path,_that.name,_that.isDir,_that.type,_that.size,_that.mtime,_that.perm,_that.crtime,_that.ctime,_that.owner,_that.group,_that.posix);case _:
  return null;

}
}

}

/// @nodoc


class _NasEntry implements NasEntry {
  const _NasEntry({required this.path, required this.name, required this.isDir, required this.type, this.size, this.mtime, this.perm, this.crtime, this.ctime, this.owner, this.group, this.posix});
  

@override final  String path;
@override final  String name;
@override final  bool isDir;
@override final  NasFileType type;
@override final  int? size;
@override final  DateTime? mtime;
@override final  NasPerm? perm;
/// Nur bei `getinfo` (Info-Sheet) befüllt.
@override final  DateTime? crtime;
/// Letzte Statusänderung; im Papierkorb ungefähr der Löschzeitpunkt.
@override final  DateTime? ctime;
@override final  String? owner;
@override final  String? group;
@override final  int? posix;

/// Create a copy of NasEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NasEntryCopyWith<_NasEntry> get copyWith => __$NasEntryCopyWithImpl<_NasEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NasEntry&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.isDir, isDir) || other.isDir == isDir)&&(identical(other.type, type) || other.type == type)&&(identical(other.size, size) || other.size == size)&&(identical(other.mtime, mtime) || other.mtime == mtime)&&(identical(other.perm, perm) || other.perm == perm)&&(identical(other.crtime, crtime) || other.crtime == crtime)&&(identical(other.ctime, ctime) || other.ctime == ctime)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.group, group) || other.group == group)&&(identical(other.posix, posix) || other.posix == posix));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path,name,isDir,type,size,mtime,perm,crtime,ctime,owner,group,posix);
}

@override
String toString() {
    return 'NasEntry(path: $path, name: $name, isDir: $isDir, type: $type, size: $size, mtime: $mtime, perm: $perm, crtime: $crtime, ctime: $ctime, owner: $owner, group: $group, posix: $posix)';
}


}

/// @nodoc
abstract mixin class _$NasEntryCopyWith<$Res> implements $NasEntryCopyWith<$Res> {
  factory _$NasEntryCopyWith(_NasEntry value, $Res Function(_NasEntry) _then) = __$NasEntryCopyWithImpl;
@override @useResult
$Res call({
 String path, String name, bool isDir, NasFileType type, int? size, DateTime? mtime, NasPerm? perm, DateTime? crtime, DateTime? ctime, String? owner, String? group, int? posix
});




}
/// @nodoc
class __$NasEntryCopyWithImpl<$Res>
    implements _$NasEntryCopyWith<$Res> {
  __$NasEntryCopyWithImpl(this._self, this._then);

  final _NasEntry _self;
  final $Res Function(_NasEntry) _then;

/// Create a copy of NasEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,Object? isDir = null,Object? type = null,Object? size = freezed,Object? mtime = freezed,Object? perm = freezed,Object? crtime = freezed,Object? ctime = freezed,Object? owner = freezed,Object? group = freezed,Object? posix = freezed,}) {
  return _then(_NasEntry(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isDir: null == isDir ? _self.isDir : isDir // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NasFileType,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,mtime: freezed == mtime ? _self.mtime : mtime // ignore: cast_nullable_to_non_nullable
as DateTime?,perm: freezed == perm ? _self.perm : perm // ignore: cast_nullable_to_non_nullable
as NasPerm?,crtime: freezed == crtime ? _self.crtime : crtime // ignore: cast_nullable_to_non_nullable
as DateTime?,ctime: freezed == ctime ? _self.ctime : ctime // ignore: cast_nullable_to_non_nullable
as DateTime?,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String?,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String?,posix: freezed == posix ? _self.posix : posix // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
