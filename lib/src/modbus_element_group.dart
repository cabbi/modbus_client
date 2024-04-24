import 'dart:typed_data';

import 'package:modbus_client/modbus_client.dart';

/// An element group which is guarantied to be a valid list of Modbus elements:
///  - contains homogeneous elements (i.e. same type)
///  - sorted by address
///  - does not exceed maximum address range (i.e. 2000 coils or 125 registers)
class ModbusElementsGroup extends Iterable<ModbusElement> {
  static const maxCoilsRange = 2000;
  static const maxRegistersRange = 125;

  final List<ModbusElement> _elements = [];
  int _startAddress = 0;
  int _addressRange = 0;
  ModbusElementType? _type;

  ModbusElementsGroup([Iterable<ModbusElement>? elements]) {
    if (elements != null) {
      addAll(elements);
      _checkAndUpdate([]);
    }
  }

  int get startAddress => _startAddress;
  int get addressRange => _addressRange;
  ModbusElementType? get type => _type;

  @override
  int get length => _elements.length;

  @override
  Iterator<ModbusElement> get iterator => _elements.iterator;

  ModbusElement operator [](int index) => _elements[index];

  void operator []=(int index, ModbusElement value) {
    var rollbackElements = _elements.toList();
    _elements[index] = value;
    _checkAndUpdate(rollbackElements);
  }

  /// Gets a read request from this elements group
  ModbusReadGroupRequest getReadRequest(
      {int? unitId, Duration? responseTimeout}) {
    if (length == 0) {
      throw ModbusException(
          context: "ModbusElements",
          msg: "Can not create a request for an empty group!");
    }

    var pdu = Uint8List(5);
    ByteData.view(pdu.buffer)
      ..setUint8(0, _type!.readFunction.code)
      ..setUint16(1, _startAddress)
      ..setUint16(3, _addressRange);
    return ModbusReadGroupRequest(this, pdu, _type!.readFunction,
        unitId: unitId, responseTimeout: responseTimeout);
  }

/* NO IMPLEMENTED: 
   here are some consideration that prevent me to implement writing
   to multiple-register:   
     - Multiple write requires consecutive element addresses
     - All element values should be specified and written (i.e. there is no mask
       that prevents some registers to be written). To implement elements to be
       written we might add a "write_value" variable and the requests could send 
       that. But I see all this a bit "weak" and error prone. 
  /// Gets a write request from this element.
  /// [value] is set to the element once request is successfully completed.
  /// If [rawValue] is true then the integer [value] is written as it is
  /// without any value or type conversion.
  ModbusWriteRequest getWriteRequest(
    dynamic value, {bool rawValue = false, int? unitId});
*/

  void add(ModbusElement value) {
    var rollbackElements = _elements.toList();
    _elements.add(value);
    _checkAndUpdate(rollbackElements);
  }

  void addAll(Iterable<ModbusElement> iterable) {
    var rollbackElements = _elements.toList();
    _elements.addAll(iterable);
    _checkAndUpdate(rollbackElements);
  }

  void clear() {
    _startAddress = 0;
    _addressRange = 0;
    _type = null;
    _elements.clear();
  }

  void _rollback(List<ModbusElement> rollbackElements) {
    _elements.clear();
    _elements.addAll(rollbackElements);
    _checkAndUpdate([]);
  }

  void _checkAndUpdate(List<ModbusElement> rollbackElements) {
    if (_elements.isEmpty) {
      clear();
      return;
    }
    _type = _elements.first.type;
    var isRegister = _type!.isRegister;
    // Before checking each element lets just check the length!
    var maxLength = isRegister ? maxRegistersRange : maxCoilsRange;
    if (length > maxLength) {
      _rollback(rollbackElements);
      throw ModbusException(
          context: "ModbusElements",
          msg: "Too many elements! [$length > $maxLength]");
    }
    // Same values?
    if (!_elements.any((e) => e.type == _type)) {
      _rollback(rollbackElements);
      throw ModbusException(
          context: "ModbusElements", msg: "All elements must be of same type!");
    }
    // Sort elements by address
    _elements.sort((a, b) => a.address - b.address);
    _startAddress = _elements.first.address;
    _addressRange = _elements.last.address - _startAddress;
    _addressRange += isRegister ? _elements.last.byteCount ~/ 2 : 1;
    if (_addressRange > maxLength) {
      _rollback(rollbackElements);
      throw ModbusException(
          context: "ModbusElements",
          msg: "Address range exceeds $maxLength! [$_addressRange]");
    }
  }
}
