import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

var spriteNames = {
  '#':case_bloc,
  ' 0':case_vide,
  ' 1':case_sol,
  '@':case_player,
  '\$':case_caisse,
  '.':case_cible,
};

var case_bloc = Block(['sol.png','bloc.png']);
var case_cible = Block(['sol.png','cible.png']);
var case_sol = Block(['sol.png']);
var case_vide = Block(['vide.png']);
var case_caisse = Block(['caisse.png']);
var case_player = Block(['caisse.png']);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sokoban',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Sokoban'),
    );
  }
}

class Level {
  int? hauteur;
  int? largeur;
  List<String>? map;
  Level(this.hauteur, this.largeur, this.map);
}

class Levels {
  List<Level>? levels;

  Future<void> loadLevels() async{
    levels = [];

    final String res = await rootBundle.loadString("./levels.json");
    final data = await json.decode(res);

    for (var level in data){
      levels?.add(Level(level.hauteur, level.largeur, level.lignes));
    }

  }

}

class Block extends StatelessWidget {
  List<String?> spriteName;

  Block(this.spriteName);

  @override
  Widget build(BuildContext context){

    List<Image>? imgs;

    for (var name in spriteName){
      imgs!.add(Image(image: AssetImage("sprites/" + name!), width: 50, height: 50,),);
    }

    return Container(
      width: 50.0,
      height: 50.0,
      child: Stack(children: imgs!),
    );

  }
}

class LevelBuilder extends StatelessWidget {
  Level? level;

  LevelBuilder(this.level);

  @override
  Widget build(BuildContext context){

    List<Row>? rows;
    List<Block>? blocks;

    for (var line in (level?.map)!){
      blocks = [];
      for (var char in line.split('')){
        blocks.add(spriteNames[char]!);
      }
    }

    return Container();
  }

}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Levels niveaux = new Levels();

  _MyHomePageState(){
    niveaux.loadLevels().then((value) => setState((){}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
