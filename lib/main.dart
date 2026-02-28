import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:marquee/marquee.dart';
import 'package:permission_handler/permission_handler.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: Home()));
}

class _HomeState extends State<Home> {
  List<AppInfo> _installedApps = [];
  final List<AppInfo> _filteredApps = [];
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _musicsearchController = TextEditingController();
  String _currentSong = "System Idle";

  bool _isSearching = false;

  List<String> quotes = [
    "भाग्य उनका साथ देता है जो कठिन परिस्थितियों में भी अपने लक्ष्य के प्रति अडिग रहते हैं।", // Luck favors the persistent.
    "आलस्य में दरिद्रता का वास होता है, और प्रयास में सफलता का।", // Poverty lives in laziness; success in effort.
    "एक बार काम शुरू करने के बाद, असफलता से डरो मत और उसे छोड़ो मत।", // Once started, don't fear failure or abandon it.
    "बिना अभ्यास के ज्ञान विष के समान है।", // Knowledge without practice is like poison.
    "संकट आने से पहले ही उससे सावधान रहना चाहिए, और आने पर उस पर प्रहार कर उसे नष्ट कर देना चाहिए।", // Attack fear when it nears.
    "दूसरों की गलतियों से सीखें, आप खुद सारी गलतियां करने के लिए पर्याप्त लंबे समय तक नहीं जी सकते।", // Learn from others' mistakes.
    "जो व्यक्ति अपना लक्ष्य निर्धारित नहीं कर सकता, वह कभी विजयी नहीं हो सकता।", // One without goals cannot win.
    "ऋण, शत्रु और रोग को कभी छोटा नहीं समझना चाहिए, इन्हें जड़ से समाप्त करना ही उचित है।", // Don't underestimate debt, enemies, or disease.
    "मनुष्य अपने कर्मों से महान बनता है, अपने जन्म से नहीं।", // Greatness comes from deeds, not birth.
  ];
  int _selectedQuote = 0;
  int _quoteSecondsCounter = 0;

  bool isRepeat = false;

  Future<void> _readPlayerStatus() async {
    try {
      final file = File('/storage/emulated/0/spci_status.txt');
      if (await file.exists()) {
        final song = await file.readAsString();
        // Only update state if the text actually changed (saves battery)
        if (mounted && song.trim() != _currentSong) {
          setState(() {
            _currentSong = song.trim();
            // Add this near your other variables
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      // Fail silently if file is busy
    }
  }

  Future<void> _clearStaleCommands() async {
    final file = File('/storage/emulated/0/launcher_cmd.txt');
    try {
      if (await file.exists()) {
        await file.delete();
        print("Purple Team Protocol: Stale command file purged.");
      }
    } catch (e) {
      // Logic: If this fails, it's likely because permissions aren't granted yet.
      // We fail silently so the app still launches smoothly.
      print("Startup Cleanup Skipped: Storage permission missing.");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchInstalledApps();
    _clearStaleCommands();
    // Logic: Re-run every second to keep time accurate
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
        _quoteSecondsCounter++;
        if (_quoteSecondsCounter >= 20) {
          int nextQuote;
          do {
            nextQuote = Random().nextInt(quotes.length);
          } while (nextQuote ==
              _selectedQuote); // Keep picking if it's the same one

          _selectedQuote = nextQuote;
          _quoteSecondsCounter = 0;
        }
      });
      _readPlayerStatus();
    });
  }

  Future<void> _fetchInstalledApps() async {
    final apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      excludeNonLaunchableApps: true,
      withIcon: true,
    );
    setState(() {
      _installedApps = apps;
    });
  }

