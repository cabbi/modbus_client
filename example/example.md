## Read request

``` dart
import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  // Create a modbus int16 register element
  var batteryTemperature = ModbusInt16Register(
      name: "BatteryTemperature",
      type: ModbusElementType.inputRegister,
      address: 22,
      uom: "°C",
      multiplier: 0.1,
      onUpdate: (self) => print(self));

  // Discover the Modbus server
  var serverIp = await ModbusClientTcp.discover("192.168.0.0");
  if (serverIp == null) {
    ModbusAppLogger.shout("No modbus server found!");
    return;
  }
  
  // Create the modbus client.
  var modbusClient = ModbusClientTcp(serverIp, unitId: 1);

  // Send a read request from the element
  await modbusClient.send(batteryTemperature.getReadRequest());

  // Ending here
  modbusClient.disconnect();
}
```

## Group read request

``` dart
import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

enum BatteryStatus implements ModbusIntEnum {
  offline(0),
  standby(1),
  running(2),
  fault(3),
  sleepMode(4);

  const BatteryStatus(this.intValue);

  @override
  final int intValue;
}

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  // Create a modbus elements group
  var batteryRegs = ModbusElementsGroup([
    ModbusEnumRegister(
        name: "BatteryStatus",
        type: ModbusElementType.holdingRegister,
        address: 37000,
        enumValues: BatteryStatus.values),
    ModbusInt32Register(
        name: "BatteryChargingPower",
        type: ModbusElementType.holdingRegister,
        address: 37001,
        uom: "W",
        description: "> 0: charging - < 0: discharging"),
    ModbusUint16Register(
        name: "BatteryCharge",
        type: ModbusElementType.holdingRegister,
        address: 37004,
        uom: "%",
        multiplier: 0.1),
    ModbusUint16Register(
        name: "BatteryTemperature",
        type: ModbusElementType.holdingRegister,
        address: 37022,
        uom: "°C",
        multiplier: 0.1),
  ]);

  // Discover the Modbus server
  var serverIp = await ModbusClientTcp.discover("192.168.0.0");
  if (serverIp == null) {
    ModbusAppLogger.shout("No modbus server found!");
    return;
  }
  
  // Create the modbus client.
  var modbusClient = ModbusClientTcp(serverIp, unitId: 1);

  // Send a read request from the group
  await modbusClient.send(batteryRegs.getReadRequest());
  print(batteryRegs[0]);
  print(batteryRegs[1]);
  print(batteryRegs[2]);
  print(batteryRegs[3]);

  // Ending here
  modbusClient.disconnect();
}
```

## Write request

``` dart
import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

enum BatteryStatus implements ModbusIntEnum {
  offline(0),
  standby(1),
  running(2),
  fault(3),
  sleepMode(4);

  const BatteryStatus(this.intValue);

  @override
  final int intValue;

  @override
  String toString() {
    return name;
  }
}

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  var batteryStatus = ModbusEnumRegister(
      name: "BatteryStatus",
      address: 11,
      type: ModbusElementType.holdingRegister,
      enumValues: BatteryStatus.values,
      onUpdate: (self) => print(self));

  // Discover the Modbus server
  var serverIp = await ModbusClientTcp.discover("192.168.0.0");
  if (serverIp == null) {
    ModbusAppLogger.shout("No modbus server found!");
    return;
  }
  
  // Create the modbus client.
  var modbusClient = ModbusClientTcp(serverIp, unitId: 1);

  var req = batteryStatus.getWriteRequest(BatteryStatus.running);
  var res = await modbusClient.send(req);
  print(res.name);

  modbusClient.disconnect();
}
```

## Endianness example

