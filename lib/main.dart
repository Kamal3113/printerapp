import 'package:ESmartPOS/lan_printer.dart';
import 'package:flutter/material.dart';

import 'package:ESmartPOS/lanPrint.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:
      //Lanprintss()
         Lanprint()
          //Lanprint2(),
    );
  }
}
