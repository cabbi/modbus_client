import 'dart:typed_data';
import 'package:modbus_client/modbus_client.dart';

int hi(int value) => (value & 0xFF00) >> 8;
int lo(int value) => (value & 0x00FF);

/// A file record element
abstract class ModbusFileRecord {
  final int fileNumber;
  final int recordNumber;

  List<num> get recordData;
  ByteBuffer get recordBuffer;
  int get recordLength => recordBuffer.lengthInBytes ~/ 2;

  ModbusFileRecord({required this.fileNumber, required this.recordNumber});
}

/// Record type used in multiple file records
enum ModbusRecordType {
  int16(1),
  uint16(1),
  int32(2),
  uint32(2),
  float(2),
  double(4);

  const ModbusRecordType(this.recordLength);
  final int recordLength;
}

/// Modbus multiple file record types
class ModbusFileMultipleRecord extends ModbusFileRecord {
  late Uint16List _recordData;

  @override
  Uint16List get recordData => _recordData;

  @override
  ByteBuffer get recordBuffer => recordData.buffer;

  ModbusFileMultipleRecord(
      {required super.fileNumber,
      required super.recordNumber,
      Uint16List? recordData})
      : _recordData = recordData ?? Uint16List(0);

  factory ModbusFileMultipleRecord.empty(
          {required int fileNumber,
          required int recordNumber,
          required int recordDataByteLength}) =>
      ModbusFileMultipleRecord(
          fileNumber: fileNumber,
          recordNumber: recordNumber,
          recordData: Uint16List(recordDataByteLength ~/ 2));

  factory ModbusFileMultipleRecord.fromTypes(
      {required int fileNumber,
      required int recordNumber,
      required Iterable<ModbusRecordType> types}) {
    int recordsLength = 0;
    for (var type in types) {
      recordsLength += type.recordLength;
    }
    return ModbusFileMultipleRecord(
        fileNumber: fileNumber,
        recordNumber: recordNumber,
        recordData: Uint16List(recordsLength));
  }

  int _currentBytePos = 0;
  void start() => _currentBytePos = 0;

  bool get endOfRecord => _endOfRecord(_currentBytePos);

  bool _endOfRecord(int bytePos) => bytePos > 2 * recordData.length;

  num? getNext(ModbusRecordType type) {
    if (_endOfRecord(_currentBytePos + (type.recordLength * 2))) {
      return null;
    }
    var dataView = ByteData.view(recordBuffer);
    var pos = _currentBytePos;
    _currentBytePos += type.recordLength * 2;
    switch (type) {
      case ModbusRecordType.int16:
        return dataView.getInt16(pos);
      case ModbusRecordType.uint16:
        return dataView.getUint16(pos);
      case ModbusRecordType.int32:
        return dataView.getInt32(pos);
      case ModbusRecordType.uint32:
        return dataView.getUint32(pos);
      case ModbusRecordType.float:
        return dataView.getFloat32(pos);
      case ModbusRecordType.double:
        return dataView.getFloat64(pos);
    }
  }

  void setNext(ModbusRecordType type, num value) {
    if (_endOfRecord(_currentBytePos + 2 * type.recordLength)) {
      throw ModbusException(
          context: "ModbusFileMultipleRecord.setNext",
          msg: "Setting value out of the record length");
    }
    var dataView = ByteData.view(recordBuffer);
    var pos = _currentBytePos;
    _currentBytePos += 2 * type.recordLength;
    switch (type) {
      case ModbusRecordType.int16:
        dataView.setInt16(pos, value as int);
        break;
      case ModbusRecordType.uint16:
        dataView.setUint16(pos, value as int);
        break;
      case ModbusRecordType.int32:
        dataView.setInt32(pos, value as int);
        break;
      case ModbusRecordType.uint32:
        dataView.setUint32(pos, value as int);
        break;
      case ModbusRecordType.float:
        dataView.setFloat32(pos, value as double);
        break;
      case ModbusRecordType.double:
        dataView.setFloat64(pos, value as double);
        break;
    }
  }

  void addNext(ModbusRecordType type, num value) {
    _currentBytePos = _recordData.length * 2;
    var currentData = _recordData;
    _recordData = Uint16List(currentData.length + type.recordLength);
    _recordData.setAll(0, currentData);
    setNext(type, value);
  }

