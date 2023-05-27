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
var case_caisseV = Block(['sol.png','caisseV.png']);

var playerH = Block(['haut_0.png']);
var playerB = Block(['bas_0.png']);
var playerG = Block(['gauche_0.png']);
var playerD = Block(['droite_0.png']);

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

    nbTargets = 0;
    nbTargetsChecked = 0;

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

    print(nbTargetsChecked);
  }

}

class Box extends StatelessWidget {
  int? x;
  int? y;
  bool? isChecked;

  Box(this.x,this.y, this.isChecked);

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool loading = true;
  int levelNumber = 0;

  Levels niveaux = new Levels();
  LevelBuilder lvlBuilder = new LevelBuilder(null);
  Entities e = new Entities(null);

  _MyHomePageState(){
    niveaux.loadLevels().then((value) => setState((){

      lvlBuilder = LevelBuilder(niveaux.levels![levelNumber]);
      e = Entities(niveaux.levels![levelNumber]);
      e.FetchEntities();

      loading = false;
    }));
  }

  checkFinish() {
    if (e.nbTargets != e.nbTargetsChecked) return;

    loading = true;

    levelNumber++;

    lvlBuilder = LevelBuilder(niveaux.levels![levelNumber]);
    e = Entities(niveaux.levels![levelNumber]);
    e.FetchEntities();

    setState((){});

    loading = false;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: loading ? CircularProgressIndicator() : Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          reverse: true,
          child : Stack(children: [
            lvlBuilder,
            e.player!,
          ]+e.boxes)
        )
      ),
      floatingActionButton: Joystick(size: 100,
        opacity: 0.4,
        isDraggable: true,
        onUpPressed: (){e.TryGo([0, -1]);checkFinish();setState(() {});},
        onDownPressed: (){e.TryGo([0, 1]);checkFinish();setState(() {});},
        onLeftPressed: (){e.TryGo([-1, 0]);checkFinish();setState(() {});},
        onRightPressed: (){e.TryGo([1, 0]);checkFinish();setState(() {});},
      ),
    ); // This trailing comma makes auto-formatting nicer for build methods.
  }
}
