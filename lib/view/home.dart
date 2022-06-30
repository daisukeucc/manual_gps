import 'package:flutter/material.dart';
import 'package:manual_gps/view/top.dart';

class HomePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Test1"),
        ),
        body: Center(
            child: TextButton(
                onPressed: () => {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return TopPage();
                  }))
                },
                child: Text("進む", style: TextStyle(fontSize: 80)))));
  }
}