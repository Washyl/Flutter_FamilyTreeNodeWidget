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

void printFamilyTree(FamilyTreeNode node, [int level = 0]) {
  String indent = ' ' * level * 2;

  if (node.firstPerson != null) {
    print('$indent First Person: ${node.firstPerson!}');
    for (var child in node.firstPerson!.children) {
      printFamilyTree(
          FamilyTreeNode(firstPerson: child.firstPerson), level + 1);
    }
  }

  if (node.secondPerson != null) {
    print('$indent Second Person: ${node.secondPerson!}');
    for (var child in node.secondPerson!.children) {
      printFamilyTree(
          FamilyTreeNode(secondPerson: child.secondPerson), level + 1);
    }
  }

  for (var child in node.children) {
    printFamilyTree(child, level + 1);
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
    getFamilyService();
  }

  Future<void> getFamilyService() async {
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

  // Future<void> getFamilyService() async {
  //   try {
  //     final jsonString = await rootBundle.loadString('assets/my_data.json');
  //     final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
  //
  //     if (jsonList.isNotEmpty) {
  //       rootNode = FamilyTreeNode.fromJson(jsonList[0]);
  //       _buildNodeButtons();
  //       setState(() {});
  //     } else {
  //       print('No data received');
  //     }
  //   } catch (e) {
  //     print('Error loading JSON data from assets: $e');
  //   }
  // }

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
        onPanUpdate: (details) {
          setState(() {
            _offset += details.delta;
            _buildNodeButtons();
          });
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
              const SizedBox(height: 10.0),
              GestureDetector(
                onTap: () {
                  _showEmptyPersonModal(person);
                },
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: const BoxDecoration(
                    color: Color(0xFFb9a270),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmptyPersonModal(Person person) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(  // Use Dialog for more control over size
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 600 : 400, // Set width based on screen size
            child: Padding(  // Add padding here
              padding: const EdgeInsets.all(16.0),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  // Set the default selectedType based on person.type
                  String selectedType = person.type == 3 ? 'Pet' : 'Natural Person';
                  TextEditingController firstNameController = TextEditingController();
                  TextEditingController lastNameController = TextEditingController();
                  TextEditingController dateController = TextEditingController();
                  String? selectedRelation; // Initially unselected

                  // Toggle state variables
                  List<bool> _relationshipStatus = [true, false]; // Initial state: Previous Relationship
                  List<bool> _adoptedStatus = [false, true]; // Initial state: Not Adopted
                  List<bool> _lifeStatus = [true, false]; // Initial state: Alive

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('Add Relation', style: TextStyle(fontSize: 20)),
                        ),
                        // Only show these options if the person is not a pet
                        if (person.type != 3) ...[
                          Column( // Change Row to Column here
                            children: [
                              RadioListTile<String>(
                                title: const Text('Natural Person'),
                                value: 'Natural Person',
                                groupValue: selectedType,
                                onChanged: (value) {
                                  setState(() {
                                    selectedType = value!;
                                  });
                                },
                              ),
                              RadioListTile<String>(
                                title: const Text('Entity'),
                                value: 'Entity',
                                groupValue: selectedType,
                                onChanged: (value) {
                                  setState(() {
                                    selectedType = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                        // Always show Pet option
                        RadioListTile<String>(
                          title: const Text('Pet'),
                          value: 'Pet',
                          groupValue: selectedType,
                          onChanged: (value) {
                            setState(() {
                              selectedType = value!;
                            });
                          },
                        ),
                        // Form fields for Natural Person
                        if (selectedType == 'Natural Person') ...[
                          TextField(
                            controller: firstNameController,
                            decoration: const InputDecoration(labelText: 'First Name'),
                          ),
                          TextField(
                            controller: lastNameController,
                            decoration: const InputDecoration(labelText: 'Last Name'),
                          ),
                          TextField(
                            controller: dateController,
                            decoration: const InputDecoration(labelText: 'Date of Birth'),
                            onTap: () async {
                              // Remove focus from the text field
                              FocusScope.of(context).requestFocus(FocusNode());

                              // Open the date picker
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Colors.orange,
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.orange,
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (pickedDate != null) {
                                dateController.text = pickedDate.toString().substring(0, 10);
                              }
                            },
                          ),
                          DropdownButtonFormField<String>(
                            value: selectedRelation,
                            decoration: const InputDecoration(
                              labelText: 'Relation',
                              hintStyle: TextStyle(color: Colors.white),
                            ),
                            hint: const Text(
                              'Select Relation',
                              style: TextStyle(color: Colors.white),
                            ),
                            items: <String>['Child', 'Spouse', 'Parent'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(color: Colors.white), // Set text color to white
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedRelation = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          // Relationship Status Toggle
                          Column(
                            children: [
                              ToggleButtons(
                                isSelected: _relationshipStatus,
                                onPressed: (int index) {
                                  setState(() {
                                    _relationshipStatus = [index == 0, index == 1];
                                  });
                                },
                                borderRadius: BorderRadius.circular(8.0),
                                constraints: const BoxConstraints(
                                  minWidth: 140.0,
                                  minHeight: 40.0,
                                ),
                                children: const <Widget>[
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text('Previous', textAlign: TextAlign.center),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text('Current', textAlign: TextAlign.center),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Adopted Status Toggle
                              ToggleButtons(
                                isSelected: _adoptedStatus,
                                onPressed: (int index) {
                                  setState(() {
                                    _adoptedStatus = [index == 0, index == 1];
                                  });
                                },
                                borderRadius: BorderRadius.circular(8.0),
                                constraints: const BoxConstraints(
                                  minWidth: 140.0,
                                  minHeight: 40.0,
                                ),
                                children: const <Widget>[
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text('Adopted', textAlign: TextAlign.center),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text('Not Adopted', textAlign: TextAlign.center),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Life Status Toggle
                              ToggleButtons(
                                isSelected: _lifeStatus,
                                onPressed: (int index) {
                                  setState(() {
                                    _lifeStatus = [index == 0, index == 1];
                                  });
                                },
                                borderRadius: BorderRadius.circular(8.0),
                                constraints: const BoxConstraints(
                                  minWidth: 140.0,
                                  minHeight: 40.0,
                                ),
                                children: const <Widget>[
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text('Alive', textAlign: TextAlign.center),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text('Deceased', textAlign: TextAlign.center),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ] else ...[
                          TextField(
                            controller: firstNameController,
                            decoration: const InputDecoration(labelText: 'Name'),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPersonModal(Person person) {
    String selectedType = 'Natural Person'; // Default selection
    TextEditingController firstNameController =
    TextEditingController(text: person.firstName);
    TextEditingController lastNameController =
    TextEditingController(text: person.lastName);
    TextEditingController dateController =
    TextEditingController(text: person.born);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        double modalWidth = MediaQuery.of(context).size.width > 600
            ? 600
            : 400; // Set width for tablets

        return AlertDialog(
          title: Text('Edit Entry'),
          content: SizedBox(
            width: modalWidth, // Set the width for the content
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RadioListTile<String>(
                              title: const Text('Natural Person'),
                              value: 'Natural Person',
                              groupValue: selectedType,
                              onChanged: (value) {
                                setState(() {
                                  selectedType = value!;
                                });
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('Entity'),
                              value: 'Entity',
                              groupValue: selectedType,
                              onChanged: (value) {
                                setState(() {
                                  selectedType = value!;
                                });
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('Pet'),
                              value: 'Pet',
                              groupValue: selectedType,
                              onChanged: (value) {
                                setState(() {
                                  selectedType = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (selectedType == 'Natural Person') ...[
                        TextField(
                          controller: firstNameController,
                          decoration: InputDecoration(labelText: 'First Name'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: lastNameController,
                          decoration: InputDecoration(labelText: 'Last Name'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: dateController,
                          decoration: InputDecoration(labelText: 'Date of Birth'),
                          onTap: () async {
                            FocusScope.of(context).requestFocus(FocusNode());
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Colors.orange,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.orange,
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              dateController.text =
                                  pickedDate.toString().substring(0, 10);
                            }
                          },
                        ),
                      ] else ...[
                        TextField(
                          controller: firstNameController,
                          decoration: InputDecoration(labelText: 'Name'),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text('Save'),
              onPressed: () async {
                setState(() {
                  person.firstName = firstNameController.text;
                  person.lastName = lastNameController.text;
                  person.type = selectedType == 'Entity'
                      ? 2
                      : selectedType == 'Pet'
                      ? 3
                      : 1;
                  person.born = dateController.text;
                });

                int type = 1; // default to 1 for Natural Person
                if (selectedType == 'Entity') {
                  type = 2;
                } else if (selectedType == 'Pet') {
                  type = 3;
                }

                final Map<String, dynamic> data = {
                  "birth_date": person.born,
                  "disinherited": false,
                  "first": person.firstName,
                  "last": person.lastName,
                  "type": type,
                };

                // try {
                //   final response = await BaseClient(context)
                //       .put('/beneficiaries/${person.id}', data);
                //   print('Update successful, response: $response');
                //   ScaffoldMessenger.of(context).showSnackBar(
                //     const SnackBar(content: Text('Updated successfully')),
                //   );
                // } catch (e) {
                //   print('Error occurred: $e');
                // }

                setState(() {
                  _buildNodeButtons();
                });
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                // try {
                //   final response = await BaseClient(context)
                //       .delete('/beneficiaries/${person.id}');
                //   getFamilyService();
                //   ScaffoldMessenger.of(context).showSnackBar(
                //     const SnackBar(content: Text('Deleted successfully')),
                //   );
                // } catch (e) {
                //   print('Error occurred: $e');
                // }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (rootNode == null) {
      return Scaffold(
        // appBar: AppBar(
        //   title: const Text('Family tree'),
        //   leading: IconButton(
        //     icon: const Icon(Icons.arrow_back),
        //     onPressed: () {
        //       context.go('/home');
        //     },
        //   ),
        // ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Family tree'),
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () {
      //       // context.go('/home');
      //     },
      //   ),
      // ),
      body: Stack(
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _offset += details.delta;
                _buildNodeButtons();
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
          // Positioned(
          //   bottom: 16,
          //   left: 16,
          //   child: FloatingActionButton(
          //     onPressed: () {
          //       setState(() {
          //         _zoomIn();
          //         // _scale = (_scale * 1.1).clamp(0.2, 1.0);
          //         // _buildNodeButtons();
          //       });
          //     },
          //     child: const Icon(Icons.zoom_in),
          //   ),
          // ),
          const Positioned(
            top: 20,
            right: 16,
            child: Row(
              children: [
                Icon(
                  Icons.linear_scale_outlined,
                  color: Color(0xFFDCD5CA),
                  size: 40,
                ),
                SizedBox(
                  width: 5,
                ),
                Text(
                  "Current Relationship",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 50,
            right: 16,
            child: Row(
              children: [
                Icon(
                  Icons.linear_scale_outlined,
                  color: Colors.deepPurple,
                  size: 40,
                ),
                SizedBox(
                  width: 5,
                ),
                Text(
                  "Previous Relationship",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Positioned(
              top: 80,
              right: 16,
              child: Row(
                children: [
                  Icon(
                    Icons.linear_scale_outlined,
                    color: Colors.blueAccent,
                    size: 40,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    "Previous Relationship",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              )),
          // Positioned(
          //   bottom: 16,
          //   left: 76,
          //   child: FloatingActionButton(
          //     onPressed: () {
          //       setState(() {
          //         _zoomOut();
          //         // _scale = (_scale * 0.95).clamp(0.8, 1.0);
          //         // _buildNodeButtons();
          //       });
          //     },
          //     child: const Icon(Icons.zoom_out),
          //   ),
          // ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _offset = Offset.zero;
                  _buildNodeButtons();
                });
              },
              child: const Icon(Icons.center_focus_strong),
            ),
          ),
        ],
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
              (i + 0.3) * 650 * _scale;
          final double childY =
              firstPersonOffset.dy + verticalSpacing - 40 + _scale;
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
              i * horizontalSpacing * _scale +
              200 * _scale;
          final double childY =
              secondPersonOffset.dy + verticalSpacing * _scale + 100 * _scale;
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

  void _zoomIn() {
    setState(() {
      final center = Offset(MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2);
      _offset = center + (_offset - center) * 1.1;
      _scale = (_scale * 1.1).clamp(0.2, 1.0);
      _buildNodeButtons();
    });
  }

  void _zoomOut() {
    setState(() {
      final center = Offset(MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2);
      _offset = center + (_offset - center) * 0.95;
      _scale = (_scale * 0.95).clamp(0.8, 1.0);
      _buildNodeButtons();
    });
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
      ..color = const Color(0xFFDCD5CA)
      ..strokeWidth = 2.0 * scale;

    Offset start = (Offset(size.width / 2, 50) + offset) * scale;

    drawLines(canvas, start, rootNode, linePaint);
  }

  void drawLines(Canvas canvas, Offset parentPosition,
      FamilyTreeNode parentNode, Paint linePaint) {
    const double verticalSpacing = 250.0;
    const double horizontalSpacing = 300.0;

    final double middleY = parentPosition.dy + verticalSpacing * scale / 2;

    Offset firstParentPosition = parentPosition.translate(0, 0);
    Offset secondParentPosition = parentPosition.translate(150, 0);

    Offset originPosition = Offset.zero;

    if (parentNode.firstPerson != null && parentNode.secondPerson != null) {
      Offset midPoint = Offset(
          (firstParentPosition.dx + secondParentPosition.dx) / 2,
          firstParentPosition.dy);
      canvas.drawLine(firstParentPosition, secondParentPosition, linePaint);
      originPosition = midPoint;
    } else if (parentNode.firstPerson != null) {
      originPosition = firstParentPosition;
    } else if (parentNode.secondPerson != null) {
      originPosition = secondParentPosition;
    }

    Offset verticalMidPoint = Offset(originPosition.dx, middleY + 100);
    if (parentNode.children.isNotEmpty) {
      canvas.drawLine(originPosition, verticalMidPoint, linePaint);
    }

    final double startX = parentPosition.dx -
        ((parentNode.children.length * horizontalSpacing * scale) / 2);

    for (int i = 0; i < parentNode.children.length; i++) {
      final double childX = startX + i * 2 * horizontalSpacing * scale;
      final double childY = parentPosition.dy + 300 + verticalSpacing * scale;
      final childPosition = Offset(childX, childY);

      Offset horizontalMidPoint = Offset(childX, middleY + 100);
      canvas.drawLine(verticalMidPoint, horizontalMidPoint, linePaint);

      canvas.drawLine(horizontalMidPoint, childPosition, linePaint);

      drawLines(canvas, childPosition, parentNode.children[i], linePaint);
    }

    if (parentNode.secondPerson != null &&
        parentNode.secondPerson!.children.isNotEmpty) {
      for (int i = 0; i < parentNode.secondPerson!.children.length; i++) {
        final double childX = secondParentPosition.dx +
            i * horizontalSpacing * scale +
            200 * scale;
        final double childY =
            secondParentPosition.dy + verticalSpacing * scale + 100 * scale;
        final childPosition = Offset(childX, childY);

        Offset horizontalMidPoint = Offset(childX, middleY - 125 * scale);
        Paint linePaintSecond = Paint()
          ..color = Colors.blueAccent
          ..strokeWidth = 2.0 * scale;
        canvas.drawLine(
            secondParentPosition, horizontalMidPoint, linePaintSecond);

        canvas.drawLine(horizontalMidPoint, childPosition, linePaintSecond);

        drawLines(canvas, childPosition, parentNode.secondPerson!.children[i],
            linePaintSecond);
      }
    }

    if (parentNode.firstPerson != null &&
        parentNode.firstPerson!.children.isNotEmpty) {
      for (int i = 0; i < parentNode.firstPerson!.children.length; i++) {
        final double childX = firstParentPosition.dx +
            i * horizontalSpacing * scale -
            (i + 0.3) * 650 * scale;
        final double childY =
            firstParentPosition.dy + verticalSpacing * scale - 40 * scale;
        final childPosition = Offset(childX, childY);

        Offset horizontalMidPoint = Offset(childX, middleY - 125 * scale);
        Paint linePaintFirst = Paint()
          ..color = Colors.deepPurple
          ..strokeWidth = 2.0 * scale;
        canvas.drawLine(
            firstParentPosition, horizontalMidPoint, linePaintFirst);

        canvas.drawLine(horizontalMidPoint, childPosition, linePaintFirst);

        drawLines(canvas, childPosition, parentNode.firstPerson!.children[i],
            linePaintFirst);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