  // Logic: Writes commands to the shared file
  Future<void> _sendMusicCommand(String cmd) async {
    // 1. Logic: Check if we have "Manage External Storage" permission
    var status = await Permission.manageExternalStorage.status;

    // 2. Logic: If not granted, request it
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    // 3. Logic: If STILL not granted, send user to settings
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Permission Required: Enable 'All Files Access'"),
          action: SnackBarAction(
            label: 'SETTINGS',
            onPressed: openAppSettings, // Opens the specific settings page
          ),
        ),
      );
      return;
    }

    // 4. Logic: Permission is good! Write the file.
    try {
      final file = File('/storage/emulated/0/launcher_cmd.txt');
      await file.writeAsString(cmd);
    } catch (e) {
      print("File Error: $e");
    }
  }

  @override
  void dispose() {
    _timer.cancel(); // Logic: Important to prevent memory leaks!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents the back button from closing the launcher
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Logic: If you have a sidebar or bottom sheet open,
        // you could close it here instead of exiting.
      },

      child: Scaffold(
        backgroundColor: Colors.black,

        endDrawer: Drawer(
          backgroundColor: Colors.black, // Cyber-Security Aesthetic
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER
                Center(
                  child: Text(
                    "TERMINAL AUDIO",
                    style: GoogleFonts.orbitron(
                      color: Colors.lightGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 2. "NOW PLAYING" WIDGET (With Auto-Trim Logic)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      // Animated-style Icon
                      const Icon(
                        Icons.graphic_eq,
                        color: Colors.greenAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 15),

                      // LOGIC: Expanded forces text to stay inside width
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "NOW PLAYING",
                              style: GoogleFonts.firaCode(
                                color: Colors.grey,
                                fontSize: 10,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // The Song Name (Reads from your _currentSong variable)
                            Text(
                              _currentSong,
                              style: GoogleFonts.firaCode(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1, // Logic: Force single line
                              overflow: TextOverflow
                                  .ellipsis, // Logic: Trims with "..."
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 3. SONG INPUT FIELD
                Text(
                  " // COMMAND INPUT",
                  style: GoogleFonts.firaCode(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 10),
                TextField(
                  style: GoogleFonts.firaCode(color: Colors.white),
                  cursorColor: Colors.lightGreenAccent,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    hintText: "Type song name...",
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                    prefixIcon: const Icon(
                      Icons.terminal,
                      color: Colors.lightGreenAccent,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.green),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      // Logic: Sends "play [song name]" to your Python Bridge
                      setState(() => _isSearching = true);
                      _sendMusicCommand("play $value");
                      Navigator.pop(context); // Optional: Close drawer on enter
                    }
                  },
                ),

                const SizedBox(height: 30),

                // 4. CONTROL BUTTONS (Row)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // REPEAT TOGGLE (Green)
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.repeat,
                            color: isRepeat ? Colors.greenAccent : Colors.white,
                            size: 30,
                          ),
                          onPressed: () {
                            _sendMusicCommand("repeat");
                            setState(() {
                              isRepeat = !isRepeat;
                            });
                          },
                        ),
                        Text(
                          "LOOP",
                          style: GoogleFonts.firaCode(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),

                    // STOP / PAUSE (Red)
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.stop_circle,
                            color: Colors.redAccent,
                            size: 50,
                          ),
                          onPressed: () =>
                              _sendMusicCommand("stop"), // Sends Ctrl+C
                        ),
                        Text(
                          "STOP",
                          style: GoogleFonts.firaCode(
                            color: Colors.redAccent,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),

                    // KILL SESSION (Grey)
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.power_settings_new,
                            color: Colors.grey,
                            size: 30,
                          ),
                          onPressed: () =>
                              _sendMusicCommand("kill"), // Kills tmux session
                        ),
                        Text(
                          "KILL",
                          style: GoogleFonts.firaCode(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // 5. FOOTER STATUS
                Center(
                  child: Text(
                    "BRIDGE STATUS: ACTIVE [TMUX]",
                    style: GoogleFonts.firaCode(
                      color: Colors.greenAccent.withOpacity(0.5),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: GestureDetector(
            onTap: () {
              setState(() => _isSearching = true);
              _sendMusicCommand("play");
            },
            child: Container(
              // 1. Give the Master Pill a strict size so the AppBar doesn't crash
              height: 45,
              width:
                  MediaQuery.of(context).size.width *
                  0.65, // Takes up 65% of screen width safely
              decoration: BoxDecoration(
                color: Colors
                    .white, // Color goes INSIDE decoration if decoration is used!
                borderRadius: BorderRadius.circular(36),
              ),
              child: Row(
                children: [
                  // 2. THE BADGE (Nested inside the white pill with a nice margin)
                  Container(
                    margin: const EdgeInsets.all(
                      4,
                    ), // Gives it a nice gap from the edges
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "10",
                      style: GoogleFonts.firaCode(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // 3. THE MAIN STATUS AREA
                  // Because the parent Container has a strict width (65% of screen),
                  // Expanded is now 100% safe to use here.
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                      child: _isSearching
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SpinKitWave(
                                  color: Colors.black,
                                  size: 15.0,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "FETCHING...",
                                  style: GoogleFonts.doto(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            )
                          : ((_currentSong == "System Idle") ||
                                (_currentSong == "Offline") ||
                                (_currentSong == "Stopped"))
                          ? Center(
                              // Keeps text centered in the remaining space
                              child: Text(
                                "Hey There, Sir",
                                style: GoogleFonts.doto(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            )
                          : Marquee(
                              text: '$_currentSong ..... ',
                              style: GoogleFonts.doto(
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                              scrollAxis: Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              blankSpace: 40.0,
                              velocity: 50.0,
                              startPadding: 10.0,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.window, size: 32, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled:
                    true, // Logic: Allows the sheet to go full-screen
                backgroundColor: Colors.black, // Matches your tech theme
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (BuildContext context) {
                  // Logic: This is the actual Widget Builder
                  return SizedBox(
                    height:
                        MediaQuery.of(context).size.height *
                        0.8, // 80% of screen
                    child:
                        _buildAppList(), // Logic: Calling a separate UI builder function
                  );
                },
              );
            },
          ),
          actions: [
            Builder(
              builder: (context) {
                return IconButton(
                  icon: Icon(Icons.play_arrow_outlined, color: Colors.white),
                  onPressed: () {
                    // This 'context' now knows about the Scaffold
                    Scaffold.of(context).openEndDrawer();
                  },
                );
              },
            ),
          ],
        ),
        body: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          padding: const EdgeInsets.all(0),

          child: PageView(
            children: [
              // Page 1: Your Clock and Quotes
              Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    // 1. The Bottom Layer (Background)
                    Positioned.fill(
                      child: Opacity(
                        opacity:
                            0.5, // Logic: Makes background subtle so text is readable
                        child: Image.asset(
                          'assets/images/cmatrix.png',
                          fit: BoxFit
                              .cover, // Logic: Ensures it fills the whole background
                        ),
                      ),
                    ),

                    // 2. The Foreground Layer (Everything else)
                    // Wrap your Column in a Positioned.fill to ensure it has the same boundaries
                    Positioned.fill(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            ((_currentTime.hour + 11) % 12 + 1)
                                .toString()
                                .padLeft(2, '0'),
                            style: GoogleFonts.doto(
                              fontSize: 80,
                              height: 1,

                              fontWeight: FontWeight.w700,
                              color: Colors
                                  .white, // Logic: White is better for layered UIs
                              shadows: const [
                                Shadow(
                                  blurRadius: 15.0,
                                  color: Colors.white,
                                  offset: Offset(2, 2),
                                ),
                              ],
                              letterSpacing: 15,
                            ),
                          ),

                          Text(
                            _currentTime.minute.toString().padLeft(2, '0'),
                            style: GoogleFonts.doto(
                              fontSize: 80,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: Colors
                                  .white, // Logic: White is better for layered UIs
                              shadows: const [
                                Shadow(
                                  blurRadius: 15.0,
                                  color: Colors.white,
                                  offset: Offset(2, 2),
                                ),
                              ],
                              letterSpacing: 15,
                            ),
                          ),
                          Text(
                            _currentTime.hour >= 12 ? 'pm' : 'am',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: Colors
                                  .white, // Logic: White is better for layered UIs
                              shadows: const [
                                Shadow(
                                  blurRadius: 15.0,
                                  color: Colors.white,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.all(
                              10,
                            ), // Use EdgeInsets.all
                            child: AnimatedTextKit(
                              // Removed 'const' here
                              key: ValueKey(_selectedQuote),
                              animatedTexts: [
                                FadeAnimatedText(
                                  quotes[_selectedQuote],
                                  textStyle: GoogleFonts.tiroDevanagariHindi(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.end,
                                  duration: const Duration(seconds: 5),
                                  fadeOutBegin: 0.9,
                                  fadeInEnd: 0.1,
                                ),
                              ],
                              totalRepeatCount: 1,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Center(child: Text("S.I.D")),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppList() {
    if (_installedApps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        TextField(
          controller: _searchController,
          style: GoogleFonts.firaCode(color: Colors.black, fontSize: 17),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: "Search apps or web...",
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.black, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            suffix: IconButton(
              icon: const Icon(Icons.ac_unit, color: Colors.black, size: 20),
              onPressed: () {
                _searchController.clear();
              },
            ),
          ),
          onSubmitted: (value) {
            // Logic: Trigger your search function here
          },
        ),
        const SizedBox(height: 20),

        // LOGIC FIX: ValueListenableBuilder intercepts keystrokes in real-time
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              // 1. Get the current typed text
              final query = value.text.toLowerCase().trim();

              // 2. Filter the master list locally right before drawing
              final currentFilteredApps = _installedApps.where((app) {
                return app.name.toLowerCase().contains(query);
              }).toList();

              // 3. Handle the "Empty State" (No apps found)
              if (currentFilteredApps.isEmpty) {
                return Center(
                  child: Text(
                    "No binary found. Search Web?",
                    // Made it white so you can actually see it on the black bottom sheet!
                    style: GoogleFonts.inconsolata(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                );
              }

              // 4. Draw the List using the newly filtered array
              return ListView.builder(
                itemCount:
                    currentFilteredApps.length, // Logic: Use real-time length
                itemBuilder: (context, index) {
                  final app =
                      currentFilteredApps[index]; // Logic: Use real-time item

                  // YOUR EXACT LIST TILE AND DIALOG LOGIC REMAINS INTACT BELOW
                  return ListTile(
                    leading: app.icon != null
                        ? Image.memory(app.icon!, width: 40)
                        : const Icon(Icons.android, color: Colors.green),
                    title: Text(
                      app.name,
                      style: GoogleFonts.firaCode(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () => InstalledApps.startApp(app.packageName),
                    onLongPress: () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text(
                          'App Action',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                          'What do you want to do with ${app.name}?',
                          textAlign: TextAlign.center,
                        ),
                        actions: [
                          Column(
                            children: [
                              TextButton(
                                onPressed: () =>
                                    InstalledApps.uninstallApp(app.packageName),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text("Uninstall"),
                              ),
                              const Divider(color: Colors.grey),
                              TextButton(
                                onPressed: () =>
                                    InstalledApps.openSettings(app.packageName),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text("App info"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
