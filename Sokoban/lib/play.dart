import 'dart:convert';
import 'levelfile.dart';
import 'menu.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:path/path.dart' as pathLib;


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joystick/joystick.dart';

const double BoxDimensions = 50.0;
const double PixDimensions = 3.0;

var case_caisseV = Block(['sol.png','caisseV.png']);
var case_caisse = Block(['sol.png','caisse.png']);

var playerH = Block(['haut_0.png']);
var playerB = Block(['bas_0.png']);
var playerG = Block(['gauche_0.png']);
var playerD = Block(['droite_0.png']);

class Entities {
  Level? level;
  List<Box> boxes = [];
  Player? player;

  int nbTargets = 0;
  int nbTargetsChecked = 0;

  List<List<Box>> boxHistory = [];
  List<Player> playerHistory = [];

  Entities(this.level);

  FetchEntities(){

    int rowNber = 0;

    nbTargets = 0;
    nbTargetsChecked = 0;

    boxes = [];
    boxHistory = [];
    playerHistory = [];

    for (var line in level!.map!){

      for (int i in List<int>.generate(line.length, (j) => j)){
        String char = line[i];

        if (char == '\$') boxes.add(Box(i, rowNber, false));
        if (char == '@') player = Player(i, rowNber, playerB);
        if (char == '.') nbTargets++;
      }

      rowNber++;
    }

  }

  TryGo(List<int> dir){
    int new_x = player!.x! + dir[0];
    int new_y = player!.y! + dir[1];

    if (level!.map![new_y][new_x] == '#') return;

    SaveState();

    for (var box in boxes){
      if (box.x == new_x && box.y == new_y){

        if (level!.map![new_y + dir[1]][new_x + dir[0]] == '#') return;

        for (var boxBis in boxes) if (boxBis.x == new_x + dir[0] && boxBis.y == new_y + dir[1]) return;

        if (level!.map![new_y][new_x] == '.'){
          nbTargetsChecked--;
          box.isChecked = false;
        }

        if (level!.map![new_y + dir[1]][new_x + dir[0]] == '.') {
          nbTargetsChecked++;
          box.isChecked = true;
        }

        boxes[boxes.indexOf(box)] = Box(new_x + dir[0], new_y + dir[1], box.isChecked!);

        break;
      }
    }

    Block sprite = dir[0] == 0 ? (dir[1] == 1 ? playerB : playerH) : (dir[0] == 1 ? playerD : playerG);

    player = Player(new_x, new_y, sprite);
  }

  SaveState() async{
    if(boxHistory.length ==99){
      boxHistory.removeAt(0);
      playerHistory.removeAt(0);
    }
    boxHistory.add(new List<Box>.from(boxes));
    playerHistory.add(player!);

    final data = [
      level,
      boxHistory.map((boxList) => boxList.map((box) => box.toJson()).toList()).toList(),
      {
        'x': player!.x,
        'y': player!.y,
        'sprite': player!.sprite?.toJson(),
      },
    ];

    final jsonString = jsonEncode(data);

    final file = File('C:/Users/Gabriel/Documents/GitHub/sokoban/Sokoban/assets/lastlevel.json);');
    await file.writeAsString(jsonString);
    print("Ecriture terminer");

  }

  UndoState(){
    if (boxHistory.length < 1 || playerHistory.length < 1) return;

    boxes = boxHistory[boxHistory.length - 1];
    boxHistory.removeLast();

    nbTargetsChecked = 0;
    for (var box in boxes) if (box.isChecked!) nbTargetsChecked++;

    player = playerHistory[playerHistory.length - 1];
    playerHistory.removeLast();

  }
}

class Player extends StatelessWidget {
  int? x;
  int? y;
  Block? sprite;

  Player(this.x,this.y, this.sprite);

  @override
  Widget build(BuildContext context){

    return AnimatedPositioned(
      child: sprite!,
      duration: Duration(milliseconds: 100),
      left: BoxDimensions*x!.toDouble(),
      top: BoxDimensions*y!.toDouble(),
    );
  }
}

class Box extends StatelessWidget {
  int? x;
  int? y;
  bool? isChecked;

  Box(this.x,this.y, this.isChecked);

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'isChecked': isChecked,
    };
  }
  @override
  Widget build(BuildContext context){
    return AnimatedPositioned(
      child: isChecked! ? case_caisseV : case_caisse,
      duration: Duration(milliseconds: 100),
      left: BoxDimensions*x!.toDouble(),
      top: BoxDimensions*y!.toDouble(),
    );
  }

}