import 'dart:async';
import 'dart:math';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

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
  List<AppInfo> _filteredApps = [];
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _fetchInstalledApps();

    // Logic: Re-run every second to keep time accurate
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
        _quoteSecondsCounter++;
        if (_quoteSecondsCounter >= 30) {
          int nextQuote;
          do {
            nextQuote = Random().nextInt(quotes.length);
          } while (nextQuote ==
              _selectedQuote); // Keep picking if it's the same one

          _selectedQuote = nextQuote;
          _quoteSecondsCounter = 0;
        }
      });
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
        backgroundColor: Colors.white,

        endDrawer: Drawer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [Text("Music Player is in Development")],
          ),
        ),

        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black, // The color goes INSIDE the decoration
              borderRadius: BorderRadius.circular(36),
            ),
            child: Text(
              "Hey There, Sir",
              style: GoogleFonts.codystar(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.window, size: 32),
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
                  icon: Icon(Icons.play_arrow_outlined),
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
                                  .black, // Logic: White is better for layered UIs
                              shadows: const [
                                Shadow(
                                  blurRadius: 15.0,
                                  color: Colors.black,
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
                                  .black, // Logic: White is better for layered UIs
                              shadows: const [
                                Shadow(
                                  blurRadius: 15.0,
                                  color: Colors.black,
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
                                  .black, // Logic: White is better for layered UIs
                              shadows: const [
                                Shadow(
                                  blurRadius: 15.0,
                                  color: Colors.black,
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
                                    color: Colors.black,
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
              const Center(child: Text("This Launcher is still in dev")),
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
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: "Search apps or web...",
            hintStyle: TextStyle(color: Colors.grey),
            prefixIcon: Icon(Icons.search, color: Colors.black, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
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
