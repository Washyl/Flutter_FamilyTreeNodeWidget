import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Person {
  int id;
  String firstName;
  String? lastName;
  String? born;
  bool disinherited;
  int? parentBranch;
  int type;
  List<FamilyTreeNode> children;

  Person({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.type,
    this.born,
    required this.disinherited,
    this.parentBranch,
    this.children = const [],
  });

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    id: json["id"],
    firstName: json["firstName"] ?? "undefined",
    lastName: json["lastName"] ?? 'undefined',
    type: json["type"],
    born: json["born"],
    disinherited: json["disinherited"],
    parentBranch: json["parent_branch"],
    children: json["children"] == null
        ? []
        : List<FamilyTreeNode>.from(json["children"]!.map((x) {
      return FamilyTreeNode.fromJson(x);
    })),
  );

  String getBornDate() {
    return born != null
        ? 'Born: ${DateFormat('MM/dd/yyyy').format(DateTime.parse(born!))}'
        : 'Born: Unknown';
  }
}

class FamilyTreeNode {
  Person? firstPerson;
  Person? secondPerson;
  List<FamilyTreeNode> children;

  FamilyTreeNode({
    this.firstPerson,
    this.secondPerson,
    this.children = const [],
  });

  factory FamilyTreeNode.fromJson(Map<String, dynamic> json) => FamilyTreeNode(
    firstPerson: json["firstPerson"] == null
        ? null
        : Person.fromJson(json["firstPerson"]),
    secondPerson: json["secondPerson"] == null
        ? null
        : Person.fromJson(json["secondPerson"]),
    children: json["children"] == null
        ? []
        : List<FamilyTreeNode>.from(
        json["children"]!.map((x) => FamilyTreeNode.fromJson(x))),
  );
}

class FamilyTreeWidget extends StatefulWidget {
  const FamilyTreeWidget({super.key});

  @override
  FamilyTreeWidgetState createState() => FamilyTreeWidgetState();
}

class FamilyTreeWidgetState extends State<FamilyTreeWidget> {
  FamilyTreeNode? rootNode;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  List<Widget> _nodeButtons = [];

  @override
  void initState() {
    super.initState();
    // Load local JSON file for testing
    loadLocalJson();
  }

