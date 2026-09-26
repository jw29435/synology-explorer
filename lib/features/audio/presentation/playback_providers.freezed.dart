// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AudioState implements DiagnosticableTreeMixin {

 PlaybackQueue get queue;/// Ordner, aus dem gespielt wird (Kopf von Screen 12).
 String? get folder; bool get playing; bool get loading; Duration? get duration; QueueRepeat get repeat; double get speed;/// Ende des Sleep-Timers mit fester Dauer.
 DateTime? get sleepEndsAt; bool get sleepEndOfTrack; TrackInfo? get info; Object? get error;
/// Create a copy of AudioState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioStateCopyWith<AudioState> get copyWith => _$AudioStateCopyWithImpl<AudioState>(this as AudioState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as AudioState;
  properties
    ..add(DiagnosticsProperty('type', 'AudioState'))
    ..add(DiagnosticsProperty('queue', _this.queue))..add(DiagnosticsProperty('folder', _this.folder))..add(DiagnosticsProperty('playing', _this.playing))..add(DiagnosticsProperty('loading', _this.loading))..add(DiagnosticsProperty('duration', _this.duration))..add(DiagnosticsProperty('repeat', _this.repeat))..add(DiagnosticsProperty('speed', _this.speed))..add(DiagnosticsProperty('sleepEndsAt', _this.sleepEndsAt))..add(DiagnosticsProperty('sleepEndOfTrack', _this.sleepEndOfTrack))..add(DiagnosticsProperty('info', _this.info))..add(DiagnosticsProperty('error', _this.error));
}

@override
bool operator ==(Object other) {
  final _this = this as AudioState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioState&&(identical(other.queue, _this.queue) || other.queue == _this.queue)&&(identical(other.folder, _this.folder) || other.folder == _this.folder)&&(identical(other.playing, _this.playing) || other.playing == _this.playing)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.repeat, _this.repeat) || other.repeat == _this.repeat)&&(identical(other.speed, _this.speed) || other.speed == _this.speed)&&(identical(other.sleepEndsAt, _this.sleepEndsAt) || other.sleepEndsAt == _this.sleepEndsAt)&&(identical(other.sleepEndOfTrack, _this.sleepEndOfTrack) || other.sleepEndOfTrack == _this.sleepEndOfTrack)&&(identical(other.info, _this.info) || other.info == _this.info)&&const DeepCollectionEquality().equals(other.error, _this.error));
}


