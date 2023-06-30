# Introduction
This is a set of three packages implementing Modbus Client sending requests to a remote device (i.e. Modbus Server).

[Modbus Client](https://pub.dev/packages/modbus_client) is the base implementation for the **TCP** and **Serial** packages.
[Modbus Client TCP](https://pub.dev/packages/modbus_client_tcp) implements the **ASCII** and **RTU** protocols to send requests via **Serial Port**
[Modbus Client Serial](https://pub.dev/packages/modbus_client_serial) implements the **TCP** protocol to sent requests via **ethernet networks**.

The split of the packages is done to minimize dependencies on your project.

# Usage

Using modbus client is simple. You define your elements, create a read or write request out of them and use the client to send the request. 
```dart
```