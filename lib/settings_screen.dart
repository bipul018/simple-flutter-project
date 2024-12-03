import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'navigator.dart';
import 'data.dart';

class SettingsScreen extends StatefulWidget{
  const SettingsScreen(title, {super.key}): this.title = title[0]+": Settings";

  final String title;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen>{
  final _formKey = GlobalKey<FormState>();
  final _numField = TextEditingController();
  final _nameField = TextEditingController();
  final _ageField = TextEditingController();

  @override
  void dispose(){
    
    _numField.dispose();
    _nameField.dispose();
    _ageField.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext cxt){
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body : Form(
        key: _formKey,
        child: Column(
          children:<Widget>[
            TextFormField(
              controller:_numField,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp("[0-9]"),
                ),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a unique id';
                }
                return null;
              },
            ),
            TextFormField(
              controller:_nameField,
              // The validator receives the text that the user has entered.
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter dog name';
                }
                return null;
              },
            ),
            TextFormField(
              controller:_ageField,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp("[0-9]"),
                ),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter dog age';
                }
                return null;
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final idt = int.parse(_numField.text);
                  final name = _nameField.text;
                  final aget = int.parse(_ageField.text);
                  ()async{
                    dogstore.insert(Dog(id: idt, name: name, age: aget));
                  }();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Inserting Dog (${idt}, ${name}, ${aget}) to databse...')),
                  );
                }
              },
              child: Text('Push to Database'),
            ),
          ],
      )),
      persistentFooterButtons: [Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: get_buttons(cxt),
      )],
    );
  }
}
