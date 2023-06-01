import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joystick/joystick.dart';

const double BoxDimensions = 50.0;
const double PixDimensions = 3.0;

var spriteNames = {
  '#':case_bloc,
  ' 0':case_vide,
  ' ':case_sol,
  '.':case_cible,
};

var pixelColor = {
  '#':Colors.red,
  ' ':Colors.grey,
  '.':Colors.white70,
  '\$':Colors.deepOrange,
  '@':Colors.green,
  '0':null,
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

enum Window {Main, LevelSelector, Game, GameMenu}

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

  SaveState(){
    boxHistory.add(new List<Box>.from(boxes));
    playerHistory.add(player!);
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

class Menu extends StatelessWidget {
  bool isMain = true;
  final Play;
  final Select;

  Menu(this.isMain, this.Play, this.Select);

  @override
  Widget build(BuildContext context){

    bool loaded = false;

    return Column(children: [
      Text(isMain ? "SOKOBAN" : "Menu", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 50.0),),
      Container(
        margin: EdgeInsets.fromLTRB(0,40.0,0,20.0),
        width: 150.0,
        height: 50.0,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), border: Border.all(color: Colors.white)),
        child: InkWell(onTap: () {Play(isMain?0:-1);},child: Text(isMain?"PLAY":"Retry", textAlign: TextAlign.center,style: TextStyle(color: Colors.white, fontSize: 35.0)),),
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool loading = true;
  int levelNumber = 0;
  Window currentWindow = Window.Main;

  Widget mainWidget = CircularProgressIndicator();
  Text bannerText = Text("Sokoban | Main Menu");

  Levels niveaux = new Levels();
  LevelBuilder lvlBuilder = new LevelBuilder(null);
  Entities e = new Entities(null);

  _MyHomePageState(){
    niveaux.loadLevels().then((value) => setState((){

      lvlBuilder = LevelBuilder(niveaux.levels![levelNumber]);
      e = Entities(niveaux.levels![levelNumber]);
      e.FetchEntities();

      mainWidget = Menu(true, Play, Select);

      loading = false;
    }));
  }
  
  WindowSwitcher(Window mode){
    
    switch(mode){
      
      case Window.Main:
        
        mainWidget = Menu(true, Play, Select);
        bannerText = Text("Sokoban | Main Menu");
        break;
        
      case Window.LevelSelector:

        mainWidget = SingleChildScrollView(child: LevelSelector(niveaux, Play));
        bannerText = Text("Sokoban | Level Selection ");
        break;
        
      case Window.Game:

        mainWidget = SingleChildScrollView(
            child : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Stack(children: [
                  lvlBuilder,
                  e.player!,
                ]+e.boxes)
            )
        );
        bannerText = Text("Sokoban | Level "+ (levelNumber + 1).toString());
        break;
        
      case Window.GameMenu:

        mainWidget = Menu(false, Play, Select);
        break;
    }
    currentWindow = mode;
  }
  
  Play(int levelNum){

    if (levelNum != -1){
      levelNumber = levelNum;

      lvlBuilder = LevelBuilder(niveaux.levels![levelNumber]);
      e = Entities(niveaux.levels![levelNumber]);
    }

    e.FetchEntities();
    
    WindowSwitcher(Window.Game);

    setState(() {});
  }

  Select(){
    WindowSwitcher(Window.LevelSelector);
    setState(() {});
  }

  checkFinish() {
    if (e.nbTargets != e.nbTargetsChecked) return;

    loading = true;

    levelNumber++;

    bannerText = Text("Sokoban | Level "+ (levelNumber + 1).toString());
    lvlBuilder = LevelBuilder(niveaux.levels![levelNumber]);
    e = Entities(niveaux.levels![levelNumber]);
    e.FetchEntities();

    loading = false;
  }

  UpdateGame(List<int> dir, bool mustUndo){
    if (mustUndo) e.UndoState();
    else e.TryGo(dir);
    checkFinish();
    mainWidget = SingleChildScrollView(
        child : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Stack(children: [
              lvlBuilder,
              e.player!,
            ]+e.boxes)
        )
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        leading: (currentWindow == Window.Game) ? IconButton(onPressed: (){WindowSwitcher(Window.GameMenu);setState(() {});}, icon: const Icon(Icons.menu),) : Container(),
        title: bannerText,
        actions: (currentWindow == Window.Game) ?
        [IconButton(onPressed: (){UpdateGame([],true);}, icon: const Icon(Icons.keyboard_backspace))] :
        ((currentWindow != Window.Main)?[IconButton(onPressed: (){WindowSwitcher(Window.Main);setState(() {});}, icon: const Icon(Icons.keyboard_backspace))]:[Container()])
      ),
      body: Center(
        child: loading ? CircularProgressIndicator() : mainWidget
      ),
      floatingActionButton: (currentWindow == Window.Game) ? Joystick(size: 100,
          opacity: 0.4,
          isDraggable: true,
          onUpPressed: (){UpdateGame([0, -1],false);},
          onDownPressed: (){UpdateGame([0, 1],false);},
          onLeftPressed: (){UpdateGame([-1, 0],false);},
          onRightPressed: (){UpdateGame([1, 0],false);},
        ) : null
    ); // This trailing comma makes auto-formatting nicer for build methods.
  }
}
