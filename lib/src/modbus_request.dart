import 'dart:async';
import 'dart:typed_data';

import 'package:modbus_client/modbus_client.dart';

/// The base Modbus request
///
/// For each Modbus request, a PDU response function code + 0x80
/// means the request has an exception.
/// The [ModbusResponseCode] enum defines possible modbus Exception.
///
/// Exception response PDU
/// ----------------------
/// BYTE - Function Code + 0x80
/// BYTE - Exception Code
abstract class ModbusRequest {
  final int? unitId;
  final Duration? responseTimeout;
  final Uint8List protocolDataUnit;
  int get functionCode => protocolDataUnit[0];
  int get responsePduLength;
  late Completer<ModbusResponseCode> _responseCompleter;

  ModbusRequest(this.protocolDataUnit, {this.unitId, this.responseTimeout}) {
    if (protocolDataUnit.isEmpty) {
      throw ModbusException(
          context: "ModbusRequest",
          msg: "Request PDU (i.e. Protocol Data Unit) cannot be empty!");
    }
    reset();
  }

  Future<ModbusResponseCode> get responseCode => _responseCompleter.future;

  void reset() {
    _responseCompleter = Completer<ModbusResponseCode>();
  }

  void setResponseCode(ModbusResponseCode code) {
    ModbusAppLogger.fine("Request completed with code: ${code.name}");
    _responseCompleter.complete(code);
  }

  void setFromPduResponse(Uint8List pdu) {
    ModbusAppLogger.finest("Response PDU: ${ModbusAppLogger.toHex(pdu)}");
    var pduView = ByteData.view(pdu.buffer);
    int functionCode = pduView.getUint8(0);

    // Any error code?
    if (functionCode & 0x80 != 0) {
      int exceptionCode = pduView.getUint8(1);
      setResponseCode(ModbusResponseCode.fromCode(exceptionCode));
      return;
    }

    // Response completed!
    setResponseCode(_setFromPduResponse(functionCode, pdu));
  }

  ModbusResponseCode _setFromPduResponse(int functionCode, Uint8List pdu) =>
      ModbusResponseCode.requestSucceed;
}

/// A request for a modbus element.
abstract class ModbusElementRequest extends ModbusRequest {
  ModbusElementRequest(super.protocolDataUnit,
      {super.unitId, super.responseTimeout});

  @override
  ModbusResponseCode _setFromPduResponse(int functionCode, Uint8List pdu) {
    // Assign response data
    if (ModbusFunctionCode.isReadFunction(functionCode)) {
      _setElementData(pdu.sublist(2));
    } else if (ModbusFunctionCode.isWriteSingleFunction(functionCode)) {
      _setElementData(pdu.sublist(3));
    }
    if (ModbusFunctionCode.isWriteMultipleFunction(functionCode)) {
      _setElementData(protocolDataUnit.sublist(6));
    }
    return ModbusResponseCode.requestSucceed;
  }

  /// Sets the response result ot from the PDU data
  void _setElementData(Uint8List data);
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

  final ModbusElement element;
  ModbusReadRequest(this.element, super.protocolDataUnit,
      {super.unitId, super.responseTimeout});

  @override
  int get responsePduLength => 2 + element.byteCount;

  @override
  void _setElementData(Uint8List data) {
    element.setValueFromBytes(data);
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

  final ModbusElementsGroup elementGroup;
  ModbusReadGroupRequest(this.elementGroup, super.protocolDataUnit,
      {super.unitId, super.responseTimeout});

  @override
  int get responsePduLength =>
      2 +
      (elementGroup.type!.isBit
          ? (elementGroup.addressRange + 7) ~/ 8
          : elementGroup.addressRange * 2);

  @override
  void _setElementData(Uint8List data) {
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
  final ModbusElement element;
  ModbusWriteRequest(this.element, super.protocolDataUnit,
      {super.unitId, super.responseTimeout});

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
  void _setElementData(Uint8List data) {
    element.setValueFromBytes(data);
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
  void _setElementData(Uint8List data) {
    // TODO
  }

  @override
  int get responsePduLength => 5;

  @override
  void _setElementData(Uint8List data) {
    element.setValueFromBytes(data);
  }
}
*/
