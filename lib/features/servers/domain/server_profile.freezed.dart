// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'server_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ServerProfile {

/// `null`, solange das Profil noch nicht gespeichert ist.
 int? get id; String get name; String get lanUrl; String? get externalUrl; String get user;
/// Create a copy of ServerProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerProfileCopyWith<ServerProfile> get copyWith => _$ServerProfileCopyWithImpl<ServerProfile>(this as ServerProfile, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ServerProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerProfile&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.lanUrl, _this.lanUrl) || other.lanUrl == _this.lanUrl)&&(identical(other.externalUrl, _this.externalUrl) || other.externalUrl == _this.externalUrl)&&(identical(other.user, _this.user) || other.user == _this.user));
}


@override
int get hashCode {
  final _this = this as ServerProfile;
  return Object.hash(runtimeType,_this.id,_this.name,_this.lanUrl,_this.externalUrl,_this.user);
}

@override
String toString() {
  final _this = this as ServerProfile;
  return 'ServerProfile(id: ${_this.id}, name: ${_this.name}, lanUrl: ${_this.lanUrl}, externalUrl: ${_this.externalUrl}, user: ${_this.user})';
}


}

/// @nodoc
abstract mixin class $ServerProfileCopyWith<$Res>  {
  factory $ServerProfileCopyWith(ServerProfile value, $Res Function(ServerProfile) _then) = _$ServerProfileCopyWithImpl;
@useResult
$Res call({
 int? id, String name, String lanUrl, String? externalUrl, String user
});




}
/// @nodoc
class _$ServerProfileCopyWithImpl<$Res>
    implements $ServerProfileCopyWith<$Res> {
  _$ServerProfileCopyWithImpl(this._self, this._then);

  final ServerProfile _self;
  final $Res Function(ServerProfile) _then;

/// Create a copy of ServerProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,Object? lanUrl = null,Object? externalUrl = freezed,Object? user = null,}) {
  return _then(ServerProfile(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,lanUrl: null == lanUrl ? _self.lanUrl : lanUrl // ignore: cast_nullable_to_non_nullable
as String,externalUrl: freezed == externalUrl ? _self.externalUrl : externalUrl // ignore: cast_nullable_to_non_nullable
as String?,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ServerProfile].
extension ServerProfilePatterns on ServerProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServerProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServerProfile value)  $default,){
final _that = this;
switch (_that) {
case _ServerProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServerProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ServerProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String name,  String lanUrl,  String? externalUrl,  String user)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerProfile() when $default != null:
return $default(_that.id,_that.name,_that.lanUrl,_that.externalUrl,_that.user);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String name,  String lanUrl,  String? externalUrl,  String user)  $default,) {final _that = this;
switch (_that) {
case _ServerProfile():
return $default(_that.id,_that.name,_that.lanUrl,_that.externalUrl,_that.user);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String name,  String lanUrl,  String? externalUrl,  String user)?  $default,) {final _that = this;
switch (_that) {
case _ServerProfile() when $default != null:
return $default(_that.id,_that.name,_that.lanUrl,_that.externalUrl,_that.user);case _:
  return null;

}
}

}

/// @nodoc


class _ServerProfile implements ServerProfile {
  const _ServerProfile({this.id, required this.name, required this.lanUrl, this.externalUrl, required this.user});
  

/// `null`, solange das Profil noch nicht gespeichert ist.
@override final  int? id;
@override final  String name;
@override final  String lanUrl;
@override final  String? externalUrl;
@override final  String user;

/// Create a copy of ServerProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerProfileCopyWith<_ServerProfile> get copyWith => __$ServerProfileCopyWithImpl<_ServerProfile>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.lanUrl, lanUrl) || other.lanUrl == lanUrl)&&(identical(other.externalUrl, externalUrl) || other.externalUrl == externalUrl)&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,lanUrl,externalUrl,user);
}

@override
String toString() {
    return 'ServerProfile(id: $id, name: $name, lanUrl: $lanUrl, externalUrl: $externalUrl, user: $user)';
}


}

/// @nodoc
abstract mixin class _$ServerProfileCopyWith<$Res> implements $ServerProfileCopyWith<$Res> {
  factory _$ServerProfileCopyWith(_ServerProfile value, $Res Function(_ServerProfile) _then) = __$ServerProfileCopyWithImpl;
@override @useResult
$Res call({
 int? id, String name, String lanUrl, String? externalUrl, String user
});




}
/// @nodoc
class __$ServerProfileCopyWithImpl<$Res>
    implements _$ServerProfileCopyWith<$Res> {
  __$ServerProfileCopyWithImpl(this._self, this._then);

  final _ServerProfile _self;
  final $Res Function(_ServerProfile) _then;

/// Create a copy of ServerProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,Object? lanUrl = null,Object? externalUrl = freezed,Object? user = null,}) {
  return _then(_ServerProfile(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,lanUrl: null == lanUrl ? _self.lanUrl : lanUrl // ignore: cast_nullable_to_non_nullable
as String,externalUrl: freezed == externalUrl ? _self.externalUrl : externalUrl // ignore: cast_nullable_to_non_nullable
as String?,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
