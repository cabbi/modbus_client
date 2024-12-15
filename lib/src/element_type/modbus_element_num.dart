part of '../modbus_element.dart';

/// A numeric register where [type] can be [ModbusElementType.inputRegister] or
/// [ModbusElementType.inputRegister]. The returned device value
/// (i.e. raw value) can be of type Int16, Uint16, Int32 or Uint32.
///
/// This raw value might be converted into an engineering value by this formula:
///    engineering value = raw value * [multiplier] + [offset]
///
/// The string representation of the engineering value can have a unit of
/// measure [uom] and rounded decimal places [viewDecimalPlaces].
abstract class ModbusNumRegister<T extends num> extends ModbusElement<T> {
  final double multiplier;
  final double offset;
  final String uom;
  final int viewDecimalPlaces;

  ModbusNumRegister(
      {required super.name,
      super.description,
      super.onUpdate,
      required super.type,
      required super.address,
      required super.byteCount,
      this.uom = "",
      this.multiplier = 1,
      this.offset = 0,
      this.viewDecimalPlaces = 2,
      super.endianness = ModbusEndianness.ABCD});

  @override
  ModbusWriteRequest getWriteRequest(dynamic value,
      {bool rawValue = false,
      int? unitId,
      Duration? responseTimeout,
      ModbusEndianness? endianness}) {
    if (byteCount == 2) {
      return super.getWriteRequest(value,
          rawValue: rawValue,
          unitId: unitId,
          responseTimeout: responseTimeout,
          endianness: endianness ?? this.endianness);
    } else {
      var numValue = rawValue ? value : _getRawValue(value);
      return getMultipleWriteRequest(_toBytes(numValue),
          unitId: unitId,
          responseTimeout: responseTimeout,
          endianness: endianness ?? this.endianness);
    }
  }

  @override
  num _getRawValue(dynamic value) => (value - offset) ~/ multiplier;

  @override
  T? setValueFromBytes(Uint8List rawValues) {
    return value = (_fromBytes(rawValues) * multiplier) + offset as T;
  }

  @override
  String get _valueStr => _value == null
      ? "<none>"
      : "${_value!.toStringAsFixed(viewDecimalPlaces).replaceFirst(RegExp(r'\.?0*$'), '')}$uom";

  T _fromBytes(Uint8List bytes);

  Uint8List _toBytes(dynamic value);
}

/// A signed 16 bit register
class ModbusInt16Register extends ModbusNumRegister {
  ModbusInt16Register(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      super.onUpdate,
      super.uom,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(byteCount: 2);

  @override
  int _fromBytes(Uint8List bytes) => ByteData.view(bytes.buffer, 0, byteCount)
      .getInt16(0, endianness.swapByte ? Endian.little : Endian.big);

  @override
  Uint8List _toBytes(dynamic value) =>
      Uint8List(byteCount)..buffer.asByteData().setInt16(0, value);
}

/// An unsigned 16 bit register
class ModbusUint16Register extends ModbusNumRegister {
  ModbusUint16Register(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      super.onUpdate,
      super.uom,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(byteCount: 2);

  @override
  int _fromBytes(Uint8List bytes) => bytes.buffer
      .asByteData()
      .getUint16(0, endianness.swapByte ? Endian.little : Endian.big);

  @override
  Uint8List _toBytes(dynamic value) =>
      Uint8List(byteCount)..buffer.asByteData().setUint16(0, value);
}

/// A signed 32 bit register
class ModbusInt32Register extends ModbusNumRegister {
  ModbusInt32Register(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      super.onUpdate,
      super.uom,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(byteCount: 4);

  @override
  int _fromBytes(Uint8List bytes) => bytes.buffer.asByteData().getInt32(0);

  @override
  Uint8List _toBytes(dynamic value) =>
      Uint8List(byteCount)..buffer.asByteData().setInt32(0, value);
}

/// An unsigned 32 bit register
class ModbusUint32Register extends ModbusNumRegister {
  ModbusUint32Register(
      {required super.name,
      required super.address,
      required super.type,
      super.uom,
      super.description,
      super.onUpdate,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(byteCount: 4);

  @override
  int _fromBytes(Uint8List bytes) => bytes.buffer.asByteData().getUint32(0);

  @override
  Uint8List _toBytes(dynamic value) =>
      Uint8List(byteCount)..buffer.asByteData().setUint32(0, value);
}

/// A signed 64 bit register
class ModbusInt64Register extends ModbusNumRegister {
  ModbusInt64Register(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      super.onUpdate,
      super.uom,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(byteCount: 8);

  @override
  int _fromBytes(Uint8List bytes) => bytes.buffer.asByteData().getInt64(0);

  @override
  Uint8List _toBytes(dynamic value) =>
      Uint8List(byteCount)..buffer.asByteData().setInt64(0, value);
}

/// An unsigned 64 bit register
class ModbusUint64Register extends ModbusNumRegister {
  ModbusUint64Register(
      {required super.name,
      required super.address,
      required super.type,
      super.uom,
      super.description,
      super.onUpdate,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(byteCount: 8);

  @override
  int _fromBytes(Uint8List bytes) => bytes.buffer.asByteData().getUint64(0);

  @override
  Uint8List _toBytes(dynamic value) =>
      Uint8List(byteCount)..buffer.asByteData().setUint64(0, value);
}

/// A 32 bit Float register
class ModbusFloatRegister extends ModbusNumRegister<double> {
  ModbusFloatRegister(
      {required super.name,
      required super.address,
      required super.type,
      super.uom,
      super.description,
      super.onUpdate,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(byteCount: 4);

  @override
  double _getRawValue(dynamic value) => (value - offset) / multiplier;

  @override
  double _fromBytes(Uint8List bytes) => bytes.buffer.asByteData().getFloat32(0);

  @override
  Uint8List _toBytes(dynamic value) =>
      Uint8List(byteCount)..buffer.asByteData().setFloat32(0, value);
}

/// A 64 bit Double register
class ModbusDoubleRegister extends ModbusNumRegister<double> {
  ModbusDoubleRegister(
      {required super.name,
      required super.address,
      required super.type,
      super.uom,
      super.description,
      super.onUpdate,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(byteCount: 8);

  @override
  double _getRawValue(dynamic value) => (value - offset) / multiplier;

  @override
  double _fromBytes(Uint8List bytes) => bytes.buffer.asByteData().getFloat64(0);

  @override
  Uint8List _toBytes(dynamic value) =>
      Uint8List(byteCount)..buffer.asByteData().setFloat64(0, value);
}