  ModbusFileRecordsReadRequest getReadRequest(
          {int? unitId, Duration? responseTimeout}) =>
      ModbusFileRecordsReadRequest([this],
          unitId: unitId, responseTimeout: responseTimeout);

  ModbusFileRecordsWriteRequest getWriteRequest(
          {int? unitId, Duration? responseTimeout}) =>
      ModbusFileRecordsWriteRequest([this],
          unitId: unitId, responseTimeout: responseTimeout);
}

/// A UInt6 file record type
class ModbusFileUint16Record extends ModbusFileRecord {
  @override
  final Uint16List recordData;
  @override
  ByteBuffer get recordBuffer => recordData.buffer;

  ModbusFileUint16Record(
      {required super.fileNumber,
      required super.recordNumber,
      required this.recordData});

  factory ModbusFileUint16Record.empty(
          {required int fileNumber,
          required int recordNumber,
          required int recordDataCount}) =>
      ModbusFileUint16Record(
          fileNumber: fileNumber,
          recordNumber: recordNumber,
          recordData: Uint16List(recordDataCount));
}

/// An Int6 file record type
class ModbusFileInt16Record extends ModbusFileRecord {
  @override
  final Int16List recordData;
  @override
  ByteBuffer get recordBuffer => recordData.buffer;

  ModbusFileInt16Record(
      {required super.fileNumber,
      required super.recordNumber,
      required this.recordData});

  factory ModbusFileInt16Record.empty(
          {required int fileNumber,
          required int recordNumber,
          required int recordDataCount}) =>
      ModbusFileInt16Record(
          fileNumber: fileNumber,
          recordNumber: recordNumber,
          recordData: Int16List(recordDataCount));
}

/// A UIn32 file record type
class ModbusFileUint32Record extends ModbusFileRecord {
  @override
  final Uint32List recordData;
  @override
  ByteBuffer get recordBuffer => recordData.buffer;

  ModbusFileUint32Record(
      {required super.fileNumber,
      required super.recordNumber,
      required this.recordData});

  factory ModbusFileUint32Record.empty(
          {required int fileNumber,
          required int recordNumber,
          required int recordDataCount}) =>
      ModbusFileUint32Record(
          fileNumber: fileNumber,
          recordNumber: recordNumber,
          recordData: Uint32List(recordDataCount));
}

/// An Int32 file record type
class ModbusFileInt32Record extends ModbusFileRecord {
  @override
  final Int32List recordData;
  @override
  ByteBuffer get recordBuffer => recordData.buffer;

  ModbusFileInt32Record(
      {required super.fileNumber,
      required super.recordNumber,
      required this.recordData});

  factory ModbusFileInt32Record.empty(
          {required int fileNumber,
          required int recordNumber,
          required int recordDataCount}) =>
      ModbusFileInt32Record(
          fileNumber: fileNumber,
          recordNumber: recordNumber,
          recordData: Int32List(recordDataCount));
}

/// A Float file record type
class ModbusFileFloatRecord extends ModbusFileRecord {
  @override
  final Float32List recordData;
  @override
  ByteBuffer get recordBuffer => recordData.buffer;

  ModbusFileFloatRecord(
      {required super.fileNumber,
      required super.recordNumber,
      required this.recordData});

  factory ModbusFileFloatRecord.empty(
          {required int fileNumber,
          required int recordNumber,
          required int recordDataCount}) =>
      ModbusFileFloatRecord(
          fileNumber: fileNumber,
          recordNumber: recordNumber,
          recordData: Float32List(recordDataCount));
}

/// A Double file record type
class ModbusFileDoubleRecord extends ModbusFileRecord {
  @override
  final Float64List recordData;
  @override
  ByteBuffer get recordBuffer => recordData.buffer;

  ModbusFileDoubleRecord(
      {required super.fileNumber,
      required super.recordNumber,
      required this.recordData});

  factory ModbusFileDoubleRecord.empty(
          {required int fileNumber,
          required int recordNumber,
          required int recordDataCount}) =>
      ModbusFileDoubleRecord(
          fileNumber: fileNumber,
          recordNumber: recordNumber,
          recordData: Float64List(recordDataCount));
}