```dart
import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  // Discover the Modbus server
  var serverIp = await ModbusClientTcp.discover("192.168.0.0");
  if (serverIp == null) {
    ModbusAppLogger.shout("No modbus server found!");
    return;
  }

  // Create the modbus client.
  var modbusClient = ModbusClientTcp(serverIp, unitId: 1);

  var int32Reg = ModbusInt32Register(
      name: "int32", address: 14, type: ModbusElementType.holdingRegister);

  var req =
      int32Reg.getWriteRequest(123456789, endianness: ModbusEndianness.ABCD);
  await modbusClient.send(req);
  print(int32Reg.value);

  int32Reg.address = 24;
  req = int32Reg.getWriteRequest(123456789, endianness: ModbusEndianness.DCBA);
  await modbusClient.send(req);
  print(int32Reg.value);

  int32Reg.address = 34;
  req = int32Reg.getWriteRequest(123456789, endianness: ModbusEndianness.BADC);
  await modbusClient.send(req);
  print(int32Reg.value);

  int32Reg.address = 44;
  req = int32Reg.getWriteRequest(123456789, endianness: ModbusEndianness.CDAB);
  await modbusClient.send(req);
  print(int32Reg.value);

  int32Reg.address = 14;
  var readReq = int32Reg.getReadRequest(endianness: ModbusEndianness.ABCD);
  await modbusClient.send(readReq);
  print(int32Reg.value);

  int32Reg.address = 24;
  readReq = int32Reg.getReadRequest(endianness: ModbusEndianness.DCBA);
  await modbusClient.send(readReq);
  print(int32Reg.value);

  int32Reg.address = 34;
  readReq = int32Reg.getReadRequest(endianness: ModbusEndianness.BADC);
  await modbusClient.send(readReq);
  print(int32Reg.value);

  int32Reg.address = 44;
  readReq = int32Reg.getReadRequest(endianness: ModbusEndianness.CDAB);
  await modbusClient.send(readReq);
  print(int32Reg.value);

  modbusClient.disconnect();
}
```

>## Bytes array example

```dart
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  var bytesRegister = ModbusBytesRegister(
      name: "BytesArray",
      address: 4,
      byteCount: 10,
      onUpdate: (self) => print(self));

  // Create the modbus client.
  var modbusClient = ModbusClientTcp("127.0.0.1", unitId: 1);

  var req1 = bytesRegister.getWriteRequest(Uint8List.fromList(
      [0x01, 0x02, 0x03, 0x04, 0x05, 0x66, 0x07, 0x08, 0x09, 0x0A]));
  var res = await modbusClient.send(req1);
  print(res);

  var req2 = bytesRegister.getReadRequest();
  res = await modbusClient.send(req2);
  print(bytesRegister.value);

  modbusClient.disconnect();
}

```

## File records write and read example

```dart
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

```

## Huawei SUN2000 inverter registers

