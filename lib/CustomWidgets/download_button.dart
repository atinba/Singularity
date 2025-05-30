import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:singularity/APIs/api.dart';
import 'package:singularity/CustomWidgets/snackbar.dart';
import 'package:singularity/Services/dl/download.dart';

class DownloadButton extends StatefulWidget {
  final Map data;
  final String? icon;
  final double? size;
  final Color? color;
  const DownloadButton({
    super.key,
    required this.data,
    this.icon,
    this.size,
    this.color,
  });

  @override
  _DownloadButtonState createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  late Download down;
  final Box downloadsBox = Hive.box('downloads');
  final ValueNotifier<bool> showStopButton = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    down = Download(widget.data['id'].toString());
    down.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    showStopButton.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set _mounted to true when the widget is added to the tree
    // _mounted = true;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 50,
      child: Center(
        child: (downloadsBox.containsKey(widget.data['id']))
            ? IconButton(
                icon: const Icon(Icons.download_done_rounded),
                tooltip: 'Download Done',
                color: widget.color ?? Theme.of(context).colorScheme.secondary,
                iconSize: widget.size ?? 24.0,
                onPressed: () {
                  down.prepareDownload(context, widget.data);
                },
              )
            : down.progress == 0
                ? IconButton(
                    icon: Icon(
                      widget.icon == 'download'
                          ? Icons.download_rounded
                          : Icons.save_alt,
                    ),
                    iconSize: widget.size ?? 24.0,
                    color: widget.color ?? Theme.of(context).iconTheme.color,
                    tooltip: 'Download',
                    onPressed: () {
                      down.prepareDownload(context, widget.data);
                    },
                  )
                : GestureDetector(
                    child: Stack(
                      children: [
                        Center(
                          child: CircularProgressIndicator(
                            value: down.progress == 1 ? null : down.progress,
                            color: widget.color,
                          ),
                        ),
                        Center(
                          child: ValueListenableBuilder(
                            valueListenable: showStopButton,
                            child: Center(
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                ),
                                iconSize: 25.0,
                                color: widget.color ??
                                    Theme.of(context).iconTheme.color,
                                tooltip: AppLocalizations.of(
                                  context,
                                )!
                                    .stopDown,
                                onPressed: () {
                                  down.download = false;
                                },
                              ),
                            ),
                            builder: (
                              BuildContext context,
                              bool showValue,
                              Widget? child,
                            ) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Visibility(
                                      visible: !showValue,
                                      child: Center(
                                        child: Text(
                                          down.progress == null
                                              ? '0%'
                                              : '${(100 * down.progress!).round()}%',
                                        ),
                                      ),
                                    ),
                                    Visibility(
                                      visible: showValue,
                                      child: child!,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      showStopButton.value = true;
                      Future.delayed(const Duration(seconds: 2), () async {
                        showStopButton.value = false;
                      });
                    },
                  ),
      ),
    );
  }
}

class MultiDownloadButton extends StatefulWidget {
  final List data;
  final String playlistName;
  const MultiDownloadButton({
    super.key,
    required this.data,
    required this.playlistName,
  });

  @override
  _MultiDownloadButtonState createState() => _MultiDownloadButtonState();
}

class _MultiDownloadButtonState extends State<MultiDownloadButton> {
  late Download down;
  int done = 0;

  @override
  void initState() {
    super.initState();
    down = Download(widget.data.first['id'].toString());
    down.addListener(() {
      setState(() {});
    });
  }

  Future<void> _waitUntilDone(String id) async {
    while (down.lastDownloadId != id) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const SizedBox();
    }
    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
        child: (down.lastDownloadId == widget.data.last['id'])
            ? IconButton(
                icon: const Icon(
                  Icons.download_done_rounded,
                ),
                color: Theme.of(context).colorScheme.secondary,
                iconSize: 25.0,
                tooltip: AppLocalizations.of(context)!.downDone,
                onPressed: () {},
              )
            : down.progress == 0
                ? Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                      ),
                      iconSize: 25.0,
                      tooltip: AppLocalizations.of(context)!.down,
                      onPressed: () async {
                        var trackNumber = 1;
                        for (final items in widget.data) {
                          final songData = items as Map;
                          songData['trackNumber'] = trackNumber;
                          songData['trackTotal'] = widget.data.length;
                          trackNumber += 1;
                          down.prepareDownload(
                            context,
                            songData,
                            createFolder: true,
                            folderName: widget.playlistName,
                            isAlbum: true,
                          );
                          await _waitUntilDone(items['id'].toString());
                          setState(() {
                            done++;
                          });
                        }
                      },
                    ),
                  )
                : Stack(
                    children: [
                      Center(
                        child: Text(
                          down.progress == null
                              ? '0%'
                              : '${(100 * down.progress!).round()}%',
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 35,
                          width: 35,
                          child: CircularProgressIndicator(
                            value: down.progress == 1 ? null : down.progress,
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(
                            value: done / widget.data.length,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class SaavnAlbumDownloadButton extends StatefulWidget {
  final String albumId;
  final String albumName;
  const SaavnAlbumDownloadButton({
    super.key,
    required this.albumId,
    required this.albumName,
  });

  @override
  _SaavnAlbumDownloadButtonState createState() =>
      _SaavnAlbumDownloadButtonState();
}

class _SaavnAlbumDownloadButtonState extends State<SaavnAlbumDownloadButton> {
  late Download down;
  int done = 0;
  List data = [];
  bool finished = false;

  @override
  void initState() {
    super.initState();
    down = Download(widget.albumId);
    down.addListener(() {
      setState(() {});
    });
  }

  Future<void> _waitUntilDone(String id) async {
    while (down.lastDownloadId != id) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
        child: finished
            ? IconButton(
                icon: const Icon(
                  Icons.download_done_rounded,
                ),
                color: Theme.of(context).colorScheme.secondary,
                iconSize: 25.0,
                tooltip: AppLocalizations.of(context)!.downDone,
                onPressed: () {},
              )
            : down.progress == 0
                ? Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                      ),
                      iconSize: 25.0,
                      color: Theme.of(context).iconTheme.color,
                      tooltip: AppLocalizations.of(context)!.down,
                      onPressed: () async {
                        ShowSnackBar().showSnackBar(
                          context,
                          '${AppLocalizations.of(context)!.downingAlbum} "${widget.albumName}"',
                        );

                        data = (await SaavnAPI()
                            .fetchAlbumSongs(widget.albumId))['songs'] as List;
                        var trackNumber = 1;
                        for (final items in data) {
                          final songData = items as Map;
                          songData['trackNumber'] = trackNumber;
                          songData['trackTotal'] = data.length;
                          trackNumber += 1;
                          down.prepareDownload(
                            context,
                            songData,
                            createFolder: true,
                            folderName: widget.albumName,
                            isAlbum: true,
                          );
                          await _waitUntilDone(items['id'].toString());
                          setState(() {
                            done++;
                          });
                        }
                        finished = true;
                      },
                    ),
                  )
                : Stack(
                    children: [
                      Center(
                        child: Text(
                          down.progress == null
                              ? '0%'
                              : '${(100 * down.progress!).round()}%',
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 35,
                          width: 35,
                          child: CircularProgressIndicator(
                            value: down.progress == 1 ? null : down.progress,
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(
                            value: data.isEmpty ? 0 : done / data.length,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
