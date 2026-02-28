import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:marquee/marquee.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:permission_handler/permission_handler.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: Home()));
}

class _HomeState extends State<Home> {
  List<AppInfo> _installedApps = [];
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _currentSong = "System Idle";
  bool _isSearching = false;
  final List<ServiceNotificationEvent> _liveNotifications = [];
  int _notificationCount = 0;

  List<String> quotes = [
    "भाग्य उनका साथ देता है जो कठिन परिस्थितियों में भी अपने लक्ष्य के प्रति अडिग रहते हैं।",
    "आलस्य में दरिद्रता का वास होता है, और प्रयास में सफलता का।",
    "एक बार काम शुरू करने के बाद, असफलता से डरो मत और उसे छोड़ो मत।",
    "बिना अभ्यास के ज्ञान विष के समान है।",
    "संकट आने से पहले ही उससे सावधान रहना चाहिए, और आने पर उस पर प्रहार कर उसे नष्ट कर देना चाहिए।",
    "दूसरों की गलतियों से सीखें, आप खुद सारी गलतियां करने के लिए पर्याप्त लंबे समय तक नहीं जी सकते।",
    "जो व्यक्ति अपना लक्ष्य निर्धारित नहीं कर सकता, वह कभी विजयी नहीं हो सकता।",
    "ऋण, शत्रु और रोग को कभी छोटा नहीं समझना चाहिए, इन्हें जड़ से समाप्त करना ही उचित है।",
    "मनुष्य अपने कर्मों से महान बनता है, अपने जन्म से नहीं।",
  ];
  int _selectedQuote = 0;
  int _quoteSecondsCounter = 0;
  bool isRepeat = false;

