
import 'dart:convert';

import 'package:audiotags/audiotags.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:singularity/APIs/spotify_api.dart';
import 'package:singularity/Helpers/matcher.dart';
import 'package:singularity/Helpers/spotify_helper.dart';

// ignore: avoid_classes_with_only_static_members
class Lyrics {
  static Future<Map<String, String>> getLyrics({
    required String id,
    required String title,
    required String artist,
    required String album,
    required String duration,
    required bool saavnHas,
    int iteration = 0,
  }) async {
    final Map<String, String> result = {
      'lyrics': '',
      'type': 'text',
      'source': '',
      'id': id,
    };

    if (iteration == 0) {
      Logger.root.info('Getting Synced Lyrics');
      // final res = await getSpotifyLyrics(title, artist);
      final res = await getLrclibLyrics(title, artist, album, duration);
      result['lyrics'] = res['lyrics']!;
      result['type'] = res['type']!;
      result['source'] = res['source']!;
    }
    if (result['lyrics'] == '') {
      Logger.root.info('Synced Lyrics, not found. Getting text lyrics');
      if (saavnHas) {
        Logger.root.info('Getting Lyrics from Saavn');
        result['lyrics'] = await getSaavnLyrics(id);
        result['type'] = 'text';
        result['source'] = 'Jiosaavn';
        if (result['lyrics'] == '') {
          final res = await getLyrics(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            saavnHas: false,
            iteration: iteration + 1,
          );
          result['lyrics'] = res['lyrics']!;
          result['type'] = res['type']!;
          result['source'] = res['source']!;
        }
      } else {
        Logger.root
            .info('Lyrics not available on Saavn, finding on Musixmatch');
        result['lyrics'] =
            await getMusixMatchLyrics(title: title, artist: artist);
        result['type'] = 'text';
        result['source'] = 'Musixmatch';
        if (result['lyrics'] == '') {
          Logger.root
              .info('Lyrics not found on Musixmatch, searching on Google');
          result['lyrics'] =
              await getGoogleLyrics(title: title, artist: artist);
          result['type'] = 'text';
          result['source'] = 'Google';
        }
      }
    }
    return result;
  }

  static Future<String> getSaavnLyrics(String id) async {
    try {
      final Uri lyricsUrl = Uri.https(
        'www.jiosaavn.com',
        '/api.php?__call=lyrics.getLyrics&lyrics_id=$id&ctx=web6dot0&api_version=4&_format=json',
      );
      final Response res =
          await get(lyricsUrl, headers: {'Accept': 'application/json'});

      final List<String> rawLyrics = utf8.decode(res.bodyBytes).split('-->');
      Map fetchedLyrics = {};
      if (rawLyrics.length > 1) {
        fetchedLyrics = json.decode(rawLyrics[1]) as Map;
      } else {
        fetchedLyrics = json.decode(rawLyrics[0]) as Map;
      }
      final String lyrics = fetchedLyrics['lyrics']
              ?.toString()
              .replaceAll('<br>', '\n')
              .replaceAll(RegExp('[ ]{2,}'), ' ') ??
          '';
      return lyrics;
    } catch (e) {
      Logger.root.severe('Error in getSaavnLyrics', e);
      return '';
    }
  }

  static Future<Map<String, String>> getLrclibLyrics(
    String track,
    String artist,
    String album,
    String duration,
  ) async {
    final Map<String, String> result = {
      'lyrics': '',
      'type': 'lrc',
      'source': 'Lrclib',
    };

    final Uri lyricsUrl = Uri.https('lrclib.net', '/api/get', {
      'track_name': track,
      'artist_name': artist,
      'album_name': album,
      'duration': duration,
    });
    final Response res =
        await get(lyricsUrl, headers: {'Accept': 'application/json'});
    if (res.statusCode == 200) {
      final Map lyricsData =
          await json.decode(utf8.decode(res.bodyBytes)) as Map;
      if (lyricsData['error'] == null) {
        if (lyricsData['syncedLyrics'] != null &&
            lyricsData['syncedLyrics'] != '') {
          result['lyrics'] = lyricsData['syncedLyrics'].toString();
        } else {
          result['lyrics'] = lyricsData['plainLyrics']
                  ?.toString()
                  .replaceAll(RegExp('[ ]{2,}'), ' ') ??
              '';
          result['type'] = 'text';
        }
        return result;
      }
    } else {
      if (res.statusCode != 404) {
        Logger.root.severe(
          'getLrclibLyrics returned ${res.statusCode}',
          res.body,
        );
      }
    }
    return result;
  }

  static Future<Map<String, String>> getSpotifyLyrics(
    String title,
    String artist,
  ) async {
    final Map<String, String> result = {
      'lyrics': '',
      'type': 'text',
      'source': 'Spotify',
    };
    await callSpotifyFunction(
      function: (String accessToken) async {
        final value = await SpotifyApi().searchTrack(
          accessToken: accessToken,
          query: '$title - $artist',
          limit: 1,
        );
        try {
          // Logger.root.info(jsonEncode(value['tracks']['items'][0]));
          if (value['tracks']['items'].length == 0) {
            Logger.root.info('No song found');
            return result;
          }
          String title2 = '';
          String artist2 = '';
          try {
            title2 = value['tracks']['items'][0]['name'].toString();
            artist2 =
                value['tracks']['items'][0]['artists'][0]['name'].toString();
          } catch (e) {
            Logger.root.severe(
              'Error in extracting artist/title in getSpotifyLyrics for $title - $artist',
              e,
            );
          }
          final trackId = value['tracks']['items'][0]['id'].toString();
          if (matchSongs(
            title: title,
            artist: artist,
            title2: title2,
            artist2: artist2,
          ).matched) {
            final Map<String, String> res =
                await getSpotifyLyricsFromId(trackId);
            result['lyrics'] = res['lyrics']!;
            result['type'] = res['type']!;
            result['source'] = res['source']!;
          } else {
            Logger.root.info('Song not matched');
          }
        } catch (e) {
          Logger.root.severe('Error in getSpotifyLyrics', e);
        }
      },
      forceSign: false,
    );
    return result;
  }