@override
int get hashCode {
  final _this = this as AudioState;
  return Object.hash(runtimeType,_this.queue,_this.folder,_this.playing,_this.loading,_this.duration,_this.repeat,_this.speed,_this.sleepEndsAt,_this.sleepEndOfTrack,_this.info,const DeepCollectionEquality().hash(_this.error));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as AudioState;
  return 'AudioState(queue: ${_this.queue}, folder: ${_this.folder}, playing: ${_this.playing}, loading: ${_this.loading}, duration: ${_this.duration}, repeat: ${_this.repeat}, speed: ${_this.speed}, sleepEndsAt: ${_this.sleepEndsAt}, sleepEndOfTrack: ${_this.sleepEndOfTrack}, info: ${_this.info}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $AudioStateCopyWith<$Res>  {
  factory $AudioStateCopyWith(AudioState value, $Res Function(AudioState) _then) = _$AudioStateCopyWithImpl;
@useResult
$Res call({
 PlaybackQueue queue, String? folder, bool playing, bool loading, Duration? duration, QueueRepeat repeat, double speed, DateTime? sleepEndsAt, bool sleepEndOfTrack, TrackInfo? info, Object? error
});




}
/// @nodoc
class _$AudioStateCopyWithImpl<$Res>
    implements $AudioStateCopyWith<$Res> {
  _$AudioStateCopyWithImpl(this._self, this._then);

  final AudioState _self;
  final $Res Function(AudioState) _then;

/// Create a copy of AudioState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? queue = null,Object? folder = freezed,Object? playing = null,Object? loading = null,Object? duration = freezed,Object? repeat = null,Object? speed = null,Object? sleepEndsAt = freezed,Object? sleepEndOfTrack = null,Object? info = freezed,Object? error = freezed,}) {
  return _then(AudioState(
queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as PlaybackQueue,folder: freezed == folder ? _self.folder : folder // ignore: cast_nullable_to_non_nullable
as String?,playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,repeat: null == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as QueueRepeat,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,sleepEndsAt: freezed == sleepEndsAt ? _self.sleepEndsAt : sleepEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,sleepEndOfTrack: null == sleepEndOfTrack ? _self.sleepEndOfTrack : sleepEndOfTrack // ignore: cast_nullable_to_non_nullable
as bool,info: freezed == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as TrackInfo?,error: freezed == error ? _self.error : error ,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioState].
extension AudioStatePatterns on AudioState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioState value)  $default,){
final _that = this;
switch (_that) {
case _AudioState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioState value)?  $default,){
final _that = this;
switch (_that) {
case _AudioState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlaybackQueue queue,  String? folder,  bool playing,  bool loading,  Duration? duration,  QueueRepeat repeat,  double speed,  DateTime? sleepEndsAt,  bool sleepEndOfTrack,  TrackInfo? info,  Object? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioState() when $default != null:
return $default(_that.queue,_that.folder,_that.playing,_that.loading,_that.duration,_that.repeat,_that.speed,_that.sleepEndsAt,_that.sleepEndOfTrack,_that.info,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlaybackQueue queue,  String? folder,  bool playing,  bool loading,  Duration? duration,  QueueRepeat repeat,  double speed,  DateTime? sleepEndsAt,  bool sleepEndOfTrack,  TrackInfo? info,  Object? error)  $default,) {final _that = this;
switch (_that) {
case _AudioState():
return $default(_that.queue,_that.folder,_that.playing,_that.loading,_that.duration,_that.repeat,_that.speed,_that.sleepEndsAt,_that.sleepEndOfTrack,_that.info,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlaybackQueue queue,  String? folder,  bool playing,  bool loading,  Duration? duration,  QueueRepeat repeat,  double speed,  DateTime? sleepEndsAt,  bool sleepEndOfTrack,  TrackInfo? info,  Object? error)?  $default,) {final _that = this;
switch (_that) {
case _AudioState() when $default != null:
return $default(_that.queue,_that.folder,_that.playing,_that.loading,_that.duration,_that.repeat,_that.speed,_that.sleepEndsAt,_that.sleepEndOfTrack,_that.info,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _AudioState extends AudioState with DiagnosticableTreeMixin {
  const _AudioState({this.queue = PlaybackQueue.empty, this.folder, this.playing = false, this.loading = false, this.duration, this.repeat = QueueRepeat.off, this.speed = 1.0, this.sleepEndsAt, this.sleepEndOfTrack = false, this.info, this.error}): super._();
  

@override@JsonKey() final  PlaybackQueue queue;
/// Ordner, aus dem gespielt wird (Kopf von Screen 12).
@override final  String? folder;
@override@JsonKey() final  bool playing;
@override@JsonKey() final  bool loading;
@override final  Duration? duration;
@override@JsonKey() final  QueueRepeat repeat;
@override@JsonKey() final  double speed;
/// Ende des Sleep-Timers mit fester Dauer.
@override final  DateTime? sleepEndsAt;
@override@JsonKey() final  bool sleepEndOfTrack;
@override final  TrackInfo? info;
@override final  Object? error;

/// Create a copy of AudioState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioStateCopyWith<_AudioState> get copyWith => __$AudioStateCopyWithImpl<_AudioState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'AudioState'))
    ..add(DiagnosticsProperty('queue', queue))..add(DiagnosticsProperty('folder', folder))..add(DiagnosticsProperty('playing', playing))..add(DiagnosticsProperty('loading', loading))..add(DiagnosticsProperty('duration', duration))..add(DiagnosticsProperty('repeat', repeat))..add(DiagnosticsProperty('speed', speed))..add(DiagnosticsProperty('sleepEndsAt', sleepEndsAt))..add(DiagnosticsProperty('sleepEndOfTrack', sleepEndOfTrack))..add(DiagnosticsProperty('info', info))..add(DiagnosticsProperty('error', error));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioState&&(identical(other.queue, queue) || other.queue == queue)&&(identical(other.folder, folder) || other.folder == folder)&&(identical(other.playing, playing) || other.playing == playing)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.repeat, repeat) || other.repeat == repeat)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.sleepEndsAt, sleepEndsAt) || other.sleepEndsAt == sleepEndsAt)&&(identical(other.sleepEndOfTrack, sleepEndOfTrack) || other.sleepEndOfTrack == sleepEndOfTrack)&&(identical(other.info, info) || other.info == info)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode {
    return Object.hash(runtimeType,queue,folder,playing,loading,duration,repeat,speed,sleepEndsAt,sleepEndOfTrack,info,const DeepCollectionEquality().hash(error));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'AudioState(queue: $queue, folder: $folder, playing: $playing, loading: $loading, duration: $duration, repeat: $repeat, speed: $speed, sleepEndsAt: $sleepEndsAt, sleepEndOfTrack: $sleepEndOfTrack, info: $info, error: $error)';
}


}

/// @nodoc
abstract mixin class _$AudioStateCopyWith<$Res> implements $AudioStateCopyWith<$Res> {
  factory _$AudioStateCopyWith(_AudioState value, $Res Function(_AudioState) _then) = __$AudioStateCopyWithImpl;
@override @useResult
$Res call({
 PlaybackQueue queue, String? folder, bool playing, bool loading, Duration? duration, QueueRepeat repeat, double speed, DateTime? sleepEndsAt, bool sleepEndOfTrack, TrackInfo? info, Object? error
});




}
/// @nodoc
class __$AudioStateCopyWithImpl<$Res>
    implements _$AudioStateCopyWith<$Res> {
  __$AudioStateCopyWithImpl(this._self, this._then);

  final _AudioState _self;
  final $Res Function(_AudioState) _then;

/// Create a copy of AudioState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? queue = null,Object? folder = freezed,Object? playing = null,Object? loading = null,Object? duration = freezed,Object? repeat = null,Object? speed = null,Object? sleepEndsAt = freezed,Object? sleepEndOfTrack = null,Object? info = freezed,Object? error = freezed,}) {
  return _then(_AudioState(
queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as PlaybackQueue,folder: freezed == folder ? _self.folder : folder // ignore: cast_nullable_to_non_nullable
as String?,playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,repeat: null == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as QueueRepeat,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,sleepEndsAt: freezed == sleepEndsAt ? _self.sleepEndsAt : sleepEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,sleepEndOfTrack: null == sleepEndOfTrack ? _self.sleepEndOfTrack : sleepEndOfTrack // ignore: cast_nullable_to_non_nullable
as bool,info: freezed == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as TrackInfo?,error: freezed == error ? _self.error : error ,
  ));
}


}

// dart format on
