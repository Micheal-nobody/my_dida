// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checklist_vo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChecklistVO {

 Id get id; String get name; Color get color;
/// Create a copy of ChecklistVO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChecklistVOCopyWith<ChecklistVO> get copyWith => _$ChecklistVOCopyWithImpl<ChecklistVO>(this as ChecklistVO, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChecklistVO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,color);

@override
String toString() {
  return 'ChecklistVO(id: $id, name: $name, color: $color)';
}


}

/// @nodoc
abstract mixin class $ChecklistVOCopyWith<$Res>  {
  factory $ChecklistVOCopyWith(ChecklistVO value, $Res Function(ChecklistVO) _then) = _$ChecklistVOCopyWithImpl;
@useResult
$Res call({
 Id id, String name, Color color
});




}
/// @nodoc
class _$ChecklistVOCopyWithImpl<$Res>
    implements $ChecklistVOCopyWith<$Res> {
  _$ChecklistVOCopyWithImpl(this._self, this._then);

  final ChecklistVO _self;
  final $Res Function(ChecklistVO) _then;

/// Create a copy of ChecklistVO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? color = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as Id,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}

}


/// Adds pattern-matching-related methods to [ChecklistVO].
extension ChecklistVOPatterns on ChecklistVO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChecklistVO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChecklistVO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChecklistVO value)  $default,){
final _that = this;
switch (_that) {
case _ChecklistVO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChecklistVO value)?  $default,){
final _that = this;
switch (_that) {
case _ChecklistVO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Id id,  String name,  Color color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChecklistVO() when $default != null:
return $default(_that.id,_that.name,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Id id,  String name,  Color color)  $default,) {final _that = this;
switch (_that) {
case _ChecklistVO():
return $default(_that.id,_that.name,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Id id,  String name,  Color color)?  $default,) {final _that = this;
switch (_that) {
case _ChecklistVO() when $default != null:
return $default(_that.id,_that.name,_that.color);case _:
  return null;

}
}

}

/// @nodoc


class _ChecklistVO extends ChecklistVO {
  const _ChecklistVO({required this.id, required this.name, this.color = const Color(0xFF000000)}): super._();
  

@override final  Id id;
@override final  String name;
@override@JsonKey() final  Color color;

/// Create a copy of ChecklistVO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChecklistVOCopyWith<_ChecklistVO> get copyWith => __$ChecklistVOCopyWithImpl<_ChecklistVO>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChecklistVO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,color);

@override
String toString() {
  return 'ChecklistVO(id: $id, name: $name, color: $color)';
}


}

/// @nodoc
abstract mixin class _$ChecklistVOCopyWith<$Res> implements $ChecklistVOCopyWith<$Res> {
  factory _$ChecklistVOCopyWith(_ChecklistVO value, $Res Function(_ChecklistVO) _then) = __$ChecklistVOCopyWithImpl;
@override @useResult
$Res call({
 Id id, String name, Color color
});




}
/// @nodoc
class __$ChecklistVOCopyWithImpl<$Res>
    implements _$ChecklistVOCopyWith<$Res> {
  __$ChecklistVOCopyWithImpl(this._self, this._then);

  final _ChecklistVO _self;
  final $Res Function(_ChecklistVO) _then;

/// Create a copy of ChecklistVO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? color = null,}) {
  return _then(_ChecklistVO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as Id,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}


}

// dart format on
