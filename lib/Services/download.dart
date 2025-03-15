import 'dart:io';

import 'package:audiotags/audiotags.dart';
// import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:singularity/CustomWidgets/snackbar.dart';
import 'package:singularity/Helpers/lyrics.dart';
import 'package:singularity/Services/youtube_services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Download with ChangeNotifier {
  static final Map<String, Download> _instances = {};
  final String id;

  factory Download(String id) {
    if (_instances.containsKey(id)) {
      return _instances[id]!;
    } else {
      final instance = Download._internal(id);
      _instances[id] = instance;
      return instance;
    }
  }

  Download._internal(this.id);

  int? rememberOption;
  final ValueNotifier<bool> remember = ValueNotifier<bool>(false);
  String preferredDownloadQuality = Hive.box('settings')
      .get('downloadQuality', defaultValue: '320 kbps') as String;
  String preferredYtDownloadQuality = Hive.box('settings')
      .get('ytDownloadQuality', defaultValue: 'High') as String;
  String downloadFormat = Hive.box('settings')
      .get('downloadFormat', defaultValue: 'm4a')
      .toString();
  bool createDownloadFolder = Hive.box('settings')
      .get('createDownloadFolder', defaultValue: false) as bool;
  bool createYoutubeFolder = Hive.box('settings')
      .get('createYoutubeFolder', defaultValue: false) as bool;
  bool numberSongTitlsInAlbum =
      Hive.box('settings').get('numberAlbumSongs', defaultValue: false) as bool;
  double? progress = 0.0;
  String lastDownloadId = '';
  bool download = true;

  Future<void> prepareDownload(
    BuildContext context,
    Map data, {
    bool createFolder = false,
    String? folderName,
  }) async {
    Logger.root.info('Preparing download for ${data['title']}');
    download = true;
    if (Platform.isAndroid || Platform.isIOS) {
      Logger.root.info('Requesting storage permission');
      PermissionStatus status = await Permission.storage.status;
      if (status.isDenied) {
        Logger.root.info('Request denied');
        await [
          Permission.storage,
          Permission.accessMediaLocation,
          Permission.mediaLibrary,
        ].request();
      }
      status = await Permission.storage.status;
      if (status.isPermanentlyDenied) {
        Logger.root.info('Request permanently denied');
        await openAppSettings();
      }
    }
    final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
    data['title'] = data['title'].toString().split('(From')[0].trim();

    String filename = '';
    final int downFilename =
        Hive.box('settings').get('downFilename', defaultValue: 1) as int;
    if (downFilename == 0) {
      filename = '${data["title"]} - ${data["artist"]}';
    } else if (downFilename == 1) {
      filename = '${data["artist"]} - ${data["title"]}';
    } else {
      filename = '${data["title"]}';
    }

    if (data.containsKey('trackNumber') &&
        createDownloadFolder &&
        numberSongTitlsInAlbum) {
      filename =
          "${data["trackNumber"].toString().padLeft(2, '0')} - ${data["title"]!}";
    }
    // String filename = '${data["title"]} - ${data["artist"]}';
    String dlPath =
        Hive.box('settings').get('downloadPath', defaultValue: '') as String;
    Logger.root.info('Cached Download path: $dlPath');
    if (filename.length > 200) {
      final String temp = filename.substring(0, 200);
      final List tempList = temp.split(', ');
      tempList.removeLast();
      filename = tempList.join(', ');
    }

    filename = '${filename.replaceAll(avoid, "").replaceAll("  ", " ")}.m4a';
    if (dlPath == '') {
      Logger.root.info(
        'Cached Download path is empty, using /storage/emulated/0/Music',
      );
      dlPath = '/storage/emulated/0/Music';
    }
    Logger.root.info('New Download path: $dlPath');
    if (data['url'].toString().contains('google') && createYoutubeFolder) {
      Logger.root.info('Youtube audio detected, creating Youtube folder');
      dlPath = '$dlPath/YouTube';
      if (!await Directory(dlPath).exists()) {
        Logger.root.info('Creating Youtube folder');
        await Directory(dlPath).create();
      }
    }

    if (createFolder && createDownloadFolder && folderName != null) {
      final String foldername = folderName.replaceAll(avoid, '');
      dlPath = '$dlPath/$foldername';
      if (!await Directory(dlPath).exists()) {
        Logger.root.info('Creating folder $foldername');
        await Directory(dlPath).create();
      }
    }

    final bool exists = await File('$dlPath/$filename').exists();
    if (exists) {
      Logger.root.info('File already exists');
      if (remember.value == true && rememberOption != null) {
        switch (rememberOption) {
          case 0:
            lastDownloadId = data['id'].toString();
          case 1:
            downloadSong(dlPath, filename, data);
          case 2:
            while (await File('$dlPath/$filename').exists()) {
              filename = filename.replaceAll('.m4a', ' (1).m4a');
            }
          default:
            lastDownloadId = data['id'].toString();
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              title: Text(
                AppLocalizations.of(context)!.alreadyExists,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '"${data['title']}" ${AppLocalizations.of(context)!.downAgain}',
                    softWrap: true,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
              actions: [
                Column(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: remember,
                      builder: (
                        BuildContext context,
                        bool rememberValue,
                        Widget? child,
                      ) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Checkbox(
                                activeColor:
                                    Theme.of(context).colorScheme.secondary,
                                value: rememberValue,
                                onChanged: (bool? value) {
                                  remember.value = value ?? false;
                                },
                              ),
                              Text(
                                AppLocalizations.of(context)!.rememberChoice,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () {
                              lastDownloadId = data['id'].toString();
                              Navigator.pop(context);
                              rememberOption = 0;
                            },
                            child: Text(
                              AppLocalizations.of(context)!.no,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              Hive.box('downloads').delete(data['id']);
                              downloadSong(dlPath, filename, data);
                              rememberOption = 1;
                            },
                            child:
                                Text(AppLocalizations.of(context)!.yesReplace),
                          ),
                          const SizedBox(width: 5.0),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              while (await File('$dlPath/$filename').exists()) {
                                filename =
                                    filename.replaceAll('.m4a', ' (1).m4a');
                              }
                              rememberOption = 2;
                              downloadSong(dlPath, filename, data);
                            },
                            child: Text(
                              AppLocalizations.of(context)!.yes,
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.secondary ==
                                            Colors.white
                                        ? Colors.black
                                        : null,
                              ),
                            ),
                          ),
                          const SizedBox(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      }
    } else {
      downloadSong(dlPath, filename, data);
    }
  }

  Future<void> downloadSong(
    String? dlPath,
    String fileName,
    Map data,
  ) async {
    Logger.root.info('processing download');
    progress = null;
    notifyListeners();
    String? filepath;
    late String filepath2;
    String? appPath;
    final List<int> bytes = [];
    final artname = fileName.replaceAll('.m4a', '.jpg');
    if (!Platform.isWindows) {
      Logger.root.info('Getting App Path for storing image');
      appPath = Hive.box('settings').get('tempDirPath')?.toString();
      appPath ??= (await getTemporaryDirectory()).path;
    } else {
      final Directory? temp = await getDownloadsDirectory();
      appPath = temp!.path;
    }

    try {
      Logger.root.info('Creating audio file $dlPath/$fileName');
      await File('$dlPath/$fileName')
          .create(recursive: true)
          .then((value) => filepath = value.path);
      Logger.root.info('Creating image file $appPath/$artname');
      await File('$appPath/$artname')
          .create(recursive: true)
          .then((value) => filepath2 = value.path);
    } catch (e) {
      Logger.root
          .info('Error creating files, requesting additional permission');
      if (Platform.isAndroid) {
        PermissionStatus status = await Permission.manageExternalStorage.status;
        if (status.isDenied) {
          Logger.root.info(
            'ManageExternalStorage permission is denied, requesting permission',
          );
          await [
            Permission.manageExternalStorage,
          ].request();
        }
        status = await Permission.manageExternalStorage.status;
        if (status.isPermanentlyDenied) {
          Logger.root.info(
            'ManageExternalStorage Request is permanently denied, opening settings',
          );
          await openAppSettings();
        }
      }

      Logger.root.info('Retrying to create audio file');
      await File('$dlPath/$fileName')
          .create(recursive: true)
          .then((value) => filepath = value.path);

      Logger.root.info('Retrying to create image file');
      await File('$appPath/$artname')
          .create(recursive: true)
          .then((value) => filepath2 = value.path);
    }
    String kUrl = data['url'].toString();

    if (!data['url'].toString().contains('google')) {
      Logger.root.info('Fetching jiosaavn download url with preferred quality');
      kUrl = kUrl.replaceAll(
        '_96.',
        "_${preferredDownloadQuality.replaceAll(' kbps', '')}.",
      );
    }

    int total = 0;
    int recieved = 0;
    Client? client;
    Stream<List<int>> stream;
    // Download from yt
    if (data['url'].toString().contains('google')) {
      // Use preferredYtDownloadQuality to check for quality first
      final AudioOnlyStreamInfo streamInfo =
          (await YouTubeServices.instance.getStreamInfo(data['id'].toString()))
              .last;
      total = streamInfo.size.totalBytes;
      // Get the actual stream
      stream = YouTubeServices.instance.getStreamClient(streamInfo);
    } else {
      Logger.root.info('Connecting to Client');
      client = Client();
      final response = await client.send(Request('GET', Uri.parse(kUrl)));
      total = response.contentLength ?? 0;
      stream = response.stream.asBroadcastStream();
    }
    Logger.root.info('Client connected, Starting download');
    stream.listen((value) {
      bytes.addAll(value);
      try {
        recieved += value.length;
        progress = recieved / total;
        notifyListeners();
        if (!download && client != null) {
          client.close();
          // need to add for yt as well
        }
      } catch (e) {
        Logger.root.severe('Error in download: $e');
      }
    }).onDone(() async {
      if (download) {
        Logger.root.info('Download complete, modifying file');
        final file = File(filepath!);
        await file.writeAsBytes(bytes);

        final client = HttpClient();
        final HttpClientRequest request2 =
            await client.getUrl(Uri.parse(data['image'].toString()));
        final HttpClientResponse response2 = await request2.close();
        final bytes2 = await consolidateHttpClientResponseBytes(response2);
        final File file2 = File(filepath2);

        file2.writeAsBytesSync(bytes2);

        data['lyrics'] = await getLyrics(data);
        writeTags(filepath!, data, bytes2);

        Logger.root.info('Closing connection & notifying listeners');
        client.close();
        lastDownloadId = data['id'].toString();
        progress = 0.0;
        notifyListeners();

        saveSongDataInDB(data, filepath!, filepath2);
        Logger.root.info('Everything Done!');
        // ShowSnackBar().showSnackBar(
        //   context,
        //   '"${data['title']}" ${AppLocalizations.of(context)!.downed}',
        // );
      } else {
        download = true;
        progress = 0.0;
        File(filepath!).delete();
        File(filepath2).delete();
      }
    });
  }

  Future<void> writeTags(String filepath, Map data, Uint8List bytes) async {
    Logger.root.info('Writing audio tags');
    try {
      final Tag tag = Tag(
        title: data['title'].toString(),
        trackArtist: data['artist'].toString(),
        albumArtist: data['album_artist']?.toString() ??
            data['artist']?.toString().split(', ')[0] ??
            '',
        album: data['album'].toString(),
        year: int.tryParse(data['year'].toString()),
        lyrics: data['lyrics'].toString(),
        trackNumber: int.tryParse(data['trackNumber'].toString()),
        trackTotal: int.tryParse(data['trackTotal'].toString()),
        discNumber: int.tryParse(data['discNumber'].toString()),
        discTotal: int.tryParse(data['discTotal'].toString()),
        duration: int.tryParse(data['duration'].toString()),
        // genre: ,
        pictures: [
          Picture(
            bytes: bytes,
            mimeType: MimeType.jpeg,
            pictureType: PictureType.coverFront,
          ),
        ],
      );

      await AudioTags.write(filepath, tag);
    } catch (e) {
      Logger.root.severe('Error writing tags: $e');
    }
  }

  Future<String> getLyrics(Map data) async {
    Logger.root.info('Downloading lyrics');
    try {
      final Map res = await Lyrics.getLyrics(
        id: data['id'].toString(),
        title: data['title'].toString(),
        artist: data['artist']?.toString() ?? '',
        album: data['album']?.toString() ?? '',
        duration: data['duration']?.toString() ?? '180',
        saavnHas: data['has_lyrics'] == 'true',
      );
      return res['lyrics'].toString();
    } catch (e) {
      Logger.root.severe('Error fetching lyrics: $e');
      return '';
    }
  }

  void saveSongDataInDB(Map data, String filepath, String filepath2) {
    Logger.root.info('Putting data to downloads database');
    final songData = {
      'id': data['id'].toString(),
      'title': data['title'].toString(),
      'subtitle': data['subtitle'].toString(),
      'artist': data['artist'].toString(),
      'albumArtist': data['album_artist']?.toString() ??
          data['artist']?.toString().split(', ')[0],
      'album': data['album'].toString(),
      'genre': data['genre'].toString(),
      'year': data['year'].toString(),
      'lyrics': data['lyrics'].toString(),
      'duration': data['duration'],
      'release_date': data['release_date'].toString(),
      'album_id': data['album_id'].toString(),
      'perma_url': data['perma_url'].toString(),
      'quality': preferredDownloadQuality,
      'path': filepath,
      'image': filepath2,
      'image_url': data['image'].toString(),
      'from_yt': data['language'].toString() == 'YouTube',
      'dateAdded': DateTime.now().toString(),
    };
    Hive.box('downloads').put(songData['id'].toString(), songData);
  }
}
