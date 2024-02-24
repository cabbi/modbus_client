import 'dart:typed_data';
import 'package:modbus_client/modbus_client.dart';

int hi(int value) => (value & 0xFF00) >> 8;
int lo(int value) => (value & 0x00FF);

/// A file record element
class ModbusFileRecord {
  final int fileNumber;
  final int recordNumber;
  Uint8List recordBytes;

  int get recordLength => recordBytes.length;

  ModbusFileRecord(
      {required this.fileNumber,
      required this.recordNumber,
      required this.recordBytes});

  factory ModbusFileRecord.empty(
          {required int fileNumber,
          required int recordNumber,
          required int recordLength}) =>
      ModbusFileRecord(
          fileNumber: fileNumber,
          recordNumber: recordNumber,
          recordBytes: Uint8List(recordLength));
}

/// The read table records request.
/// Max length of records is 35.
class ModbusFileRecordsReadRequest extends ModbusRequest {
  final List<ModbusFileRecord> fileRecords;

  @override
  final int responsePduLength;

  ModbusFileRecordsReadRequest(this.fileRecords,
      {super.unitId, super.responseTimeout})
      : responsePduLength = _getResponsePduLength(fileRecords),
        super(_getProtocolDataUnit(fileRecords));

  static int _getResponsePduLength(List<ModbusFileRecord> fileRecords) {
    int len = 2;
    for (var record in fileRecords) {
      len += 2 + 2 * record.recordLength;
    }
    return len;
  }

  static Uint8List _getProtocolDataUnit(List<ModbusFileRecord> fileRecords) {
    if (fileRecords.isEmpty || fileRecords.length > 35) {
      throw ModbusException(
          context: "ModbusFileRecordsRequest",
          msg: "Invalid file records list, length must be between 1 and 35!");
    }
    // Request
    // -------
    // Function code 1 Byte 0x14
    // Byte Count 1 Byte 0x07 to 0xF5 bytes
    // Sub-Req. x, Reference Type 1 Byte 06
    // Sub-Req. x, File Number 2 Bytes 0x0001 to 0xFFFF
    // Sub-Req. x, Record Number 2 Bytes 0x0000 to 0x270F
    // Sub-Req. x, Record Length 2 Bytes N
    // Sub-Req. x+1, ...
    var protocolDataUnit = Uint8List(2 + 7 * fileRecords.length);
    int i = 0;
    protocolDataUnit[i++] = 0x14;
    protocolDataUnit[i++] = 7 * fileRecords.length;
    for (var record in fileRecords) {
      protocolDataUnit[i++] = 6; // Reference type
      protocolDataUnit[i++] = hi(record.fileNumber);
      protocolDataUnit[i++] = lo(record.fileNumber);
      protocolDataUnit[i++] = hi(record.recordNumber);
      protocolDataUnit[i++] = lo(record.recordNumber);
      protocolDataUnit[i++] = hi(record.recordLength);
      protocolDataUnit[i++] = lo(record.recordLength);
    }
    return protocolDataUnit;
  }

  @override
  ModbusResponseCode internalSetFromPduResponse(
      int functionCode, Uint8List pdu) {
    // Response
    // --------
    // Function code 1 Byte 0x14
    // Resp. data Length 1 Byte 0x07 to 0xF5
    // Sub-Req. x, File Resp. length 1 Byte 0x07 to 0xF5
    // Sub-Req. x, Reference Type 1 Byte 6
    // Sub-Req. x, Record Data N x 2 Bytes
    // Sub-Req. x+1, ...
    if (pdu.length != responsePduLength || pdu[0] != functionCode) {
      return ModbusResponseCode.requestRxFailed;
    }
    int i = 2;
    for (var record in fileRecords) {
      i++; // Byte count
      // Reference type
      if (pdu[i++] != 6) {
        return ModbusResponseCode.requestRxFailed;
      }
      // Record data
      for (int b = 0; b < record.recordLength; b++) {
        record.recordBytes[b] = (pdu[i++] << 8) + pdu[i++];
      }
    }
    return ModbusResponseCode.requestSucceed;
  }
}

/// The write table records request.
/// Max length of records is 35.
class ModbusFileRecordsWriteRequest extends ModbusRequest {
  final List<ModbusFileRecord> fileRecords;

  @override
  final int responsePduLength;

  ModbusFileRecordsWriteRequest(this.fileRecords,
      {super.unitId, super.responseTimeout})
      : responsePduLength = _getResponsePduLength(fileRecords),
        super(_getProtocolDataUnit(fileRecords));

  static int _getResponsePduLength(List<ModbusFileRecord> fileRecords) {
    int len = 2;
    for (var record in fileRecords) {
      len += 7 + 2 * record.recordLength;
    }
    return len;
  }

  static Uint8List _getProtocolDataUnit(List<ModbusFileRecord> fileRecords) {
    if (fileRecords.isEmpty || fileRecords.length > 35) {
      throw ModbusException(
          context: "ModbusFileRecordsRequest",
          msg: "Invalid file records list, length must be between 1 and 35!");
    }
    // Request
    // -------
    // Function code 1 Byte 0x15
    // Request data length 1 Byte 0x09 to 0xFB
    // Sub-Req. x, Reference Type 1 Byte 06
    // Sub-Req. x, File Number 2 Bytes 0x0001 to 0xFFFF
    // Sub-Req. x, Record Number 2 Bytes 0x0000 to 0x270F
    // Sub-Req. x, Record length 2 Bytes N
    // Sub-Req. x, Record data N x 2 Bytes
    // Sub-Req. x+1, ...
    int reqDataLength = _getResponsePduLength(fileRecords) - 2;
    var protocolDataUnit = Uint8List(2 + reqDataLength);
    int i = 0;
    protocolDataUnit[i++] = 0x15;
    protocolDataUnit[i++] = reqDataLength;
    for (var record in fileRecords) {
      protocolDataUnit[i++] = 6; // Reference type
      protocolDataUnit[i++] = hi(record.fileNumber);
      protocolDataUnit[i++] = lo(record.fileNumber);
      protocolDataUnit[i++] = hi(record.recordNumber);
      protocolDataUnit[i++] = lo(record.recordNumber);
      protocolDataUnit[i++] = hi(record.recordLength);
      protocolDataUnit[i++] = lo(record.recordLength);
      // Record data
      for (int b = 0; b < record.recordLength; b++) {
        var data = record.recordBytes[b];
        protocolDataUnit[i++] = hi(data);
        protocolDataUnit[i++] = lo(data);
      }
    }
    return protocolDataUnit;
  }

  @override
  ModbusResponseCode internalSetFromPduResponse(
      int functionCode, Uint8List pdu) {
    // Response is echo of request
    return ModbusResponseCode.requestSucceed;
  }
}
