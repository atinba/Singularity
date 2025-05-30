import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:singularity/CustomWidgets/bottom_nav_bar.dart';
import 'package:singularity/CustomWidgets/drawer.dart';
import 'package:singularity/CustomWidgets/gradient_containers.dart';
import 'package:singularity/CustomWidgets/miniplayer.dart';
import 'package:singularity/CustomWidgets/snackbar.dart';
import 'package:singularity/Helpers/backup_restore.dart';
import 'package:singularity/Helpers/downloads_checker.dart';
import 'package:singularity/Helpers/github.dart';
import 'package:singularity/Helpers/route_handler.dart';
import 'package:singularity/Helpers/update.dart';
import 'package:singularity/Screens/Common/routes.dart';
import 'package:singularity/Screens/Home/home_screen.dart';
import 'package:singularity/Screens/Library/library.dart';
import 'package:singularity/Screens/LocalMusic/downed_songs.dart';
import 'package:singularity/Screens/LocalMusic/downed_songs_desktop.dart';
import 'package:singularity/Screens/Player/audioplayer.dart';
import 'package:singularity/Screens/Settings/new_settings_page.dart';
import 'package:singularity/Services/ext_storage_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);
  String? appVersion;
  String name =
      Hive.box('settings').get('name', defaultValue: 'Guest') as String;
  bool checkUpdate =
      Hive.box('settings').get('checkUpdate', defaultValue: true) as bool;
  bool autoBackup =
      Hive.box('settings').get('autoBackup', defaultValue: false) as bool;
  List sectionsToShow = Hive.box('settings').get(
    'sectionsToShow',
    defaultValue: ['Home', 'Library', 'Settings'],
  ) as List;
  DateTime? backButtonPressTime;
  final bool useDense = Hive.box('settings').get(
    'useDenseMini',
    defaultValue: false,
  ) as bool;

  void callback() {
    sectionsToShow = Hive.box('settings').get(
      'sectionsToShow',
      defaultValue: ['Home', 'Library', 'Settings'],
    ) as List;
    onItemTapped(0);
    setState(() {});
  }

  void onItemTapped(int index) {
    _selectedIndex.value = index;
    _controller.jumpToTab(
      index,
    );
  }

  // Future<bool> handleWillPop(BuildContext? context) async {
  //   if (context == null) return false;
  //   final now = DateTime.now();
  //   final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
  //       backButtonPressTime == null ||
  //           now.difference(backButtonPressTime!) > const Duration(seconds: 3);

  //   if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
  //     backButtonPressTime = now;
  //     ShowSnackBar().showSnackBar(
  //       context,
  //       AppLocalizations.of(context)!.exitConfirm,
  //       duration: const Duration(seconds: 2),
  //       noAction: true,
  //     );
  //     return false;
  //   }
  //   return true;
  // }

  void checkVersion() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      appVersion = packageInfo.version;

      if (checkUpdate) {
        Logger.root.info('Checking for update');
        GitHub.getLatestVersion().then((String version) async {
          if (compareVersion(
            version,
            appVersion!,
          )) {
            Logger.root.info('Update available');
            ShowSnackBar().showSnackBar(
              context,
              AppLocalizations.of(context)!.updateAvailable,
              duration: const Duration(seconds: 15),
              action: SnackBarAction(
                textColor: Theme.of(context).colorScheme.secondary,
                label: AppLocalizations.of(context)!.update,
                onPressed: () async {
                  // String arch = '';
                  // if (Platform.isAndroid) {
                  //   List? abis = await Hive.box('settings').get('supportedAbis')
                  //       as List?;

                  //   if (abis == null) {
                  //     final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
                  //     final AndroidDeviceInfo androidDeviceInfo =
                  //         await deviceInfo.androidInfo;
                  //     abis = androidDeviceInfo.supportedAbis;
                  //     await Hive.box('settings').put('supportedAbis', abis);
                  //   }
                  //   if (abis.contains('arm64')) {
                  //     arch = 'arm64';
                  //   } else if (abis.contains('armeabi')) {
                  //     arch = 'armeabi';
                  //   }
                  // }
                  Navigator.pop(context);
                  launchUrl(
                    Uri.parse(
                      'https://github.com/atinba/Singularity/releases/latest',
                    ),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            );
          } else {
            Logger.root.info('No update available');
          }
        });
      }

      if (autoBackup) {
        final List<String> checked = [
          AppLocalizations.of(
            context,
          )!
              .settings,
          AppLocalizations.of(
            context,
          )!
              .downs,
          AppLocalizations.of(
            context,
          )!
              .playlists,
        ];
        final List playlistNames = Hive.box('settings').get(
          'playlistNames',
          defaultValue: ['Favorite Songs'],
        ) as List;
        final Map<String, List> boxNames = {
          AppLocalizations.of(
            context,
          )!
              .settings: ['settings'],
          AppLocalizations.of(
            context,
          )!
              .cache: ['cache'],
          AppLocalizations.of(
            context,
          )!
              .downs: ['downloads'],
          AppLocalizations.of(
            context,
          )!
              .playlists: playlistNames,
        };
        final String autoBackPath = Hive.box('settings').get(
          'autoBackPath',
          defaultValue: '',
        ) as String;
        if (autoBackPath == '') {
          ExtStorageProvider.getExtStorage(
            dirName: 'Singularity/Backups',
            writeAccess: true,
          ).then((value) {
            Hive.box('settings').put('autoBackPath', value);
            createBackup(
              context,
              checked,
              boxNames,
              path: value,
              fileName: 'Singularity_AutoBackup',
              showDialog: false,
            );
          });
        } else {
          createBackup(
            context,
            checked,
            boxNames,
            path: autoBackPath,
            fileName: 'Singularity_AutoBackup',
            showDialog: false,
          ).then(
            (value) => {
              if (value.contains('No such file or directory'))
                {
                  ExtStorageProvider.getExtStorage(
                    dirName: 'Singularity/Backups',
                    writeAccess: true,
                  ).then(
                    (value) {
                      Hive.box('settings').put('autoBackPath', value);
                      createBackup(
                        context,
                        checked,
                        boxNames,
                        path: value,
                        fileName: 'Singularity_AutoBackup',
                      );
                    },
                  ),
                },
            },
          );
        }
      }
    });
    downloadChecker();
  }

  final PageController _pageController = PageController();
  final PersistentTabController _controller = PersistentTabController();

  @override
  void initState() {
    super.initState();
    checkVersion();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool rotated = MediaQuery.sizeOf(context).height < screenWidth;
    final miniplayer = MiniPlayer();
    return GradientContainer(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        drawerEnableOpenDragGesture: false,
        drawer: Drawer(
          child: GradientContainer(
            child: CustomScrollView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  stretch: true,
                  expandedHeight: MediaQuery.sizeOf(context).height * 0.2,
                  flexibleSpace: FlexibleSpaceBar(
                    title: RichText(
                      text: TextSpan(
                        text: AppLocalizations.of(context)!.appTitle,
                        style: const TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w600,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: appVersion == null ? '' : '\nv$appVersion',
                            style: const TextStyle(
                              fontSize: 7.0,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.end,
                    ),
                    titlePadding: const EdgeInsets.only(bottom: 40.0),
                    centerTitle: true,
                    background: ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.black.withValues(alpha: 0.1),
                          ],
                        ).createShader(
                          Rect.fromLTRB(0, 0, rect.width, rect.height),
                        );
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image(
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        image: AssetImage(
                          Theme.of(context).brightness == Brightness.dark
                              ? 'assets/header-dark.jpg'
                              : 'assets/header.jpg',
                        ),
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      ValueListenableBuilder(
                        valueListenable: _selectedIndex,
                        builder: (
                          BuildContext context,
                          int snapshot,
                          Widget? child,
                        ) {
                          return Column(
                            children: [
                              ListTile(
                                title: Text(
                                  AppLocalizations.of(context)!.home,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                leading: const Icon(
                                  Icons.home_rounded,
                                ),
                                selected: _selectedIndex.value ==
                                    sectionsToShow.indexOf('Home'),
                                selectedColor:
                                    Theme.of(context).colorScheme.secondary,
                                onTap: () {
                                  Navigator.pop(context);
                                  if (_selectedIndex.value != 0) {
                                    onItemTapped(0);
                                  }
                                },
                              ),
                              ListTile(
                                title:
                                    Text(AppLocalizations.of(context)!.myMusic),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                leading: Icon(
                                  MdiIcons.folderMusic,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          (Platform.isWindows ||
                                                  Platform.isLinux ||
                                                  Platform.isMacOS)
                                              ? const DownloadedSongsDesktop()
                                              : const DownloadedSongs(
                                                  showPlaylists: true,
                                                ),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                title:
                                    Text(AppLocalizations.of(context)!.downs),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                leading: Icon(
                                  Icons.download_done_rounded,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/downloads');
                                },
                              ),
                              ListTile(
                                title: Text(
                                  AppLocalizations.of(context)!.playlists,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                leading: Icon(
                                  Icons.playlist_play_rounded,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/playlists');
                                },
                              ),
                              ListTile(
                                title: Text(
                                  AppLocalizations.of(context)!.settings,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                // miscellaneous_services_rounded,
                                leading: const Icon(Icons.settings_rounded),
                                selected: _selectedIndex.value ==
                                    sectionsToShow.indexOf('Settings'),
                                selectedColor:
                                    Theme.of(context).colorScheme.secondary,
                                onTap: () {
                                  Navigator.pop(context);
                                  final idx =
                                      sectionsToShow.indexOf('Settings');
                                  if (idx != -1) {
                                    if (_selectedIndex.value != idx) {
                                      onItemTapped(idx);
                                    }
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            NewSettingsPage(callback: callback),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Row(
          children: [
            if (rotated)
              ValueListenableBuilder(
                valueListenable: _selectedIndex,
                builder: (BuildContext context, int indexValue, Widget? child) {
                  return NavigationRail(
                    minWidth: 70.0,
                    groupAlignment: 0.0,
                    backgroundColor:
                        // Colors.transparent,
                        Theme.of(context).cardColor,
                    selectedIndex: indexValue,
                    onDestinationSelected: (int index) {
                      onItemTapped(index);
                    },
                    labelType: screenWidth > 1050
                        ? NavigationRailLabelType.selected
                        : NavigationRailLabelType.none,
                    selectedLabelTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelTextStyle: TextStyle(
                      color: Theme.of(context).iconTheme.color,
                    ),
                    selectedIconTheme: Theme.of(context).iconTheme.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                    unselectedIconTheme: Theme.of(context).iconTheme,
                    useIndicator: screenWidth < 1050,
                    indicatorColor: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.2),
                    leading: homeDrawer(
                      context: context,
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                    ),
                    destinations: sectionsToShow.map((e) {
                      switch (e) {
                        case 'Home':
                          return NavigationRailDestination(
                            icon: const Icon(Icons.home_rounded),
                            label: Text(AppLocalizations.of(context)!.home),
                          );
                        case 'Library':
                          return NavigationRailDestination(
                            icon: const Icon(Icons.my_library_music_rounded),
                            label: Text(AppLocalizations.of(context)!.library),
                          );
                        default:
                          return NavigationRailDestination(
                            icon: const Icon(Icons.settings_rounded),
                            label: Text(
                              AppLocalizations.of(context)!.settings,
                            ),
                          );
                      }
                    }).toList(),
                  );
                },
              ),
            Expanded(
              child: PersistentTabView.custom(
                context,
                controller: _controller,
                itemCount: sectionsToShow.length,
                navBarHeight: 60 +
                    (rotated ? 0 : 70) +
                    (useDense ? 0 : 10) +
                    (rotated && useDense ? 10 : 0),
                // confineToSafeArea: false,
                resizeToAvoidBottomInset: true,
                backgroundColor: Colors.transparent,
                customWidget: ColoredBox(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      miniplayer,
                      if (!rotated)
                        ValueListenableBuilder(
                          valueListenable: _selectedIndex,
                          builder: (
                            BuildContext context,
                            int indexValue,
                            Widget? child,
                          ) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              height: 60,
                              child: CustomBottomNavBar(
                                currentIndex: indexValue,
                                backgroundColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.black.withValues(alpha: 0.93)
                                    : Colors.white.withValues(alpha: 0.93),
                                onTap: (index) {
                                  onItemTapped(index);
                                },
                                items: _navBarItems(context),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                screens: sectionsToShow.map((e) {
                  switch (e) {
                    case 'Home':
                      return CustomNavBarScreen(
                        routeAndNavigatorSettings: RouteAndNavigatorSettings(
                          routes: namedRoutes,
                          onGenerateRoute: (RouteSettings settings) {
                            if (settings.name == '/player') {
                              return PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (_, __, ___) => const PlayScreen(),
                              );
                            }
                            return HandleRoute.handleRoute(settings.name);
                          },
                        ),
                        screen: const HomeScreen(),
                      );
                    case 'Library':
                      return CustomNavBarScreen(
                        routeAndNavigatorSettings: RouteAndNavigatorSettings(
                          routes: namedRoutes,
                          onGenerateRoute: (RouteSettings settings) {
                            if (settings.name == '/player') {
                              return PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (_, __, ___) => const PlayScreen(),
                              );
                            }
                            return HandleRoute.handleRoute(settings.name);
                          },
                        ),
                        screen: const LibraryPage(),
                      );
                    default:
                      return CustomNavBarScreen(
                        routeAndNavigatorSettings: RouteAndNavigatorSettings(
                          routes: namedRoutes,
                          onGenerateRoute: (RouteSettings settings) {
                            if (settings.name == '/player') {
                              return PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (_, __, ___) => const PlayScreen(),
                              );
                            }
                            return HandleRoute.handleRoute(settings.name);
                          },
                        ),
                        screen: NewSettingsPage(callback: callback),
                      );
                  }
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<CustomBottomNavBarItem> _navBarItems(BuildContext context) {
    return sectionsToShow.map((section) {
      switch (section) {
        case 'Home':
          return CustomBottomNavBarItem(
            icon: const Icon(Icons.home_rounded),
            title: Text(AppLocalizations.of(context)!.home),
            selectedColor: Theme.of(context).colorScheme.secondary,
          );
        case 'Library':
          return CustomBottomNavBarItem(
            icon: const Icon(Icons.my_library_music_rounded),
            title: Text(AppLocalizations.of(context)!.library),
            selectedColor: Theme.of(context).colorScheme.secondary,
          );
        default:
          return CustomBottomNavBarItem(
            icon: const Icon(Icons.settings_rounded),
            title: Text(AppLocalizations.of(context)!.settings),
            selectedColor: Theme.of(context).colorScheme.secondary,
          );
      }
    }).toList();
  }
}
