import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'camera_screen.dart';
import 'settings_screen.dart';
import 'web_screen.dart';

Map<String, (IconData, dynamic Function(List))> get_screens(){
  return <String, (IconData, dynamic Function(List))>{
    '/web' : (Icons.web, (List args) => WebScreen(args)),
    '/' : (Icons.home, (List args) => HomeScreen(args)),
    '/settings' : (Icons.settings, (List args) => SettingsScreen(args)),
    '/camera' : (Icons.camera, (List args) => CameraScreen(args)),

  };
}

Map<String, WidgetBuilder> get_navigator(args){
  final items = get_screens();
  return Map.fromIterable(
    items.keys,
    key: (key) => key,
    value: (key) => ((context) => items[key]!.$2(args)),
  );
  //return [for ((key, value) in get_screens())
  //(key, (cxt) => value[1].newInstance(new Symbol(''), args).reflectee)];
}

List<Widget> get_buttons(BuildContext cxt){
  final items = get_screens();
  return items.entries
  .map((entry) => ElevatedButton(
      onPressed : () => Navigator.pushNamed(cxt, entry.key),
      child: Icon(entry.value.$1),
  )).toList();
  // return [for ((key, value) in get_screens())
  //   ElevatedButton(
  //     onPressed : () => Navigator.pushNamed(key),
  //     child: const Icon(value[0]),
  // )];
}




