import 'dart:convert';
import 'levelfile.dart';
import 'menu.dart';
import 'play.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joystick/joystick.dart';

int LastLevel = 0;
List<dynamic> tempboxHistory = [];
List<dynamic> tempplayerHistory = [];


enum Window {Main, LevelSelector, Game, GameMenu}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LoadpastLevel();
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
Future<void> LoadpastLevel() async {

  final String res = await rootBundle.loadString("./lastlevel.json");
  final data = await json.decode(res);

  LastLevel =data[0] ;
  tempboxHistory = data[1] ;
  tempplayerHistory = data[2] ;
  print(LastLevel);
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

      mainWidget = Menu(true, Play, Select, [0, [], []]);

      loading = false;
    }));
  }

  WindowSwitcher(Window mode){

    switch(mode){

      case Window.Main:

        mainWidget = Menu(true, Play, Select, [LastLevel, tempplayerHistory, tempboxHistory]);
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

        mainWidget = Menu(false, Play, Select,[0, [], []]);
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
        leading: (currentWindow == Window.Game)
            ? IconButton(
          onPressed: () {
            WindowSwitcher(Window.GameMenu);
            setState(() {});
          },
          icon: const Icon(Icons.menu),
        )
            : Container(),
        title: bannerText,
      ),
      body: Stack(
        children: [
          Center(child: loading ? CircularProgressIndicator() : mainWidget),
          if (currentWindow == Window.Game)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: IconButton(
                  onPressed: () {
                    UpdateGame([], true);
                  },
                  icon: const Icon(
                    Icons.keyboard_backspace,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (currentWindow == Window.Game)
          ? Joystick(
        size: 100,
        opacity: 0.4,
        isDraggable: true,
        onUpPressed: () {
          UpdateGame([0, -1], false);},
        onDownPressed: () {
          UpdateGame([0, 1], false);},
        onLeftPressed: () {
          UpdateGame([-1, 0], false);},
        onRightPressed: () {
          UpdateGame([1, 0], false);},
      )
          : null,
    );


  }
}