```dart
import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

enum BatteryStatus implements ModbusIntEnum {
  offline(0),
  standby(1),
  running(2),
  fault(3),
  sleepMode(4);

  const BatteryStatus(this.intValue);

  @override
  final int intValue;
}

enum MeterStatus implements ModbusIntEnum {
  offline(0),
  normal(1);

  const MeterStatus(this.intValue);

  @override
  final int intValue;
}

void main() async {
  ModbusAppLogger(Level.INFO);

  // Discover the Modbus server
  var serverIp = await ModbusClientTcp.discover("192.168.0.0");
  if (serverIp == null) {
    ModbusAppLogger.shout("No modbus server found!");
    return;
  }
  
  // Create the modbus client.
  var client = ModbusClientTcp(serverIp,
      serverPort: 502,
      unitId: 1,
      responseTimeout: Duration(seconds: 3),
      connectionTimeout: Duration(seconds: 1),
      delayAfterConnect: Duration(seconds: 1));

  var batteryRegs = ModbusElementsGroup([
    ModbusEnumRegister(
        name: "BatteryStatus",
        type: ModbusElementType.holdingRegister,
        address: 37000,
        enumValues: BatteryStatus.values),
    ModbusInt32Register(
        name: "BatteryChargingPower",
        type: ModbusElementType.holdingRegister,
        address: 37001,
        uom: "W",
        description: "> 0: charging - < 0: discharging"),
    ModbusUint16Register(
        name: "BatteryTemperature",
        type: ModbusElementType.holdingRegister,
        address: 37022,
        uom: "°C",
        multiplier: 0.1),
    ModbusUint16Register(
        name: "BatteryCharge",
        type: ModbusElementType.holdingRegister,
        address: 37004,
        uom: "%",
        multiplier: 0.1),
  ]);

  var meterRegs = ModbusElementsGroup([
    ModbusEnumRegister(
        name: "MeterStatus",
        type: ModbusElementType.holdingRegister,
        address: 37100,
        enumValues: MeterStatus.values),
    ModbusInt32Register(
        name: "MeterGridVoltagePhaseA",
        type: ModbusElementType.holdingRegister,
        address: 37101,
        uom: "V",
        multiplier: 0.1),
    ModbusInt32Register(
        name: "MeterGridVoltagePhaseB",
        type: ModbusElementType.holdingRegister,
        address: 37103,
        uom: "V",
        multiplier: 0.1),
    ModbusInt32Register(
        name: "MeterGridVoltagePhaseC",
        type: ModbusElementType.holdingRegister,
        address: 37105,
        uom: "V",
        multiplier: 0.1),
    ModbusInt32Register(
        name: "MeterGridCurrentPhaseA",
        type: ModbusElementType.holdingRegister,
        address: 37107,
        uom: "A",
        multiplier: 0.01),
    ModbusInt32Register(
        name: "MeterGridCurrentPhaseB",
        type: ModbusElementType.holdingRegister,
        address: 37109,
        uom: "A",
        multiplier: 0.01),
    ModbusInt32Register(
        name: "MeterGridCurrentPhaseC",
        type: ModbusElementType.holdingRegister,
        address: 37111,
        uom: "A",
        multiplier: 0.01),
    ModbusInt32Register(
        name: "MeterActivePowerTotal",
        type: ModbusElementType.holdingRegister,
        address: 37113,
        uom: "W",
        description:
            ">0 feed-in to the power grid - <0 supply from the power grid"),
    ModbusInt32Register(
        name: "MeterActivePowerPhaseA",
        type: ModbusElementType.holdingRegister,
        address: 37132,
        uom: "W"),
    ModbusInt32Register(
        name: "MeterActivePowerPhaseB",
        type: ModbusElementType.holdingRegister,
        address: 37134,
        uom: "W"),
    ModbusInt32Register(
        name: "MeterActivePowerPhaseC",
        type: ModbusElementType.holdingRegister,
        address: 37136,
        uom: "W"),
  ]);

  var inverterRegs1 = ModbusElementsGroup([
    ModbusBitMaskRegister(
        name: "State 1",
        type: ModbusElementType.holdingRegister,
        address: 32000,
        bitMasks: [
          ModbusBitMask(0, "standby"),
          ModbusBitMask(1, "grid connected"),
          ModbusBitMask(2, "grid connected normally"),
          ModbusBitMask(
              3, "grid connection with derating due to power rationing"),
          ModbusBitMask(4,
              "grid connection with derating due to internal causes of the solar inverter"),
          ModbusBitMask(5, "normal stop"),
          ModbusBitMask(6, "stop due to faults"),
          ModbusBitMask(7, "stop due to power rationing"),
          ModbusBitMask(8, "shutdown"),
          ModbusBitMask(9, "spot check"),
        ]),
    ModbusBitMaskRegister(
        name: "State 2",
        type: ModbusElementType.holdingRegister,
        address: 32002,
        bitMasks: [
          ModbusBitMask(0, "unlocked", "locked"),
          ModbusBitMask(1, "connected", "disconnected"),
          ModbusBitMask(
              2, "DSP data collection active", "DSP data collection inactive"),
        ]),
    ModbusBitMaskRegister(
        name: "State 3",
        type: ModbusElementType.holdingRegister,
        address: 32003,
        bitMasks: [
          ModbusBitMask(0, "off-grid", "on-grid"),
          ModbusBitMask(
              1, "off-grid switch enabled", "off-grid switch disabled"),
        ]),
    ModbusBitMaskRegister(
        name: "Alarm 1",
        type: ModbusElementType.holdingRegister,
        address: 32008,
        bitMasks: [
          ModbusBitMask(0, "High String Input Voltage [2001 Major]"),
          ModbusBitMask(1, "DC Arc Fault [2002 Major]"),
          ModbusBitMask(2, "String Reverse Connection [2011 Major]"),
          ModbusBitMask(3, "String Current Backfeed [2012 Warning]"),
          ModbusBitMask(4, "Abnormal String Power [2013 Warning]"),
          ModbusBitMask(5, "AFCI Self-Check Fail. [2021 Major]"),
          ModbusBitMask(6, "Phase Wire Short-Circuited to PE [2031 Major]"),
          ModbusBitMask(7, "Grid Loss [2032 Major]"),
          ModbusBitMask(8, "Grid Undervoltage [2033 Major]"),
          ModbusBitMask(9, "Grid Overvoltage [2034 Major]"),
          ModbusBitMask(10, "Grid Volt. Imbalance [2035 Major]"),
          ModbusBitMask(11, "Grid Overfrequency [2036 Major]"),
          ModbusBitMask(12, "Grid Underfrequency [2037 Major]"),
          ModbusBitMask(13, "Unstable Grid Frequency [2038 Major]"),
          ModbusBitMask(14, "Output Overcurrent [2039 Major]"),
          ModbusBitMask(15, "Output DC Component Overhigh [2040 Major]"),
        ]),
    ModbusBitMaskRegister(
        name: "Alarm 2",
        type: ModbusElementType.holdingRegister,
        address: 32009,
        bitMasks: [
          ModbusBitMask(0, "Abnormal Residual Current 2051 Major"),
          ModbusBitMask(1, "Abnormal Grounding 2061 Major"),
          ModbusBitMask(2, "Low Insulation Resistance 2062 Major"),
          ModbusBitMask(3, "Overtemperature 2063 Minor"),
          ModbusBitMask(4, "Device Fault 2064 Major"),
          ModbusBitMask(5, "Upgrade Failed or Version Mismatch 2065 Minor"),
          ModbusBitMask(6, "License Expired 2066 Warning"),
          ModbusBitMask(7, "Faulty Monitoring Unit 61440 Minor"),
          ModbusBitMask(8, "Faulty Power Collector[2] 2067 Major"),
          ModbusBitMask(9, "Battery abnormal 2068 Minor"),
          ModbusBitMask(10, "Active Islanding 2070 Major"),
          ModbusBitMask(11, "Passive Islanding 2071 Major"),
          ModbusBitMask(12, "Transient AC Overvoltage 2072 Major"),
          ModbusBitMask(13, "Peripheral port short circuit[3] 2075 Warning"),
          ModbusBitMask(14, "Churn output overload[4] 2077 Major"),
          ModbusBitMask(15, "Abnormal PV module configuration 2080 Major"),
        ]),
    ModbusBitMaskRegister(
        name: "Alarm 3",
        type: ModbusElementType.holdingRegister,
        address: 32010,
        bitMasks: [
          ModbusBitMask(0, "Optimizer fault[5] 2081 Warning"),
          ModbusBitMask(1, "Built-in PID operation abnormal[6] 2085 Minor"),
          ModbusBitMask(2, "High input string voltage to ground. 2014 Major"),
          ModbusBitMask(3, "External Fan Abnormal 2086 Major"),
          ModbusBitMask(4, "Battery Reverse Connection[7] 2069 Major"),
          ModbusBitMask(5, "On-grid/Off-grid controller"),
          ModbusBitMask(6, "PV String Loss 2015 Warning"),
          ModbusBitMask(7, "Internal Fan Abnormal 2087 Major"),
          ModbusBitMask(8, "DC Protection Unit Abnormal[8] 2088 Major"),
          ModbusBitMask(9, "EL Unit Abnormal 2089 Minor"),
          ModbusBitMask(10, "Active Adjustment Instruction Abnormal"),
          ModbusBitMask(11, "Reactive Adjustment Instruction Abnormal"),
          ModbusBitMask(12, "CT Wiring Abnormal 2092 Major"),
          ModbusBitMask(13, "DC Arc Fault(ADMC Alarm to be clear manually)"),
        ]),
    ModbusInt16Register(
        name: "PV1 Voltage",
        type: ModbusElementType.holdingRegister,
        address: 32016,
        uom: "V",
        multiplier: .1),
    ModbusInt16Register(
        name: "PV1 Current",
        type: ModbusElementType.holdingRegister,
        address: 32017,
        uom: "A",
        multiplier: .01),
    ModbusInt16Register(
        name: "PV2 Voltage",
        type: ModbusElementType.holdingRegister,
        address: 32018,
        uom: "V",
        multiplier: .1),
    ModbusInt16Register(
        name: "PV2 Current",
        type: ModbusElementType.holdingRegister,
        address: 32019,
        uom: "A",
        multiplier: .01),
    ModbusInt16Register(
        name: "PV3 Voltage",
        type: ModbusElementType.holdingRegister,
        address: 32020,
        uom: "V",
        multiplier: .1),
    ModbusInt16Register(
        name: "PV3 Current",
        type: ModbusElementType.holdingRegister,
        address: 32021,
        uom: "A",
        multiplier: .01),
    ModbusInt16Register(
        name: "PV4 Voltage",
        type: ModbusElementType.holdingRegister,
        address: 32022,
        uom: "V",
        multiplier: .1),
    ModbusInt16Register(
        name: "PV4 Current",
        type: ModbusElementType.holdingRegister,
        address: 32023,
        uom: "A",
        multiplier: .01),
  ]);
  var inverterRegs2 = ModbusElementsGroup([
    ModbusInt32Register(
        name: "Input power",
        type: ModbusElementType.holdingRegister,
        address: 32064,
        uom: "KW",
        multiplier: .001),
    ModbusUint16Register(
        name: "Power grid voltage/Line voltage between phases A and B",
        type: ModbusElementType.holdingRegister,
        address: 32066,
        uom: "V",
        multiplier: .1,
        description:
            "When the output mode is L/N, L1/L2/N, or L1/L2, Power Grid voltage is used"),
    ModbusUint16Register(
        name: "Line voltage between phases B and C",
        type: ModbusElementType.holdingRegister,
        address: 32067,
        uom: "V",
        multiplier: .1,
        description:
            "When the output mode is L/N, L1/L2/N, or L1/L2, the information is invalid"),
    ModbusUint16Register(
        name: "Line voltage between phases C and A",
        type: ModbusElementType.holdingRegister,
        address: 32068,
        uom: "V",
        multiplier: .1,
        description:
            "When the output mode is L/N, L1/L2/N, or L1/L2, the information is invalid"),
    ModbusUint16Register(
        name: "Phase A voltage",
        type: ModbusElementType.holdingRegister,
        address: 32069,
        uom: "V",
        multiplier: .1,
        description:
            "When the output mode is L/N, L1/L2/N, or L1/L2, the information is invalid"),
    ModbusUint16Register(
        name: "Phase B voltage",
        type: ModbusElementType.holdingRegister,
        address: 32070,
        uom: "V",
        multiplier: .1,
        description:
            "When the output mode is L/N, L1/L2/N, or L1/L2, the information is invalid"),
    ModbusUint16Register(
        name: "Phase C voltage",
        type: ModbusElementType.holdingRegister,
        address: 32071,
        uom: "V",
        multiplier: .1,
        description:
            "When the output mode is L/N, L1/L2/N, or L1/L2, the information is invalid"),
    ModbusInt32Register(
        name: "Power grid current/Phase A current",
        type: ModbusElementType.holdingRegister,
        address: 32072,
        uom: "A",
        multiplier: .001,
        description:
            "When the output mode is L/N, L1/L2/N, or L1/L2, Power Grid current is used"),
    ModbusInt32Register(
        name: "Phase B current",
        type: ModbusElementType.holdingRegister,
        address: 32074,
        uom: "A",
        multiplier: .001,
        description:
            "When the output mode is L/N, L1/L2/N, or L1/L2, the information is invalid"),
    ModbusInt32Register(
        name: "Phase C current",
        type: ModbusElementType.holdingRegister,
        address: 32076,
        uom: "A",
        multiplier: .001,
        description:
            "When the output mode is L/N, L1/L2/N, or L1/L2, the information is invalid"),
    ModbusInt32Register(
        name: "Peak active power of current day",
        type: ModbusElementType.holdingRegister,
        address: 32078,
        uom: "kW",
        multiplier: .001),
    ModbusInt32Register(
        name: "Active power",
        type: ModbusElementType.holdingRegister,
        address: 32080,
        uom: "kW",
        multiplier: .001),
    ModbusInt32Register(
        name: "Reactive power",
        type: ModbusElementType.holdingRegister,
        address: 32082,
        uom: "kVar",
        multiplier: .001),
    ModbusInt16Register(
        name: "Power factor",
        type: ModbusElementType.holdingRegister,
        address: 32084,
        multiplier: .001),
    ModbusUint16Register(
        name: "Grid frequency",
        type: ModbusElementType.holdingRegister,
        address: 32085,
        uom: "Hz",
        multiplier: .01),
    ModbusUint16Register(
        name: "Efficiency",
        type: ModbusElementType.holdingRegister,
        address: 32086,
        uom: "%",
        multiplier: .01),
    ModbusInt16Register(
        name: "Internal temperature",
        type: ModbusElementType.holdingRegister,
        address: 32087,
        uom: "°C",
        multiplier: .1),
    ModbusUint16Register(
        name: "Insulation resistance",
        type: ModbusElementType.holdingRegister,
        address: 32088,
        uom: "MΩ",
        multiplier: .001),
    ModbusStatusRegister(
        name: "Device status",
        type: ModbusElementType.holdingRegister,
        address: 32089,
        statusValues: [
          ModbusStatus(0x0000, "Standby: initializing"),
          ModbusStatus(0x0001, "Standby: detecting insulation resistance"),
          ModbusStatus(0x0002, "Standby: detecting irradiation"),
          ModbusStatus(0x0003, "Standby: drid detecting"),
          ModbusStatus(0x0100, "Starting"),
          ModbusStatus(0x0200, "On-grid (Off-grid mode: running)"),
          ModbusStatus(0x0201,
              "Grid connection: power limited (Off-grid mode: running: power limited)"),
          ModbusStatus(0x0202,
              "Grid connection: selfderating (Off-grid mode: running: selfderating)"),
          ModbusStatus(0x0203, "Off-grid Running"),
          ModbusStatus(0x0300, "Shutdown: fault"),
          ModbusStatus(0x0301, "Shutdown: command"),
          ModbusStatus(0x0302, "Shutdown: OVGR"),
          ModbusStatus(0x0303, "Shutdown: communication disconnected"),
          ModbusStatus(0x0304, "Shutdown: power limited"),
          ModbusStatus(0x0305, "Shutdown: manual startup required"),
          ModbusStatus(0x0306, "Shutdown: DC switches disconnected"),
          ModbusStatus(0x0307, "Shutdown: rapid cutoff"),
          ModbusStatus(0x0308, "Shutdown: input underpower"),
          ModbusStatus(0x0401, "Grid scheduling: cosφ-P curve"),
          ModbusStatus(0x0402, "Grid scheduling: Q-U curve"),
          ModbusStatus(0x0403, "Grid scheduling: PF-U curve"),
          ModbusStatus(0x0404, "Grid scheduling: dry contact"),
          ModbusStatus(0x0405, "Grid scheduling: Q-P curve"),
          ModbusStatus(0x0500, "Spotcheck ready"),
          ModbusStatus(0x0501, "Spotchecking"),
          ModbusStatus(0x0600, "Inspecting"),
          ModbusStatus(0X0700, "AFCI self check"),
          ModbusStatus(0X0800, "I-V scanning"),
          ModbusStatus(0X0900, "DC input detection"),
          ModbusStatus(0X0A00, "Running: off-grid charging"),
          ModbusStatus(0xA000, "Standby: no irradiation"),
        ]),
    ModbusUint16Register(
        name: "Fault code",
        type: ModbusElementType.holdingRegister,
        address: 32090),
    ModbusEpochRegister(
        name: "Startup time",
        type: ModbusElementType.holdingRegister,
        address: 32091,
        isUtc: false),
    ModbusEpochRegister(
        name: "Shutdown time",
        type: ModbusElementType.holdingRegister,
        address: 32093,
        isUtc: false),
    ModbusUint32Register(
        name: "Accumulated energy yield",
        type: ModbusElementType.holdingRegister,
        address: 32106,
        uom: "kwh",
        multiplier: .01),
    ModbusUint32Register(
        name: "Daily energy yield",
        type: ModbusElementType.holdingRegister,
        address: 32114,
        uom: "kwh",
        multiplier: .01),
  ]);

  try {
    var batteryRegsReq = batteryRegs.getReadRequest();
    var res = await client.send(batteryRegsReq);
    if (res == ModbusResponseCode.requestSucceed) {
      for (var element in batteryRegs) {
        print(element);
      }
    } else {
      print(res);
    }

    var meterRegsReq = meterRegs.getReadRequest();
    res = await client.send(meterRegsReq);
    if (res == ModbusResponseCode.requestSucceed) {
      for (var element in meterRegs) {
        print(element);
      }
    } else {
      print(res);
    }

    var inverterRegs1Req = inverterRegs1.getReadRequest();
    res = await client.send(inverterRegs1Req);
    if (res == ModbusResponseCode.requestSucceed) {
      for (var element in inverterRegs1) {
        print(element);
      }
    } else {
      print(res);
    }

    var inverterRegs2Req = inverterRegs2.getReadRequest();
    res = await client.send(inverterRegs2Req);
    if (res == ModbusResponseCode.requestSucceed) {
      for (var element in inverterRegs2) {
        print(element);
      }
    } else {
      print(res);
    }
  } finally {
    client.disconnect();
  }
}
```