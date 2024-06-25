## 1.3.0
- Added 'ModbusEndianess' handling for numeric registers
- Added 'ModbusFloatRegister' and 'ModbusDoubleRegister' registers
- 'address' field is no more final

## 1.2.1
- Added 'ModbusBytesRegister' class

## 1.2.0
- Changed 'ModbusFunctionCode' from enum to class in order to add custom types
- Changed 'ModbusElementType' from enum to class in order to add custom types
- Added 'custom_request_example.dart' example
- Changed ModbusRequest:
  - 'protocolDataUnit' is now a getter and no more a final variable
  - 'functionCode' is now of type 'FunctionCode'

## 1.1.2
- Added 'ModbusFileMultipleRecord' class
- Bug fix in response error code handling

## 1.1.1
- Added Uint16, Int16, Uint32, Int32, Float and Double ModbusFileRecord types

## 1.1.0
- Added Modbus Read & Write file records (i.e. 0x14 & 0x15 function codes)

## 1.0.4
- Added 'onUpdate' paameter for ModbusDiscreteInput and ModbusCoil

## 1.0.3+3
- Little adjustment in case 'setResponseCode' is called multiple times
- Documentation and examples update
- Warnings removal

## 1.0.2
- Removed **ModbusEpochType** from **ModbusEpochRegister** since it's only a 32 bits registry for now and it cannot handle milliseconds representation.
- Some cosmetic code changes in **ModbusRequest** and **ModbusElementRequest** to help overriding those classes.
- **README.md** and **example.md** file updates

## 1.0.1
- set dependency of "collection" to 1.17.1 in order to have flutter compatibility [https://github.com/cabbi/modbus_client/issues/1] 
  
## 1.0.0
- Initial version.
