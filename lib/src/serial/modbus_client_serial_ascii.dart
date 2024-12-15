part of 'modbus_client_serial.dart';

/// The serial Modbus ASCII client class.
class ModbusClientSerialAsciiBase extends ModbusClientSerial {
  ModbusClientSerialAsciiBase(
      {required super.serialPort,
      super.unitId,
      super.connectionMode = ModbusConnectionMode.autoConnectAndKeepConnected,
      super.responseTimeout = const Duration(seconds: 3)});

  @override
  int get checksumByteCount => 1;

  // Returns the modbus telegram out of this request's PDU
  @override
  Uint8List _getTxTelegram(ModbusRequest request, int unitId) {
    List<int> msg = [unitId];
    msg += request.protocolDataUnit;
    msg.add(computeLRC(msg));
    msg = toModbusAscii(msg);
    msg.insert(0, ':'.codeUnits[0]);
    msg.addAll('\r\n'.codeUnits);
    return Uint8List.fromList(msg);
  }

  /// Read response from device.
  @override
  Future<ModbusResponseCode> _readResponseHeader(
      _ModbusSerialResponse response, Duration timeout) async {
    try {
      // Read header data
      var byteCount = 3 * 2 + 1;
      var rxData = await serialPort.read(byteCount, timeout: timeout);

      // Received requested data?
      if (rxData.length < byteCount) {
        return ModbusResponseCode.requestTimeout;
      }

      // Check the leading ':' ascii telegram char
      if (rxData[0] != 58) {
        return ModbusResponseCode.requestRxFailed;
      }

      // NOTE: remove the leading ':' ascii telegram char
      response.setRxData(fromModbusAscii(rxData.sublist(1)));
    } catch (ex) {
      ModbusAppLogger.severe(
          "Unexpected exception in reading ASCII message Header", ex);
    }

    // Header has been acquired
    return response.headerResponseCode;
  }

  /// Reads the full pdu response from device.
  ///
  /// NOTE: response header should be already being read!
  @override
  Future<ModbusResponseCode> _readResponsePdu(
      _ModbusSerialResponse response, Duration timeout) async {
    try {
      // Header has been already acquired (i.e. -2) + lrc + /r/n
      int byteCount = 2 * (response.request.responsePduLength - 2) + 3;
      var rxData = await serialPort.read(byteCount, timeout: timeout);
      if (rxData.length < byteCount) {
        return ModbusResponseCode.requestTimeout;
      }
      response.addRxData(fromModbusAscii(rxData));
      return _checksumCheck(response);
    } catch (ex) {
      ModbusAppLogger.severe(
          "Unexpected exception in reading ASCII message PDU", ex);
    }
    return ModbusResponseCode.requestRxFailed;
  }

  ModbusResponseCode _checksumCheck(_ModbusSerialResponse response) {
    var pduChecksum = computeLRC(response.getRxData(includeChecksum: false));
    return pduChecksum == response.checksum.first
        ? ModbusResponseCode.requestSucceed
        : ModbusResponseCode.requestRxWrongChecksum;
  }

  static Uint8List fromModbusAscii(Iterable<int> ascii) {
    String str = String.fromCharCodes(ascii);
    List<int> bytes = [];
    for (int i = 0; i < str.length - 1; i += 2) {
      bytes.add(int.parse(str.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  static List<int> toModbusAscii(Iterable<int> bytes) {
    StringBuffer buf = StringBuffer();
    for (var byte in bytes) {
      buf.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return List<int>.from(buf.toString().toUpperCase().codeUnits,
        growable: true);
  }

  static int computeLRC(Iterable<int> bytes) {
    var nLRC = 0;
    for (var byte in bytes) {
      nLRC = (nLRC + (byte & 0XFF)) & 0XFF;
    }
    nLRC = (nLRC - 1) ^ 0xFF;

    return nLRC & 0XFF;
  }
}
