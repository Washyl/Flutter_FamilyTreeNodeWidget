import 'package:flutter/material.dart';
import 'family_tree_view.dart'; // Import the family tree widget file

void main() {
  runApp(const FamilyTreeApp());
}

class FamilyTreeApp extends StatelessWidget {
  const FamilyTreeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Tree Visualizer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const FamilyTreePage(),
    );
  }
}

class FamilyTreePage extends StatelessWidget {
  const FamilyTreePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FamilyTreeWidget(),  // This widget will handle the rendering of the family tree.
    );
  }
}
