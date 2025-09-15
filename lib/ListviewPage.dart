import 'package:flutter/material.dart';

class Listviewpage extends StatelessWidget {
  const Listviewpage({super.key});

  @override
  Widget build(BuildContext context) {
    ListView listView = ListView(
      children: <Widget>[
        ListTile(
          leading: Icon(Icons.landscape), // First icon on the left side, landscape is a predefined icon
          title: Text("Landscape"), // Big title
          subtitle: Text("Beautiful view!"), // Small description
          trailing: Icon(Icons.wb_sunny), // Last icon on the right side, wb_sunny is a predefined icon
        )
      ],
    );
    return listView;
  }

  // Longlist is better for long lists

}