  static Future<Map<String, String>> getSpotifyLyricsFromId(
    String trackId,
  ) async {
    final Map<String, String> result = {
      'lyrics': '',
      'type': 'text',
      'source': 'Spotify',
    };
    try {
      final Uri lyricsUrl =
          Uri.https('spotify-lyric-api-984e7b4face0.herokuapp.com', '/', {
        'trackid': trackId,
        'format': 'lrc',
      });
      final Response res =
          await get(lyricsUrl, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final Map lyricsData =
            await json.decode(utf8.decode(res.bodyBytes)) as Map;
        if (lyricsData['error'] == false) {
          final List lines = await lyricsData['lines'] as List;
          if (lyricsData['syncType'] == 'LINE_SYNCED') {
            result['lyrics'] = lines
                .map((e) => '[${e["timeTag"]}]${e["words"]}')
                .toList()
                .join('\n');
            result['type'] = 'lrc';
          } else {
            result['lyrics'] = lines.map((e) => e['words']).toList().join('\n');
            result['type'] = 'text';
          }
        }
      } else {
        Logger.root.severe(
          'getSpotifyLyricsFromId returned ${res.statusCode}',
          res.body,
        );
      }
      return result;
    } catch (e) {
      Logger.root.severe('Error in getSpotifyLyrics', e);
      return result;
    }
  }

  static Future<String> getGoogleLyrics({
    required String title,
    required String artist,
  }) async {
    const String url =
        'https://www.google.com/search?client=safari&rls=en&ie=UTF-8&oe=UTF-8&q=';
    const String delimiter1 =
        '</div></div></div></div><div class="hwc"><div class="BNeawe tAd8D AP7Wnd"><div><div class="BNeawe tAd8D AP7Wnd">';
    const String delimiter2 =
        '</div></div></div></div></div><div><span class="hwc"><div class="BNeawe uEec3 AP7Wnd">';
    String lyrics = '';
    try {
      lyrics = utf8.decode(
        (await get(
          Uri.parse(Uri.encodeFull('$url$title by $artist lyrics')),
        ))
            .bodyBytes,
      );
      lyrics = lyrics.split(delimiter1).last;
      lyrics = lyrics.split(delimiter2).first;
      if (lyrics.contains('<meta charset="UTF-8">')) throw Error();
    } catch (_) {
      try {
        lyrics = utf8.decode(
          (await get(
            Uri.parse(
              Uri.encodeFull('$url$title by $artist song lyrics'),
            ),
          ))
              .bodyBytes,
        );
        lyrics = lyrics.split(delimiter1).last;
        lyrics = lyrics.split(delimiter2).first;
        if (lyrics.contains('<meta charset="UTF-8">')) throw Error();
      } catch (_) {
        try {
          lyrics = utf8.decode(
            (await get(
              Uri.parse(
                Uri.encodeFull(
                  '$url${title.split("-").first} by $artist lyrics',
                ),
              ),
            ))
                .bodyBytes,
          );
          lyrics = lyrics.split(delimiter1).last;
          lyrics = lyrics.split(delimiter2).first;
          if (lyrics.contains('<meta charset="UTF-8">')) throw Error();
        } catch (_) {
          lyrics = '';
        }
      }
    }
    return lyrics.trim().replaceAll(RegExp('[ ]{2,}'), ' ');
  }

  static Future<String> getOffLyrics(String path) async {
    try {
      final Tag? tags = await AudioTags.read(path);
      return tags?.lyrics ?? '';
    } catch (e) {
      return '';
    }
  }

  static Future<String> getLyricsLink(String song, String artist) async {
    const String authority = 'www.musixmatch.com';
    final String unencodedPath = '/search/$song $artist';
    final Response res = await get(Uri.https(authority, unencodedPath));
    if (res.statusCode != 200) return '';
    final RegExpMatch? result =
        RegExp(r'href=\"(\/lyrics\/.*?)\"').firstMatch(res.body);
    return result == null ? '' : result[1]!;
  }

  static Future<String> scrapLink(String unencodedPath) async {
    Logger.root.info('Trying to scrap lyrics from $unencodedPath');
    const String authority = 'www.musixmatch.com';
    final Response res = await get(Uri.https(authority, unencodedPath));
    if (res.statusCode != 200) return '';
    final List<String?> lyrics = RegExp(
      r'<span class=\"lyrics__content__ok\">(.*?)<\/span>',
      dotAll: true,
    ).allMatches(utf8.decode(res.bodyBytes)).map((m) => m[1]).toList();

    return lyrics.isEmpty ? '' : lyrics.join('\n');
  }

  static Future<String> getMusixMatchLyrics({
    required String title,
    required String artist,
  }) async {
    try {
      final String link = await getLyricsLink(title, artist);
      Logger.root.info('Found Musixmatch Lyrics Link: $link');
      final String lyrics = await scrapLink(link);
      return lyrics.replaceAll(RegExp('[ ]{2,}'), ' ');
    } catch (e) {
      Logger.root.severe('Error in getMusixMatchLyrics', e);
      return '';
    }
  }
}