  Future<void> _initNotificationListener() async {
    try {
      bool isPermissionGranted =
          await NotificationListenerService.isPermissionGranted();
      developer.log(
        'Notification permission status: $isPermissionGranted',
        name: 'NotificationService',
      );

      if (!isPermissionGranted) {
        developer.log(
          'Requesting notification permission...',
          name: 'NotificationService',
        );
        await NotificationListenerService.requestPermission();
        // After requesting, check again. If still not granted, exit the function.
        isPermissionGranted =
            await NotificationListenerService.isPermissionGranted();
        if (!isPermissionGranted) {
          developer.log(
            'Notification permission not granted after request.',
            name: 'NotificationService',
            level: 900,
          );
          return;
        }
      }

      NotificationListenerService.notificationsStream.listen((event) {
        if (mounted) {
          setState(() {
            _liveNotifications.insert(0, event);
            _notificationCount = _liveNotifications.length;
          });
        }
      });
    } catch (e, s) {
      developer.log(
        'Error initializing notification listener',
        name: 'NotificationService',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _readPlayerStatus() async {
    try {
      final file = File('/storage/emulated/0/spci_status.txt');
      if (await file.exists()) {
        final song = await file.readAsString();
        if (mounted && song.trim() != _currentSong) {
          setState(() {
            _currentSong = song.trim();
            _isSearching = false;
          });
        }
      }
    } catch (e, s) {
      developer.log(
        'Error reading player status file',
        name: 'FileIO',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _clearStaleCommands() async {
    try {
      final file = File('/storage/emulated/0/launcher_cmd.txt');
      if (await file.exists()) {
        await file.delete();
        developer.log("Stale command file purged.", name: 'FileIO');
      }
    } catch (e, s) {
      developer.log(
        "Error clearing stale commands",
        name: 'FileIO',
        error: e,
        stackTrace: s,
      );
    }
  }

  Widget _buildAnimatedBadge() {
    return GestureDetector(
      onTap: _showNotificationsPopup,
      child: Container(
        key: const ValueKey("badge_container"),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(30),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.5),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text(
            "$_notificationCount",
            key: ValueKey(_notificationCount),
            style: GoogleFonts.firaCode(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchInstalledApps();
    _clearStaleCommands();
    _initNotificationListener();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
          _quoteSecondsCounter++;
          if (_quoteSecondsCounter >= 20) {
            int nextQuote;
            do {
              nextQuote = Random().nextInt(quotes.length);
            } while (nextQuote == _selectedQuote);
            _selectedQuote = nextQuote;
            _quoteSecondsCounter = 0;
          }
        });
      }
      _readPlayerStatus();
    });
  }

  void _showNotificationsPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          "SYSTEM LOGS",
          style: GoogleFonts.firaCode(color: Colors.lightGreenAccent),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _liveNotifications.length,
            itemBuilder: (context, index) {
              final notif = _liveNotifications[index];
              return ListTile(
                title: Text(
                  notif.packageName ?? "Unknown",
                  style: GoogleFonts.firaCode(color: Colors.grey, fontSize: 10),
                ),
                subtitle: Text(
                  notif.content ?? "No content",
                  style: GoogleFonts.firaCode(color: Colors.white),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) {
                setState(() {
                  _liveNotifications.clear();
                  _notificationCount = 0;
                });
              }
              Navigator.pop(context);
            },
            child: const Text(
              "CLEAR LOGS",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchInstalledApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        excludeNonLaunchableApps: true,
      );
      if (mounted) {
        setState(() => _installedApps = apps);
      }
    } catch (e, s) {
      developer.log(
        'Error fetching installed apps',
        name: 'InstalledApps',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _sendMusicCommand(String cmd) async {
    try {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Permission Required: Enable 'All Files Access'"),
              action: SnackBarAction(
                label: 'SETTINGS',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
        return;
      }
      final file = File('/storage/emulated/0/launcher_cmd.txt');
      await file.writeAsString(cmd);
    } catch (e, s) {
      developer.log(
        'Error sending music command',
        name: 'FileIO',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        endDrawer: Drawer(
          backgroundColor: Colors.black,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(13),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green.withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.graphic_eq,
                        color: Colors.greenAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 15),
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
                            Text(
                              _currentSong,
                              style: GoogleFonts.firaCode(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
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
                    fillColor: Colors.white.withAlpha(20),
                    hintText: "Type song name...",
                    hintStyle: TextStyle(color: Colors.grey.withAlpha(128)),
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
                      borderSide: BorderSide(color: Colors.white.withAlpha(26)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.green),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      if (mounted) setState(() => _isSearching = true);
                      _sendMusicCommand("play $value");
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
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
                            if (mounted) setState(() => isRepeat = !isRepeat);
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
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.stop_circle,
                            color: Colors.redAccent,
                            size: 50,
                          ),
                          onPressed: () => _sendMusicCommand("stop"),
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
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.power_settings_new,
                            color: Colors.grey,
                            size: 30,
                          ),
                          onPressed: () => _sendMusicCommand("kill"),
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
                Center(
                  child: Text(
                    "BRIDGE STATUS: ACTIVE [TMUX]",
                    style: GoogleFonts.firaCode(
                      color: Colors.greenAccent.withAlpha(128),
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
              if (mounted) setState(() => _isSearching = true);
              _sendMusicCommand("play");
            },
            child: Container(
              height: 45,
              width: MediaQuery.of(context).size.width * 0.65,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) =>
                            ScaleTransition(scale: animation, child: child),
                    child: _notificationCount <= 1
                        ? const SizedBox.shrink()
                        : _buildAnimatedBadge(),
                  ),
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
                                  style: GoogleFonts.firaCode(
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
                              child: Text(
                                "Hey There, Sir",
                                style: GoogleFonts.firaCode(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            )
                          : Marquee(
                              text: '$_currentSong ..... ',
                              style: GoogleFonts.firaCode(
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
                isScrollControlled: true,
                backgroundColor: Colors.black,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (BuildContext context) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: _buildAppList(),
                ),
              );
            },
          ),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(
                  Icons.play_arrow_outlined,
                  color: Colors.white,
                ),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
        ),
        body: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          padding: const EdgeInsets.all(0),
          child: PageView(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.5,
                        child: Image.asset(
                          'assets/images/cmatrix.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            ((_currentTime.hour + 11) % 12 + 1)
                                .toString()
                                .padLeft(2, '0'),
                            style: GoogleFonts.firaCode(
                              fontSize: 80,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
                            style: GoogleFonts.firaCode(
                              fontSize: 80,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
                              color: Colors.white,
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
                            padding: const EdgeInsets.all(10),
                            child: AnimatedTextKit(
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
              onPressed: () => _searchController.clear(),
            ),
          ),
          onSubmitted: (value) {},
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              final query = value.text.toLowerCase().trim();
              final currentFilteredApps = _installedApps
                  .where((app) => app.name.toLowerCase().contains(query))
                  .toList();

              if (currentFilteredApps.isEmpty) {
                return Center(
                  child: Text(
                    "No binary found. Search Web?",
                    style: GoogleFonts.inconsolata(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: currentFilteredApps.length,
                itemBuilder: (context, index) {
                  final app = currentFilteredApps[index];
                  return ListTile(
                    leading: const Icon(Icons.android, color: Colors.green),
                    title: Text(
                      app.name,
                      style: GoogleFonts.firaCode(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () async {
                      try {
                        await InstalledApps.startApp(app.packageName);
                      } catch (e, s) {
                        developer.log(
                          'Error starting app',
                          name: 'InstalledApps',
                          error: e,
                          stackTrace: s,
                        );
                      }
                    },
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
                                onPressed: () async {
                                  try {
                                    await InstalledApps.uninstallApp(
                                      app.packageName,
                                    );
                                    if (mounted) {
                                      Navigator.pop(context);
                                    } // Close dialog after uninstall
                                  } catch (e, s) {
                                    developer.log(
                                      'Error uninstalling app',
                                      name: 'InstalledApps',
                                      error: e,
                                      stackTrace: s,
                                    );
                                  }
                                },
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
                                onPressed: () async {
                                  try {
                                    InstalledApps.openSettings(app.packageName);
                                    if (mounted) {
                                      Navigator.pop(context);
                                    } // Close dialog after opening settings
                                  } catch (e, s) {
                                    developer.log(
                                      'Error opening app settings',
                                      name: 'InstalledApps',
                                      error: e,
                                      stackTrace: s,
                                    );
                                  }
                                },
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
