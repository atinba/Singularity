import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:singularity/CustomWidgets/add_playlist.dart';
import 'package:singularity/Helpers/add_mediaitem_to_queue.dart';
import 'package:singularity/Helpers/mediaitem_converter.dart';
import 'package:singularity/Helpers/radio.dart';
import 'package:singularity/Screens/Common/song_list.dart';
import 'package:singularity/Screens/Search/search.dart';
import 'package:singularity/Screens/YouTube/youtube_playlist.dart';
import 'package:singularity/Services/yt_music.dart';
import 'package:singularity/utils.dart';

class SongTileTrailingMenu extends StatefulWidget {
  final Map data;
  final bool isPlaylist;
  final Function(Map)? deleteLiked;
  const SongTileTrailingMenu({
    super.key,
    required this.data,
    this.isPlaylist = false,
    this.deleteLiked,
  });

  @override
  _SongTileTrailingMenuState createState() => _SongTileTrailingMenuState();
}

class _SongTileTrailingMenuState extends State<SongTileTrailingMenu> {
  @override
  Widget build(BuildContext context) {
    final MediaItem mediaItem = MediaItemConverter.mapToMediaItem(widget.data);
    return PopupMenuButton(
      icon: Icon(
        Icons.more_vert_rounded,
        color: Theme.of(context).iconTheme.color,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(15.0),
        ),
      ),
      itemBuilder: (context) => [
        if (widget.isPlaylist && widget.deleteLiked != null)
          PopupMenuItem(
            value: 6,
            child: Row(
              children: [
                const Icon(
                  Icons.delete_rounded,
                ),
                const SizedBox(
                  width: 10.0,
                ),
                Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .remove,
                ),
              ],
            ),
          ),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(
                Icons.playlist_play_rounded,
                color: Theme.of(context).iconTheme.color,
                size: 26.0,
              ),
              const SizedBox(width: 10.0),
              Text(AppLocalizations.of(context)!.playNext),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(
                Icons.queue_music_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(AppLocalizations.of(context)!.addToQueue),
            ],
          ),
        ),
        PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              Icon(
                Icons.playlist_add_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(AppLocalizations.of(context)!.addToPlaylist),
            ],
          ),
        ),
        PopupMenuItem(
          value: 4,
          child: Row(
            children: [
              Icon(
                Icons.album_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(AppLocalizations.of(context)!.viewAlbum),
            ],
          ),
        ),
        if (mediaItem.artist != null)
          ...mediaItem.artist.toString().split(', ').map(
                (artist) => PopupMenuItem(
                  value: artist,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          '${AppLocalizations.of(context)!.viewArtist} ($artist)',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        PopupMenuItem(
          value: 7,
          child: Row(
            children: [
              Icon(
                Icons.podcasts_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(AppLocalizations.of(context)!.playRadio),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 4:
            Navigator.push(
              context,
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (_, __, ___) => SongsListPage(
                  listItem: {
                    'type': 'album',
                    'id': mediaItem.extras?['album_id'],
                    'title': mediaItem.album,
                    'image': mediaItem.artUri,
                  },
                ),
              ),
            );
          case 6:
            widget.deleteLiked!(widget.data);
          case 7:
            createRadioItems(stationNames: [mediaItem.id]);
          case 0:
            AddToPlaylist().addToPlaylist(context, mediaItem);
          case 1:
            addToNowPlaying(context: context, mediaItem: mediaItem);
          case 2:
            playNext(mediaItem, context);
          default:
            navigateToArtistPage(
              context,
              albumId: mediaItem.extras?['album_id'] as String,
              artistName: value.toString(),
            );
        }
      },
    );
  }
}

class YtSongTileTrailingMenu extends StatefulWidget {
  final Map data;
  const YtSongTileTrailingMenu({super.key, required this.data});

  @override
  _YtSongTileTrailingMenuState createState() => _YtSongTileTrailingMenuState();
}

class _YtSongTileTrailingMenuState extends State<YtSongTileTrailingMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(
        Icons.more_vert_rounded,
        color: Theme.of(context).iconTheme.color,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(15.0),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              Icon(
                CupertinoIcons.search,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(
                width: 10.0,
              ),
              Text(
                AppLocalizations.of(
                  context,
                )!
                    .searchHome,
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(
                Icons.playlist_play_rounded,
                color: Theme.of(context).iconTheme.color,
                size: 26.0,
              ),
              const SizedBox(width: 10.0),
              Text(AppLocalizations.of(context)!.playNext),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(
                Icons.queue_music_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(AppLocalizations.of(context)!.addToQueue),
            ],
          ),
        ),
        PopupMenuItem(
          value: 3,
          child: Row(
            children: [
              Icon(
                Icons.playlist_add_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(AppLocalizations.of(context)!.addToPlaylist),
            ],
          ),
        ),
        if (widget.data.containsKey('albumId'))
          PopupMenuItem(
            value: 6,
            child: Row(
              children: [
                Icon(
                  Icons.album_sharp,
                  color: Theme.of(context).iconTheme.color,
                ),
                const SizedBox(width: 10.0),
                const Text('Go to Album'),
              ],
            ),
          ),
      ],
      onSelected: (int? value) {
        if (value == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchPage(
                query: widget.data['title'].toString(),
              ),
            ),
          );
        }
        if (value == 1 || value == 2 || value == 3) {
          YtMusicService()
              .getSongData(
            videoId: widget.data['id'].toString(),
            data: widget.data,
          )
              .then((songMap) {
            final MediaItem mediaItem =
                MediaItemConverter.mapToMediaItem(songMap);
            if (value == 1) {
              playNext(mediaItem, context);
            }
            if (value == 2) {
              addToNowPlaying(context: context, mediaItem: mediaItem);
            }
            if (value == 3) {
              AddToPlaylist().addToPlaylist(context, mediaItem);
            }
          });
        }
        if (value == 6) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => YouTubePlaylist(
                playlistId: widget.data['albumId'].toString(),
                type: 'album',
              ),
            ),
          );
        }
      },
    );
  }
}
