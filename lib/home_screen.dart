import 'package:flutter/material.dart';
import 'navigator.dart';
import 'data.dart';


// Function to, given a Dog entity, give widgets and a option to remove the entry using button
Widget dog_to_widget(Dog dog){
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children:[
      Container(padding: const EdgeInsets.all(10), child: Text("Id: ${dog.id}")),
      Expanded(child:Container(padding: const EdgeInsets.all(10), child: Text("Name: ${dog.name}"))),
      Container(padding: const EdgeInsets.all(10), child: Text("Age: ${dog.age}")),
      Container(padding: const EdgeInsets.all(10), child: ElevatedButton(
        child:Text("Delete"),
        onPressed:(){
          dogstore.remove(dog.id);
        }
    ))
    ]
  );
}

class HomeScreen extends StatelessWidget{
  const HomeScreen(title, {super.key}): this.title = title[0]+": Home";

  final String title;

  @override
  Widget build(BuildContext cxt){
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body : //Container(height: 50, child:Center(child:const Text("I'm from home"))),
      //FutureBuilder<List<String>> (
      StreamBuilder<List<Dog>> (
        //future: get_dogs(),
        stream: dogstore.subscribe(),
        builder: (cxt, snap){
          if(snap.connectionState == ConnectionState.waiting){
            return Column(children: [Expanded(child: CircularProgressIndicator()),
                Text("Awaiting database results...")]);
          }
          if(snap.hasData){
            return ListView(
              padding: const EdgeInsets.all(10),
              //children: snap.data!.map((dat) => Center(child:Text(dat.toString()))).toList(),
              children: snap.data!.map((dat) => Center(child:dog_to_widget(dat))).toList(),
            );
          }
          else if(snap.hasError){
            return Column(
              children:[
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Error: ${snap.error}'),
                ),
            ]);
          }
          else{
            return Column(
              children:[
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Some unknown error happened'),
                ),
            ]);
          }
      }),
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

class TheHomePage extends StatefulWidget{
  const TheHomePage({super.key, required this.title});

  final String title;

  @override
  State<TheHomePage> createState() => _TheHomePageState();

}

class _TheHomePageState extends State<TheHomePage>{

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

