## Read request

``` dart
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

void main() async {
  // Create a modbus int16 register element
  var batteryTemperature = ModbusInt16Register(
      name: "BatteryTemperature",
      type: ModbusElementType.inputRegister,
      address: 22,
      uom: "°C",
      multiplier: 0.1,
      onUpdate: (self) => print(self));

  // Create the modbus client.
  var modbusClient = ModbusClientTcp("127.0.0.1", unitId: 1);

  // Send a read request from the element
  await modbusClient.send(batteryTemperature.getReadRequest());

  // Ending here
  modbusClient.disconnect();
}
```

## Group read request

``` dart
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

  // Create the modbus client.
  var modbusClient = ModbusClientTcp("127.0.0.1", unitId: 1);

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
  var batteryStatus = ModbusEnumRegister(
      name: "BatteryStatus",
      address: 11,
      type: ModbusElementType.holdingRegister,
      enumValues: BatteryStatus.values,
      onUpdate: (self) => print(self));

  var modbusClient = ModbusClientTcp("127.0.0.1", unitId: 1);

  var req = batteryStatus.getWriteRequest(BatteryStatus.running);
  var res = await modbusClient.send(req);
  print(res.name);

  modbusClient.disconnect();
}
```

