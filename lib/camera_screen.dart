import 'package:flutter/material.dart';
import 'navigator.dart';
import 'data.dart';
import 'cam_cntrl.dart';

class CameraScreen extends StatelessWidget{
  const CameraScreen(title, {super.key}): this.title = title[0]+": Camera";

  final String title;

  @override
  Widget build(BuildContext cxt){
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body : //Container(height: 50, child:Center(child:const Text("I'm from camera"))),
      //FutureBuilder<List<String>> (
      //StreamBuilder<List<Dog>> (
      //  //future: get_dogs(),
      //  stream: dogstore.subscribe(),
      //  builder: (cxt, snap){
      //    if(snap.hasData){
      //      return ListView(
      //        padding: const EdgeInsets.all(8),
      //        children: snap.data!.map((dat) => Center(child:Text(dat.toString()))).toList(),
      //      );
      //    }
      //    else if(snap.hasError){
      //      return Column(
      //        children:[
      //          const Icon(
      //            Icons.error_outline,
      //            color: Colors.red,
      //            size: 60,
      //          ),
      //          Padding(
      //            padding: const EdgeInsets.only(top: 16),
      //            child: Text('Error: ${snap.error}'),
      //          ),
      //      ]);
      //    }
      //    else{
      //      return Column(children: [Expanded(child: CircularProgressIndicator()),
      //          Text("Awaiting database results...")]);
      //    }
      //}),
      CameraBox(),
      persistentFooterButtons: [Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: get_buttons(cxt),
    )]
    );
  }
}



class ContentGenerator {
  final List<Widget> items;

  ContentGenerator({required this.items});

  Widget get_item(BuildContext cxt, int inx){
    return items[inx % items.length];
  }
}

class TheCameraPage extends StatefulWidget{
  const TheCameraPage({super.key, required this.title});

  final String title;

  @override
  State<TheCameraPage> createState() => _TheCameraPageState();

}

class _TheCameraPageState extends State<TheCameraPage>{

  late final ContentGenerator _genr;

  @override
  void initState(){
    _genr = ContentGenerator(items:[
        Container(height: 100, child: Center(child: const Text("Hello and Aloha"))),
        Container(height: 100, child: Center(child: const Text("Hello and Hoso"))),
        Container(height: 100, child: Center(child: const Text("Hoso and Aloha"))),
    ]);
    super.initState();
  }

  @override
  void dispose(){
    super.dispose();
  }
  
  @override
  Widget build(BuildContext cxt){
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body : Column(
        //constraints: BoxConstraints.expand()
        //height: double.infinity,
        children:[
          Container(height: 50, child: ElevatedButton(
              onPressed:() => Navigator.pushNamed(cxt, '/another'),
              child:Text("Go on"))),
          Container(height: 50, child:Center(child:const Text("I'm From above"))),
          Expanded(
          child:ListView.builder(
            itemBuilder: _genr.get_item,
      ))],
      )
    );
  }
}


// class CameraScreen extends StatelessWidget{
//   const CameraScreen(title, {super.key}): this.title = title[0]+": Camera";

//   final String title;

//   @override
//   Widget build(BuildContext cxt){
//     return Scaffold(
//       appBar: AppBar(title: Text(title)),
//       body : Container(height: 50, child:Center(child:const Text("I'm from camera"))),
//       persistentFooterButtons: [Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: get_buttons(cxt),
//       )],
//     );
//   }
// }
