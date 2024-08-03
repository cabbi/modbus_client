library modbus_client_serial_impl;

import 'dart:async';
import 'dart:typed_data';

import 'package:synchronized/synchronized.dart';
import 'package:modbus_client/modbus_client.dart';

part 'modbus_client_serial_rtu.dart';
part 'modbus_client_serial_ascii.dart';
part 'modbus_serial_port.dart';

/// The serial Modbus client class.
abstract class ModbusClientSerial extends ModbusClient {
  ModbusSerialPort serialPort;
  final Lock _lock = Lock();

  ModbusClientSerial(
      {required this.serialPort,
      super.unitId,
      super.connectionMode = ModbusConnectionMode.autoConnectAndKeepConnected,
      super.responseTimeout = const Duration(seconds: 3)});

  /// Returns the serial telegram checksum length
  int get checksumByteCount;

  /// Returns the modbus telegram out of this request's PDU
  Uint8List _getTxTelegram(ModbusRequest request, int unitId);

  /// Read response from device.
  Future<ModbusResponseCode> _readResponseHeader(
      _ModbusSerialResponse response, Duration timeout);

  /// Reads the full pdu response from device.
  ///
  /// NOTE: response header should be read already!
  Future<ModbusResponseCode> _readResponsePdu(
      _ModbusSerialResponse response, Duration timeout);

  /// Returns true if connection is established
  @override
  bool get isConnected => serialPort.isOpen;

  /// Close the connection
  @override
  Future<void> disconnect() async {
    ModbusAppLogger.fine("Closing serial port ${serialPort.name}...");
    if (serialPort.isOpen) {
      serialPort.close();
    }
  }

  /// Sends a modbus request
  @override
  Future<ModbusResponseCode> send(ModbusRequest request) async {
    Duration resTimeout = getResponseTimeout(request);
    var res = await _lock.synchronized(() async {
      // Connect if needed
      try {
        if (connectionMode != ModbusConnectionMode.doNotConnect) {
          await connect();
        }
        if (!isConnected) {
          return ModbusResponseCode.connectionFailed;
        }
      } catch (ex) {
        ModbusAppLogger.severe(
            "Unexpected exception in connecting to ${serialPort.name}", ex);
        return ModbusResponseCode.connectionFailed;
      }

      // Reset this request in case it was already used before
      request.reset();

      // Start a stopwatch for the request timeout
      final reqStopwatch = Stopwatch()..start();

      // Send the request data
      var unitId = getUnitId(request);
      try {
        // Flush both tx & rx buffers (discard old pending requests & responses)
        await serialPort.flush();

        // Sent the serial telegram
        var reqTxData = _getTxTelegram(request, unitId);
        int txDataCount =
            await serialPort.write(reqTxData, timeout: resTimeout);
        if (txDataCount < reqTxData.length) {
          request.setResponseCode(ModbusResponseCode.requestTimeout);
          return request.responseCode;
        }
      } catch (ex) {
        ModbusAppLogger.severe(
            "Unexpected exception in sending data to ${serialPort.name}", ex);
        request.setResponseCode(ModbusResponseCode.requestTxFailed);
        return request.responseCode;
      }

      // Lets check the response header (i.e.read first bytes only to check if
      // response is normal or has error)
      var response = _ModbusSerialResponse(
          request: request,
          unitId: unitId,
          checksumByteCount: checksumByteCount);
      Duration remainingTime = resTimeout - reqStopwatch.elapsed;
      var responseCode = remainingTime.isNegative
          ? ModbusResponseCode.requestTimeout
          : await _readResponseHeader(response, remainingTime);
      if (responseCode != ModbusResponseCode.requestSucceed) {
        request.setResponseCode(responseCode);
        return request.responseCode;
      }

      // Lets wait the rest of the PDU response
      remainingTime = resTimeout - reqStopwatch.elapsed;
      responseCode = remainingTime.isNegative
          ? ModbusResponseCode.requestTimeout
          : await _readResponsePdu(response, remainingTime);
      if (responseCode != ModbusResponseCode.requestSucceed) {
        request.setResponseCode(responseCode);
        return request.responseCode;
      }

      // Set the request response based on received PDU
      request.setFromPduResponse(response.pdu);

      return request.responseCode;
    });
    // Need to disconnect?
    if (connectionMode == ModbusConnectionMode.autoConnectAndDisconnect) {
      await disconnect();
    }
    return res;
  }

  /// Connect the port if not already done or disconnected
  @override
  Future<bool> connect() async {
    if (isConnected) {
      return true;
    }
    ModbusAppLogger.fine("Opening serial port ${serialPort.name}...");
    return serialPort.open();
  }
}

/// The modbus serial response is composed from:
/// BYTE - UnitId
/// BYTE - Function code
/// BYTE - Modbus exception code if Function code & 0x80 (i.e. bit 8 == 1)
class _ModbusSerialResponse {
  final ModbusRequest request;
  final int unitId;
  final int checksumByteCount;

  _ModbusSerialResponse(
      {required this.request,
      required this.unitId,
      required this.checksumByteCount});

  List<int>? _rxData;
  void setRxData(List<int> rxData) =>
      _rxData = List<int>.from(rxData, growable: true);
  void addRxData(List<int> rxData) => _rxData!.addAll(rxData);

  ModbusResponseCode get headerResponseCode {
    if (_rxData == null || _rxData!.length < 3) {
      return ModbusResponseCode.requestRxFailed;
    }
    if (_rxData![0] != unitId) {
      return ModbusResponseCode.requestRxWrongUnitId;
    }
    if ((_rxData![1] & 0x80) != 0) {
      return ModbusResponseCode.fromCode(_rxData![2]);
    }
    if (_rxData![1] != request.functionCode.code) {
      return ModbusResponseCode.requestRxWrongFunctionCode;
    }
    return ModbusResponseCode.requestSucceed;
  }

  Iterable<int> getRxData({required bool includeChecksum}) => _rxData!
      .getRange(0, _rxData!.length - (includeChecksum ? 0 : checksumByteCount));

  Uint8List get pdu => // serial telegram has: <unit id> + <pdu> + <checksum>
      _rxData == null
          ? Uint8List(0)
          : Uint8List.fromList(
              _rxData!.sublist(1, _rxData!.length - checksumByteCount));

  Uint8List get checksum => _rxData == null
      ? Uint8List(0)
      : Uint8List.fromList(
          _rxData!.sublist(_rxData!.length - checksumByteCount));
}
