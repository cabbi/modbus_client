import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  // Create the modbus client.
  var modbusClient = ModbusClientTcp("127.0.0.1", unitId: 1);

  // Write two file records
  var r1 = ModbusFileUint16Record(
      fileNumber: 4,
      recordNumber: 1,
      recordData: Uint16List.fromList([12573, 56312]));
  var r2 = ModbusFileDoubleRecord(
      fileNumber: 3,
      recordNumber: 9,
      recordData: Float64List.fromList([123.5634, 125756782.8492]));
  await modbusClient.send(ModbusFileRecordsWriteRequest([r1, r2]));

  // Read two file records
  r1 = ModbusFileUint16Record.empty(
      fileNumber: 4, recordNumber: 1, recordDataCount: 2);
  r2 = ModbusFileDoubleRecord.empty(
      fileNumber: 3, recordNumber: 9, recordDataCount: 2);
  await modbusClient.send(ModbusFileRecordsReadRequest([r1, r2]));

  // Write multiple records
  var multipleRecords =
      ModbusFileMultipleRecord(fileNumber: 4, recordNumber: 1);
  multipleRecords.addNext(ModbusRecordType.int16, -123);
  multipleRecords.addNext(ModbusRecordType.uint16, 5000);
  multipleRecords.addNext(ModbusRecordType.int32, -1234567890);
  multipleRecords.addNext(ModbusRecordType.uint32, 1234567890);
  multipleRecords.addNext(ModbusRecordType.float, 123.45);
  multipleRecords.addNext(ModbusRecordType.double, 12345.6789);
  await modbusClient.send(multipleRecords.getWriteRequest());

  multipleRecords = ModbusFileMultipleRecord.empty(
      fileNumber: 4, recordNumber: 1, recordDataByteLength: 24);
  await modbusClient.send(multipleRecords.getReadRequest());
  multipleRecords.start();
  print(multipleRecords.getNext(ModbusRecordType.int16));
  print(multipleRecords.getNext(ModbusRecordType.uint16));
  print(multipleRecords.getNext(ModbusRecordType.int32));
  print(multipleRecords.getNext(ModbusRecordType.uint32));
  print(multipleRecords.getNext(ModbusRecordType.float));
  print(multipleRecords.getNext(ModbusRecordType.double));

  // Ending here
  modbusClient.disconnect();
}
