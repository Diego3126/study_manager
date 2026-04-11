import 'package:flutter/material.dart';
import 'widgets/custom_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StudyManager')),
      drawer: const CustomDrawer(),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Bienvenido a StudyManager\nTu agenda académica inteligente',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}