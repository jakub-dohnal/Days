import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'Days.dart';

void main() => runApp(new DaysApp());

class DaysApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Days',
      theme: new ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: new MyDaysWG(title: 'My Days'),
    );
  }
}
