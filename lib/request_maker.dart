import 'file_picking.dart';
import 'openapi_loader.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart';

enum RequestUnitType {
  string,
  integer,
  decimal,
  video,
}

// Represents a abstract class that is supposed to return the value or widget
abstract class _BaseRequestUnit{
  //const _BaseRequestUnit({required this.name, this.can_be_null=true});
  _BaseRequestUnit({required this.name, this.can_be_null=true});
  final bool can_be_null;
  final String name;
  dynamic? get value;
  Widget get widget;
}
typedef RequestInputType = ({String field_name, RequestUnitType type, bool nullable});
class RequestObject extends StatefulWidget{
  
  RequestObject({required this.base_builder, required this.endpoint, required this.request_fields, this.on_submit, super.key}){
    print(">>>>>>>> Current task fields are now : ${request_fields}");
    _request_objs = request_fields.map(
      (field){
        return switch(field.type){
          RequestUnitType.string => _StrRequestUnit(name: field.field_name, can_be_null: field.nullable),
          RequestUnitType.integer => _IntRequestUnit(name: field.field_name, can_be_null: field.nullable),
          RequestUnitType.decimal => _DoubleRequestUnit(name: field.field_name, can_be_null: field.nullable),
          RequestUnitType.video => _VideoRequestUnit(name: field.field_name, can_be_null: field.nullable),
        };
    }).toList();
  }
  final Future<void> Function(http.Response)? on_submit;
  final String endpoint;
  final String Function() base_builder;
  List<RequestInputType> request_fields;
  // fkit we saving state in the root of the class now
  List<_BaseRequestUnit> _request_objs = [];

  @override
  State<RequestObject> createState() => _RequestObjectState();
}

class _RequestObjectState extends State<RequestObject>{
  final _formKey = GlobalKey<FormState>();
  
  @override
  void initState(){
    super.initState();
    
  }
  
  @override
  Widget build(BuildContext ctx){
    return Form(
      key: _formKey,
      child: Column(
        
        children:<Widget>[
          Text("Endpoint : ${widget.endpoint}"),
          ...widget._request_objs.map((obj)=>obj.widget),
          ElevatedButton(
            child:const Text("Send Request"),
            onPressed:() async{
              if(_formKey.currentState!.validate()){
                // Submit as the form
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text("Yes, the request is goiing to be submitted to ${widget.base_builder()}/${widget.endpoint}"),
                    backgroundColor: Colors.blue,
                  )
                );
                // TODO:: Need to send the things to submission

                var uri = Uri.parse("${widget.base_builder()}/${widget.endpoint}");
                //Fill non video parameters
                bool has_files = false;
                Map<String, String> fmap = {};
                for (int i = 0; i < widget._request_objs.length; ++i){
                  final spec = widget.request_fields[i];
                  final obj = widget._request_objs[i];
                  if((spec.type == RequestUnitType.video) && (obj.value != null)){
                    has_files = true;
                  }
                  else{
                    if(obj.value != null){
                      final v = obj.value!.toString();
                      fmap[spec.field_name]=v;
                    }
                  }
                }
                uri=uri.replace(queryParameters: fmap);

                if(has_files){
                  var request = http.MultipartRequest('POST', uri);
                  for (int i = 0; i < widget._request_objs.length; ++i){
                    final spec = widget.request_fields[i];
                    final obj = widget._request_objs[i];
                    // TODO:: Support bytestream also
                    if((spec.type == RequestUnitType.video) && (obj.value != null)){
                      request.files.add(await http.MultipartFile.fromPath(
                          spec.field_name,
                          obj.value!.path,
                          //contentType: MediaType('video', 'mp4')));
                          contentType: MediaType.parse(lookupMimeType(obj.value!.path)??"video/mp4"))) ;
                    }
                  }

                  var streamedResponse = await request.send();
                  var response = await http.Response.fromStream(streamedResponse);

                  if(widget.on_submit != null){
                    widget.on_submit!(response);
                  }

                }
                else{
                  var request = http.Request('POST', uri);
                  var streamedResponse = await request.send();
                  var response = await http.Response.fromStream(streamedResponse);

                  if(widget.on_submit != null){
                    widget.on_submit!(response);
                  }
                }
              }
            }
          ),
        ],
      )
    );
  }
}


class _StrRequestUnit extends _BaseRequestUnit{
  final TextEditingController _controller = TextEditingController();
  _StrRequestUnit({required String name, required bool can_be_null}):super(name: name, can_be_null:can_be_null);
  @override
  String? get value{
    return _controller.text.isNotEmpty ? _controller.text: null;
  }
  @override
  Widget get widget{
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(labelText: super.name),
      validator: (value) {
        if(!can_be_null && (value == null || value.isEmpty)){
          return "Field cannot be empty";
        }
        return null;
      }
    );
  }
}

class _IntRequestUnit extends _BaseRequestUnit{
  final TextEditingController _controller = TextEditingController();
  _IntRequestUnit({required String name, required bool can_be_null}):super(name: name, can_be_null:can_be_null);
  @override
  int? get value{
    try{
      return int.parse(_controller.text);
    } catch(e){
      return null;
    }
  }
  @override
  Widget get widget{
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(labelText: super.name),
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly
      ], // Only allow digits
      validator: (value) {
        if(value == null || value.isEmpty) {
          if (!can_be_null){
            return "Field cannot be empty";
          }
          return null;
        }
        if (int.tryParse(value) == null) {
          return 'Invalid integer';
        }
        return null;
      },
    );
  }
}

class _DoubleRequestUnit extends _BaseRequestUnit{
  final TextEditingController _controller = TextEditingController();
  _DoubleRequestUnit({required String name, required bool can_be_null}):super(name: name, can_be_null:can_be_null);
  @override
  double? get value{
    try{
      return double.parse(_controller.text);
    } catch(e){
      return null;
    }
  }
  @override
  Widget get widget{
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(labelText: super.name),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
            try {
              final text = newValue.text;
              if (text.isNotEmpty) double.parse(text);
              return newValue;
            } catch (e) {
              return oldValue;
            }
        }),
      ],
      validator: (value) {
        if(value == null || value.isEmpty) {
          if (!can_be_null) {
            return "Field cannot be empty";
          }
          return null;
        }
        if (double.tryParse(value) == null) {
          return 'Invalid double';
        }
        return null;
      },
    );
  }
}

class _VideoRequestUnit extends _BaseRequestUnit{
  final _filePicking = FilePickerService();
  _VideoRequestUnit({required String name, required bool can_be_null}):super(name: name, can_be_null:can_be_null);
  File? _file;
  @override
  File? get value{
    return _file;
  }
  @override
  Widget get widget{
    return FormField<File>(
      validator: (File? file){
        if(!can_be_null && (file == null)){
          return "Field cannot be empty";
        }
        // Maybe add other size restrictions
      },
      builder: (FormFieldState<File> state){
        return Row(
          children:<Widget>[
            //TODO:: insert padding
            Text(super.name+" : "),
        
            (_file != null)?
            Text(_file!.path)
            :const SizedBox.shrink(),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async{
                final file = await _filePicking.pickVideoFile();
                if (file != null) {
                  state.didChange(file);
                  _file=file;
                  //setState(()=>_file=file);
                  //setState(()=>{});
                }
              },
              child: const Text('Pick Video File'),
            ),
        
            (_file != null)?ElevatedButton(
              onPressed: () async{
                state.didChange(null);
                _file=null;
                //setState(()=>_file=null);
                //setState(()=>{});
              },
              child: const Text('Clear'),
            ):const SizedBox.shrink(),
        ]);
      }
    );
  }
}
