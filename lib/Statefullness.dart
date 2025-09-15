import 'package:flutter/material.dart';

class MyStatefulWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    throw MyState();
  }
}

class MyState extends State<MyStatefulWidget> {
  String name = "";
  String currency = "";
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: "Insert your input",
        ),
        onSubmitted: (String string) {
          setState(() {
            name = string;
          });
        },
      ),
      Text("The text input is: ${name}"),
      dropdownlist()
    ]);
  }

  DropdownButton dropdownlist() {
    var currencies = ["Dollars", "Euros"];
    return DropdownButton<String>(
      items: currencies.map((String dropDownStringItem) {
        return DropdownMenuItem<String>(
          value: dropDownStringItem,
          child: Text(dropDownStringItem),
        );
      }).toList(),
      onChanged: (String? newValueSelected) {
        if (newValueSelected != null) {
          setState(() {
            currency = newValueSelected;
          });
        }
      },

      value: currency,
    );
  }

}