  Future<void> loadLocalJson() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/family_tree.json');
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      if (jsonList.isNotEmpty) {
        setState(() {
          rootNode = FamilyTreeNode.fromJson(jsonList[0]);
          _buildNodeButtons();
        });
      } else {
        print('No data received');
      }
    } catch (e) {
      print('Error loading JSON data from assets: $e');
    }
  }

  Widget _buildNodeButton(Offset position, Person person) {
    const double nodeWidth = 120.0;
    const double nodeHeight = 120.0;
    const double buttonSize = 30.0;

    String personTypeText;
    if (person.type == 1) {
      personTypeText = 'Natural Person';
    } else if (person.type == 2) {
      personTypeText = 'Entity';
    } else {
      personTypeText = 'Pet';
    }

    return Positioned(
      left: position.dx - (nodeWidth / 2),
      top: position.dy - (nodeHeight / 2),
      child: GestureDetector(
        onTap: () {
          _showPersonModal(person);
        },
        child: Container(
          width: nodeWidth,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: const Color(0xFFDCD5CA),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${person.firstName} ${person.lastName}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 5.0),
              Icon(
                person.type == 1
                    ? Icons.person
                    : person.type == 2
                    ? Icons.business
                    : Icons.pets,
              ),
              const SizedBox(height: 5.0),
              Text(
                person.getBornDate(),
                style: const TextStyle(color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _buildNodeButtons() {
    _nodeButtons.clear();
    _addNodeButtons(
        rootNode!, Offset(MediaQuery.of(context).size.width / 2, 50) + _offset);
  }

  void _addNodeButtons(FamilyTreeNode node, Offset position) {
    const double nodeWidth = 110.0;
    const double nodeHeight = 200.0;
    const double verticalSpacing = 250.0;
    const double horizontalSpacing = 300.0;

    if (node.firstPerson != null) {
      Offset firstPersonOffset =
      position.translate((nodeHeight + 40) * _scale, 0);
      _nodeButtons.add(_buildNodeButton(position * _scale, node.firstPerson!));

      if (node.firstPerson!.children.isNotEmpty) {
        for (int i = 0; i < node.firstPerson!.children.length; i++) {
          final double childX = position.dx +
              i * horizontalSpacing * _scale -
              (i + 0.3) * 650 * _scale; // Adjust horizontal spacing for children
          final double childY =
              firstPersonOffset.dy + verticalSpacing - 40 + _scale; // Adjust vertical spacing
          final childPosition = Offset(childX, childY);
          _addNodeButtons(node.firstPerson!.children[i], childPosition);
        }
      }
    }

    if (node.secondPerson != null) {
      Offset secondPersonOffset =
      position.translate((nodeWidth + 40) * _scale, 0);
      _nodeButtons.add(
          _buildNodeButton(secondPersonOffset * _scale, node.secondPerson!));

      if (node.secondPerson!.children.isNotEmpty) {
        for (int i = 0; i < node.secondPerson!.children.length; i++) {
          final double childX = secondPersonOffset.dx +
              i * horizontalSpacing * _scale + // Adjust horizontal alignment
              200 * _scale;
          final double childY =
              secondPersonOffset.dy + verticalSpacing * _scale + 100 * _scale; // Adjust vertical alignment
          final childPosition = Offset(childX, childY);
          _addNodeButtons(node.secondPerson!.children[i], childPosition);
        }
      }
    }

    final double startX =
        position.dx - ((node.children.length * horizontalSpacing * _scale) / 2);

    for (int i = 0; i < node.children.length; i++) {
      final double childX = startX + i * 2 * horizontalSpacing * _scale;
      final double childY = position.dy + 300 + verticalSpacing * _scale;
      final childPosition = Offset(childX, childY);
      _addNodeButtons(node.children[i], childPosition);
    }
  }

  void _showPersonModal(Person person) {
    // Show a modal to display person details
  }
  @override
  Widget build(BuildContext context) {
    if (rootNode == null) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onScaleUpdate: (details) {
              setState(() {
                // Apply the focalPointDelta for panning
                _offset += details.focalPointDelta;

                // Smooth scaling - adjust scale incrementally for smoother zooming
                // The '0.01' controls how fast or slow the zooming happens (smaller value = slower zoom)
                _scale = (_scale * (1 + (details.scale - 1) * 0.05)).clamp(0.5, 2.0);

                _buildNodeButtons(); // Rebuild the nodes when zooming and panning
              });
            },

            child: CustomPaint(
              size: Size.infinite,
              painter: FamilyTreePainter(
                rootNode: rootNode!,
                offset: _offset,
                scale: _scale,
              ),
            ),
          ),
          ..._nodeButtons,
          Positioned(
            top: 20,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.linear_scale, color: Colors.black, size: 20),
                    const SizedBox(width: 5),
                    const Text("Current Relationship"),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.linear_scale, color: Colors.deepPurple, size: 20),
                    const SizedBox(width: 5),
                    const Text("Previous Relationship"),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.linear_scale, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 5),
                    const Text("Previous Relationship"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class FamilyTreePainter extends CustomPainter {
  final FamilyTreeNode rootNode;
  final Offset offset;
  final double scale;

  FamilyTreePainter({
    required this.rootNode,
    required this.offset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint = Paint()
      ..color = const Color(0xFFDCD5CA) // Default for current relationship
      ..strokeWidth = 2.0 * scale;

    Offset start = (Offset(size.width / 2, 50) + offset) * scale;

    drawLines(canvas, start, rootNode, linePaint);
  }

  void drawLines(Canvas canvas, Offset parentPosition, FamilyTreeNode parentNode, Paint linePaint) {
    const double verticalSpacing = 250.0;
    const double horizontalSpacing = 300.0;

    final double middleY = parentPosition.dy + verticalSpacing * scale / 2;

    // Handle the first person (current relationship)
    if (parentNode.firstPerson != null) {
      Offset firstParentPosition = parentPosition.translate(0, 0);
      Offset verticalMidPoint = Offset(firstParentPosition.dx, middleY);

      // Draw lines for children of the first person (current relationship)
      if (parentNode.children.isNotEmpty) {
        canvas.drawLine(firstParentPosition, verticalMidPoint, linePaint); // Current relationship line

        final double startX = parentPosition.dx - ((parentNode.children.length * horizontalSpacing * scale) / 2);
        for (int i = 0; i < parentNode.children.length; i++) {
          final double childX = startX + i * horizontalSpacing * scale;
          final double childY = parentPosition.dy + 300 + verticalSpacing * scale;
          final childPosition = Offset(childX, childY);

          Offset horizontalMidPoint = Offset(childX, middleY);
          canvas.drawLine(verticalMidPoint, horizontalMidPoint, linePaint);
          canvas.drawLine(horizontalMidPoint, childPosition, linePaint);

          drawLines(canvas, childPosition, parentNode.children[i], linePaint);
        }
      }
    }

    // Handle the first person's previous relationship (shown in purple)
    if (parentNode.firstPerson != null && parentNode.firstPerson!.children.isNotEmpty) {
      // Create a new paint object for the purple line (previous relationship)
      Paint previousRelationshipPaintFirst = Paint()
        ..color = Colors.deepPurple // Purple for first person's previous relationship
        ..strokeWidth = 2.0 * scale;

      Offset firstParentPosition = parentPosition.translate(0, 0);

      for (int i = 0; i < parentNode.firstPerson!.children.length; i++) {
        final double childX = firstParentPosition.dx + i * horizontalSpacing * scale - (i + 0.3) * 650 * scale;
        final double childY = firstParentPosition.dy + verticalSpacing * scale - 40 * scale;
        final childPosition = Offset(childX, childY);

        Offset horizontalMidPoint = Offset(childX, middleY - 125 * scale);

        canvas.drawLine(firstParentPosition, horizontalMidPoint, previousRelationshipPaintFirst); // Purple line
        canvas.drawLine(horizontalMidPoint, childPosition, previousRelationshipPaintFirst);

        drawLines(canvas, childPosition, parentNode.firstPerson!.children[i], previousRelationshipPaintFirst);
      }
    }

    // Handle the second person (current or previous relationship shown in blue)
    if (parentNode.secondPerson != null) {
      // Create a new paint object for the blue line (current or previous relationship)
      Paint secondRelationshipPaint = Paint()
        ..color = Colors.blueAccent // Blue for second person's relationship
        ..strokeWidth = 2.0 * scale;

      Offset secondParentPosition = parentPosition.translate(150, 0);

      // Check if the second person has children and draw lines
      if (parentNode.secondPerson!.children.isNotEmpty) {
        for (int i = 0; i < parentNode.secondPerson!.children.length; i++) {
          final double childX = secondParentPosition.dx + horizontalSpacing * scale;
          final double childY = parentPosition.dy + verticalSpacing * scale;
          final childPosition = Offset(childX, childY);

          canvas.drawLine(secondParentPosition, childPosition, secondRelationshipPaint); // Blue line for second person

          drawLines(canvas, childPosition, parentNode.secondPerson!.children[i], secondRelationshipPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}



