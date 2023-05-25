import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joystick/joystick.dart';

const double BoxDimensions = 50.0;

var spriteNames = {
  '#':case_bloc,
  ' 0':case_vide,
  ' ':case_sol,
  '.':case_cible,
};

var case_bloc = Block(['sol.png','bloc.png']);
var case_cible = Block(['sol.png','cible.png']);
var case_sol = Block(['sol.png']);
var case_vide = Block([]);
var case_caisse = Block(['sol.png','caisse.png']);

var playerH0 = Block(['haut_0.png']);
var playerH1 = Block(['haut_1.png']);
var playerH2 = Block(['haut_2.png']);
var playerB0 = Block(['bas_0.png']);
var playerB1 = Block(['bas_1.png']);
var playerB2 = Block(['bas_2.png']);
var playerG0 = Block(['gauche_0.png']);
var playerG1 = Block(['gauche_1.png']);
var playerG2 = Block(['gauche_2.png']);
var playerD0 = Block(['droite_0.png']);
var playerD1 = Block(['droite_1.png']);
var playerD2 = Block(['droite_2.png']);

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
  List<List<String>>? map;
  Level(this.hauteur, this.largeur, this.map);
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

class Block extends StatelessWidget {
  List<String?> spriteName;

  Block(this.spriteName);

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

class LevelBuilder extends StatelessWidget {
  Level? level;

  LevelBuilder(this.level);

  @override
  Widget build(BuildContext context){

    List<Row>? rows = [];
    List<Expanded>? blocks;

    bool floorBegan;
    List<String> chars;
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
      color: Colors.black54,
      width: level!.largeur!.toDouble() * 50.0,
      height: level!.hauteur!.toDouble() * 50.0,
      child: Column(children: rows!,)
    );
  }
}

class Entities {
  Level? level;
  List<Box> boxes = [];
  Player? player;

  int nbTargets = 0;
  int nbTargetsChecked = 0;

  Entities(this.level);

  FetchEntities(){

    int rowNber = 0;
    List<String> chars;

    nbTargets = 0;
    nbTargetsChecked = 0;

    for (var line in level!.map!){

      for (int i in List<int>.generate(line.length, (j) => j)){
        String char = line[i];

        if (char == '\$') boxes.add(Box(i, rowNber));
        if (char == '@') player = Player(i, rowNber);
        if (char == '.') nbTargets++;
      }

      rowNber++;
    }

  }

  TryGo(List<int> dir){
    int new_x = player!.x! + dir[0];
    int new_y = player!.y! + dir[1];

    if (level!.map![new_y][new_x] == '#') return;

    for (var box in boxes){
      if (box.x == new_x && box.y == new_y){

        if (level!.map![new_y + dir[1]][new_x + dir[0]] == '#') return;

        for (var boxBis in boxes) if (boxBis.x == new_x + dir[0] && boxBis.y == new_y + dir[1]) return;

        if (level!.map![new_y + dir[1]][new_x + dir[0]] == '.') nbTargetsChecked++;

        boxes[boxes.indexOf(box)] = Box(new_x + dir[0], new_y + dir[1]);

        break;
      }
    }

    if (level!.map![new_y][new_x] == '.') nbTargetsChecked--;

    player = Player(new_x, new_y);
  }

}

class Box extends StatelessWidget {
  int? x;
  int? y;

  Box(this.x,this.y);

  @override
  Widget build(BuildContext context){
    return AnimatedPositioned(
      child: case_caisse,
      duration: Duration(milliseconds: 100),
      left: BoxDimensions*x!.toDouble(),
      top: BoxDimensions*y!.toDouble(),
    );
  }

}

class Player extends StatelessWidget {
  int? x;
  int? y;
  Block sprite = playerB0;

  Player(this.x,this.y);

  @override
  Widget build(BuildContext context){

    return AnimatedPositioned(
      child: sprite,
      duration: Duration(milliseconds: 100),
      left: BoxDimensions*x!.toDouble(),
      top: BoxDimensions*y!.toDouble(),
    );
  }

}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool loading = true;

  Levels niveaux = new Levels();
  LevelBuilder lvlBuilder = new LevelBuilder(null);
  Entities e = new Entities(null);

  _MyHomePageState(){
    niveaux.loadLevels().then((value) => setState((){

      lvlBuilder = LevelBuilder(niveaux.levels![0]);
      e = Entities(niveaux.levels![0]);
      e.FetchEntities();

      loading = false;
    }));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: loading ? CircularProgressIndicator() : Center(
        child: SingleChildScrollView(
          child : Stack(children: [
            lvlBuilder,
            e.player!,
            Positioned(
                top: 400.0,
                left: 500.0,
                child: Container(
                    width: 100.0,
                    height: 100.0,
                    child: Joystick(size: 100,
                      opacity: 0.4,
                      isDraggable: false,
                      onUpPressed: (){e.TryGo([0, -1]);setState(() {});},
                      onDownPressed: (){e.TryGo([0, 1]);setState(() {});},
                      onLeftPressed: (){e.TryGo([-1, 0]);setState(() {});},
                      onRightPressed: (){e.TryGo([1, 0]);setState(() {});},
                    ))),
          ]+e.boxes)
        )
      )
    ); // This trailing comma makes auto-formatting nicer for build methods.
  }
}
