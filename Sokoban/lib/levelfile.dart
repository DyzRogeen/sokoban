import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joystick/joystick.dart';

const double BoxDimensions = 50.0;

var spriteNames = {
  '#':case_bloc,
  ' 0':case_vide,
  ' ':case_sol,
  '.':case_cible,
  '*':case_trou,
};


var case_bloc = Block(['sol.png','bloc.png']);
var case_cible = Block(['sol.png','cible.png']);
var case_sol = Block(['sol.png']);
var case_vide = Block([]);
var case_trou = Block(['trou.png']);



class Level {
  int? hauteur;
  int? largeur;
  List<List<String>>? map;
  Level(this.hauteur, this.largeur, this.map);
  Map<String, dynamic> toJson() {
    return {
      'hauteur': hauteur,
      'largeur': largeur,
      'map': map,
    };
  }
}


class Levels {
  List<Level>? levels;

  Future<void> loadLevels() async {
    levels = [];
    List<List<String>> map = [];

    final String res = await rootBundle.loadString("./levels.json");
    final data = await json.decode(res);

    for (var level in data) {
      var lines = level["lignes"];
      map = List.generate(lines.length, (i) => lines[i].toString().split(''));

      levels?.add(Level(level["hauteur"], level["largeur"], map));
    }
  }
}


class LevelBuilder extends StatelessWidget {
  Level? level;

  LevelBuilder(this.level);

  @override
  Widget build(BuildContext context){

    List<Row>? rows = [];
    List<Expanded>? blocks;

    bool floorBegan;
    String char;
    int lastlength = level!.largeur!;

    for (var line in (level?.map)!){

      blocks = [];
      floorBegan = false;

      for (int i in List<int>.generate(level!.largeur!, (j) => j)){

        if (i == lastlength) floorBegan = false;

        if (i < line.length){
          char = line[i];

          if (!floorBegan && char == '#') floorBegan = true;
          else if (!floorBegan && char == ' ') char = ' 0';
          else if (char == '@' || char == '\$') char = ' ';

          blocks.add(Expanded(child: spriteNames[char]!));
        }
        else blocks.add(Expanded(child: spriteNames[' 0']!));

      }
      lastlength = line.length;

      rows?.add(Row(children: blocks,));

    }

    return Container(
        width: level!.largeur!.toDouble() * BoxDimensions,
        height: level!.hauteur!.toDouble() * BoxDimensions,
        child: Column(children: rows!,)
    );
  }
}


class Block extends StatelessWidget {
  List<String?> spriteName;

  Block(this.spriteName);

  Map<String, dynamic> toJson() {
    return {
      'spriteName': spriteName,
    };
  }

  @override
  Widget build(BuildContext context){

    List<Image>? imgs = [];

    for (var name in spriteName){
      imgs!.add(Image(image: AssetImage("sprites/" + name!), width: BoxDimensions, height: BoxDimensions,),);
    }

    return Container(
      width: BoxDimensions,
      height: BoxDimensions,
      child: Stack(children: imgs!),
    );

  }
}