/// The read table records request.
/// Max length of records in bytes should not exceed 72 bytes.
class ModbusFileRecordsReadRequest extends ModbusRequest {
  final List<ModbusFileRecord> fileRecords;

  static FunctionCode recordsReadFunctionCode =
      ModbusFunctionCode(0x14, FunctionType.custom);
  @override
  final FunctionCode functionCode = recordsReadFunctionCode;
  @override
  Uint8List get protocolDataUnit => _getProtocolDataUnit(fileRecords);

  @override
  final int responsePduLength;

  ModbusFileRecordsReadRequest(this.fileRecords,
      {super.unitId, super.responseTimeout})
      : responsePduLength = _getResponsePduLength(fileRecords),
        super();

  static int _getResponsePduLength(List<ModbusFileRecord> fileRecords) {
    int len = 2;
    for (var record in fileRecords) {
      len += 2 + 2 * record.recordLength;
    }
    return len;
  }

  static Uint8List _getProtocolDataUnit(List<ModbusFileRecord> fileRecords) {
    // PDU length checks
    if (fileRecords.isEmpty) {
      throw ModbusException(
          context: "ModbusFileRecordsReadRequest",
          msg: "File records list should not be empty!");
    }
    if (_getResponsePduLength(fileRecords) > 255) {
      throw ModbusException(
          context: "ModbusFileRecordsReadRequest",
          msg: "File records list exceeds max length!");
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
    protocolDataUnit[i++] = recordsReadFunctionCode.code;
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
  ModbusResponseCode internalSetFromPduResponse(Uint8List pdu) {
    // Response
    // --------
    // Function code 1 Byte 0x14
    // Resp. data Length 1 Byte 0x07 to 0xF5
    // Sub-Req. x, File Resp. length 1 Byte 0x07 to 0xF5
    // Sub-Req. x, Reference Type 1 Byte 6
    // Sub-Req. x, Record Data N x 2 Bytes
    // Sub-Req. x+1, ...
    if (pdu.length != responsePduLength || pdu[0] != functionCode.code) {
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
      var dataView = ByteData.view(record.recordBuffer);
      for (int b = 0; b < record.recordLength * 2; b++) {
        dataView.setUint8(b, pdu[i++]);
      }
    }
    return ModbusResponseCode.requestSucceed;
  }
}

/// The write table records request.
/// Max length of records in bytes should not exceed 72 bytes.
class ModbusFileRecordsWriteRequest extends ModbusRequest {
  final List<ModbusFileRecord> fileRecords;

  static FunctionCode recordsWriteFunctionCode =
      ModbusFunctionCode(0x15, FunctionType.custom);
  @override
  final FunctionCode functionCode = recordsWriteFunctionCode;
  @override
  Uint8List get protocolDataUnit => _getProtocolDataUnit(fileRecords);

  @override
  final int responsePduLength;

  ModbusFileRecordsWriteRequest(this.fileRecords,
      {super.unitId, super.responseTimeout})
      : responsePduLength = _getResponsePduLength(fileRecords),
        super();

  static int _getResponsePduLength(List<ModbusFileRecord> fileRecords) {
    int len = 2;
    for (var record in fileRecords) {
      len += 7 + 2 * record.recordLength;
    }
    return len;
  }

  static Uint8List _getProtocolDataUnit(List<ModbusFileRecord> fileRecords) {
    // PDU length checks
    if (fileRecords.isEmpty) {
      throw ModbusException(
          context: "ModbusFileRecordsWriteRequest",
          msg: "File records list should not be empty!");
    }
    if (_getResponsePduLength(fileRecords) > 255) {
      throw ModbusException(
          context: "ModbusFileRecordsWriteRequest",
          msg: "File records list exceeds max length!");
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
    protocolDataUnit[i++] = recordsWriteFunctionCode.code;
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
      var dataView = ByteData.view(record.recordBuffer);
      for (int b = 0; b < record.recordLength * 2; b++) {
        protocolDataUnit[i++] = dataView.getUint8(b);
      }
    }
    return protocolDataUnit;
  }

  @override
  ModbusResponseCode internalSetFromPduResponse(Uint8List pdu) {
    // Response is echo of request
    return ModbusResponseCode.requestSucceed;
  }
}
