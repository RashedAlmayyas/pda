// import 'package:blue_thermal_printer/blue_thermal_printer.dart';
// import 'package:flutter/material.dart';
// class ZebraPage extends StatefulWidget {
//   @override
//   _ZebraPageState createState() => _ZebraPageState();
// }
//
// class _ZebraPageState extends State<ZebraPage> {
//   BlueThermalPrinter printer = BlueThermalPrinter.instance;
//   List<BluetoothDevice> devices = [];
//   BluetoothDevice? selectedDevice;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchDevices();
//   }
//
//   Future<void> fetchDevices() async {
//     try {
//       final List<BluetoothDevice> pairedDevices = await printer.getBondedDevices();
//       setState(() {
//         devices = pairedDevices;
//       });
//     } catch (e) {
//       print('Error fetching devices: $e');
//     }
//   }
//
//   void connectToDevice(BluetoothDevice device) async {
//     try {
//       await printer.connect(device);
//       setState(() {
//         selectedDevice = device;
//       });
//     } catch (e) {
//       print('Error connecting to device: $e');
//     }
//   }
//
//   void printSample() async {
//     if (selectedDevice != null) {
//       printer.write('^XA^FO50,50^ADN,36,20^FDmohammad bassam yahia^FS^XZ');
//     } else {
//       print("No device connected!");
//     }
//   }
//
//   void printArabicText() {
//     String line1 = "محمد بسام محمد يحيى";
//     String line2 = "العامة لتطوير البرمجيات";
//     String line3 = "مبرمج";
//     // ZPL Command for multi-line Arabic text
//     String zplCommand = '''
//     ^XA
//     ^CI28
//     ^FO50,50
//     ^A@N,36,36,E:TT0003M_.FNT
//     ^FD$line1^FS
//     ^FO50,100
//     ^A@N,36,36,E:TT0003M_.FNT
//     ^FD$line2^FS
//     ^FO50,150
//     ^A@N,36,36,E:TT0003M_.FNT
//     ^FD$line3^FS
//     ^XZ
//   ''';
//     printer.write(zplCommand);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Zebra Printer'),
//       ),
//       body: Column(
//         children: [
//           DropdownButton<BluetoothDevice>(
//             hint: Text('Select Device'),
//             value: selectedDevice,
//             onChanged: (BluetoothDevice? device) {
//               connectToDevice(device!);
//             },
//             items: devices
//                 .map((device) => DropdownMenuItem(
//               child: Text(device.name ?? ''),
//               value: device,
//             ))
//                 .toList(),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               ElevatedButton(
//                 onPressed: printSample,
//                 child: Text('Print English'),
//               ),
//               ElevatedButton(
//                 onPressed: printArabicText,
//                 child: Text('Print Arabic'),
//               ),
//             ],
//           )
//         ],
//       ),
//     );
//   }
// }