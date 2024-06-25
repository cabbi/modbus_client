import 'dart:async';
import 'dart:typed_data';

import 'package:modbus_client/modbus_client.dart';

/// The base Modbus request
///
/// For each Modbus request, a PDU response function code + 0x80
/// means the request has an exception.
/// The [ModbusResponseCode] defines possible modbus Exception.
///
/// Exception response PDU
/// ----------------------
/// BYTE - Function Code + 0x80
/// BYTE - Exception Code
abstract class ModbusRequest {
  final int? unitId;
  final Duration? responseTimeout;
  Uint8List get protocolDataUnit;
  FunctionCode get functionCode;
  int get responsePduLength;
  ModbusEndianness endianness;
  late Completer<ModbusResponseCode> _responseCompleter;

  ModbusRequest(
      {this.unitId,
      this.responseTimeout,
      this.endianness = ModbusEndianness.ABCD}) {
    if (protocolDataUnit.isEmpty) {
      throw ModbusException(
          context: "ModbusRequest",
          msg: "Request PDU (i.e. Protocol Data Unit) cannot be empty!");
    }
    reset();
  }

  Future<ModbusResponseCode> get responseCode async =>
      _responseCompleter.future;

  void reset() {
    _responseCompleter = Completer<ModbusResponseCode>();
  }

  void setResponseCode(ModbusResponseCode code) {
    ModbusAppLogger.fine("Request completed with code: ${code.name}");
    if (_responseCompleter.isCompleted) {
      reset();
    }
    _responseCompleter.complete(code);
  }

  void setFromPduResponse(Uint8List pdu) {
    ModbusAppLogger.finest("Response PDU: ${ModbusAppLogger.toHex(pdu)}");
    var pduView = ByteData.view(pdu.buffer);
    int functionCode = pduView.getUint8(0);

    // Any error code?
    if ((functionCode & 0x80) != 0) {
      int exceptionCode = pduView.getUint8(1);
      setResponseCode(ModbusResponseCode.fromCode(exceptionCode));
      return;
    }

    // Response completed!
    setResponseCode(internalSetFromPduResponse(pdu));
  }

  ModbusResponseCode internalSetFromPduResponse(Uint8List pdu) =>
      ModbusResponseCode.requestSucceed;
}

/// A request for a modbus element.
abstract class ModbusElementRequest extends ModbusRequest {
  ModbusElementRequest({super.unitId, super.responseTimeout, super.endianness});

  @override
  ModbusResponseCode internalSetFromPduResponse(Uint8List pdu) {
    // Assign response data
    if (functionCode.type == FunctionType.read) {
      internalSetElementData(pdu.sublist(2));
    } else if (functionCode.type == FunctionType.writeSingle) {
      internalSetElementData(pdu.sublist(3));
    }
    if (functionCode.type == FunctionType.writeMultiple) {
      internalSetElementData(protocolDataUnit.sublist(6));
    }
    return ModbusResponseCode.requestSucceed;
  }

  /// Sets the response result ot from the PDU data
  void internalSetElementData(Uint8List data);
}

/// A read request of a single element.
class ModbusReadRequest extends ModbusElementRequest {
  // Request PDU
  // -----------
  // BYTE - Function Code
  // WORD - First Address
  // WORD - Elements Count
  //
  // Response PDU
  // ------------
  // BYTE - Function Code
  // BYTE - Byte Count
  // N BYTES - Element Values

  @override
  final FunctionCode functionCode;
  @override
  final Uint8List protocolDataUnit;
  final ModbusElement element;
  ModbusReadRequest(this.element, this.protocolDataUnit, this.functionCode,
      {super.unitId, super.responseTimeout, super.endianness});

  @override
  int get responsePduLength => 2 + element.byteCount;

  @override
  void internalSetElementData(Uint8List data) {
    element.setValueFromBytes(endianness.getEndianBytes(data));
  }
}

/// A read request of an elements group.
class ModbusReadGroupRequest extends ModbusElementRequest {
  // Request PDU
  // -----------
  // BYTE - Function Code
  // WORD - First Address
  // WORD - Elements Count
  //
  // Response PDU
  // ------------
  // BYTE - Function Code
  // BYTE - Byte Count
  // N BYTES - Element Values

  @override
  final FunctionCode functionCode;
  @override
  final Uint8List protocolDataUnit;
  final ModbusElementsGroup elementGroup;
  ModbusReadGroupRequest(
      this.elementGroup, this.protocolDataUnit, this.functionCode,
      {super.unitId, super.responseTimeout, super.endianness});

  @override
  int get responsePduLength =>
      2 +
      (elementGroup.type!.isBit
          ? (elementGroup.addressRange + 7) ~/ 8
          : elementGroup.addressRange * 2);

  @override
  void internalSetElementData(Uint8List data) {
    for (var register in elementGroup) {
      if (register.type.isRegister) {
        var startIndex = (register.address - elementGroup.startAddress) * 2;
        register.setValueFromBytes(
            data.sublist(startIndex, startIndex + (register.byteCount)));
      }
      if (register.type.isBit) {
        var byteIndex = (register.address - elementGroup.startAddress) ~/ 8;
        var bitIndex = (register.address - elementGroup.startAddress) % 8;
        var byteValue = ByteData.view(data.buffer).getUint8(byteIndex);
        var bitValue = (byteValue >> bitIndex) & 0x01;
        register.value = bitValue;
      }
    }
  }
}

/// A write request of a single element.
class ModbusWriteRequest extends ModbusElementRequest {
  @override
  final FunctionCode functionCode;
  @override
  final Uint8List protocolDataUnit;
  final ModbusElement element;
  ModbusWriteRequest(this.element, this.protocolDataUnit, this.functionCode,
      {super.unitId, super.responseTimeout, super.endianness});

  // Request PDU
  // -----------
  // BYTE - Function Code
  // WORD - First Address
  // WORD - Register Value
  //
  // Response PDU
  // ------------
  // BYTE - Function Code
  // WORD - First Address
  // WORD - Register Value

  @override
  int get responsePduLength => 5;

  @override
  void internalSetElementData(Uint8List data) {
    element.setValueFromBytes(endianness.getEndianBytes(data));
  }
}

/// A write request of an elements group.
/* TODO: define multiple write "strategy"!
class ModbusWriteGroupRequest extends ModbusElementRequest {
  // Request PDU
  // -----------
  // BYTE - Function Code
  // WORD - First Address
  // WORD - Register Count
  // BYTE - Byte Count
  // N WORDS - Register values
  //
  // Response PDU
  // ------------
  // BYTE - Function Code
  // WORD - First Address
  // WORD - Register Count

  final ModbusElementsGroup elementGroup;
  ModbusWriteGroupRequest(this.elementGroup, super.protocolDataUnit, [super.unitId]);

  @override
  int get responsePduLength => 5;

  @override
  void internalSetElementData(Uint8List data);
}
*/
