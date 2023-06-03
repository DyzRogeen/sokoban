import 'dart:convert';
import 'levelfile.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joystick/joystick.dart';

const double PixDimensions = 3.0;


var pixelColor = {
  '#':Colors.red,
  ' ':Colors.grey,
  '.':Colors.white70,
  '\$':Colors.deepOrange,
  '@':Colors.green,
  '0':null,
};

class Menu extends StatelessWidget {
  bool isMain = true;
  final Play;
  final Select;
  final data;

  Menu(this.isMain, this.Play, this.Select, this.data);

  @override
  Widget build(BuildContext context){
    print(data[0]);

    bool loaded = false;

    return Column(children: [
      Text(isMain ? "SOKOBAN" : "Menu", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 50.0),),
      Container(
        margin: EdgeInsets.fromLTRB(0,40.0,0,20.0),
        width: 150.0,
        height: 50.0,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), border: Border.all(color: Colors.white)),
        child: InkWell(onTap: () {Play(isMain?data[0]:-1);},child: Text(isMain?"PLAY":"Retry", textAlign: TextAlign.center,style: TextStyle(color: Colors.white, fontSize: 35.0)),),
      ),
      Container(
        margin: EdgeInsets.all(20.0),
        width: 150.0,
        height: 50.0,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), border: Border.all(color: Colors.white)),
        child: InkWell(onTap: () {Select();},child: Text("Level\nSelection", textAlign: TextAlign.center,style: TextStyle(color: Colors.white, fontSize: 20.0)),),
      ),
    ]);
  }
}

class LevelSelector extends StatelessWidget{
  Levels? levels;
  final Play;

  LevelSelector(this.levels, this.Play);

  @override
  Widget build(BuildContext context){

    List<Container> levelBox = [];

    for(var level in levels!.levels!) levelBox.add(Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.white12),
        margin: EdgeInsets.all(10.0),
        padding: EdgeInsets.all(10.0),
        child: InkWell(onTap: (){Play(levels!.levels!.indexOf(level));},
            child: Row(children: [
              Container(margin: EdgeInsets.all(50.0),width: 120.0, height: 100, child: LevelOverview(level)),
              Text("Niveau "+(levelBox.length + 1).toString(), style: TextStyle(color: Colors.white, fontSize: 30.0)),
            ],))));

    return Column(children: levelBox,);
  }
}

class LevelOverview extends StatelessWidget{
  Level? level;

  LevelOverview(this.level);

  @override
  Widget build(BuildContext context){

    double lvlWidth = level!.largeur!.toDouble();
    double lvlHeight = level!.hauteur!.toDouble();
    double pixSize = 22.0 * PixDimensions / lvlHeight;

    List<Row>? rows = [];
    List<Container>? pixels;

    bool floorBegan;
    String char;
    int lastlength = level!.largeur!;

    for (var line in (level?.map)!){

      pixels = [];
      floorBegan = false;

      for (int i in List<int>.generate(level!.largeur!, (j) => j)){

        if (i == lastlength) floorBegan = false;

        if (i < line.length){
          char = line[i];

          if (!floorBegan && char == '#') floorBegan = true;
          else if (!floorBegan && char == ' ') char = '0';

          pixels.add(Container(width: pixSize, height: pixSize, color: pixelColor[char],));
        }
        else pixels.add(Container(width: pixSize, height: pixSize, color: pixelColor['0'],));

      }
      lastlength = line.length;

      rows?.add(Row(children: pixels,));

    }

    return Container(
        width: lvlWidth * PixDimensions,
        height: lvlHeight * PixDimensions,
        child: Column(children: rows!,)
    );
  }
}