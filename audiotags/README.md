# AudioTags

Read and write audio metadata in Flutter. Supports multiple formats.

## Usage

### Read

```dart
Tag? tag = await AudioTags.read(path);

String? title = tag?.title;
String? trackArtist = tag?.trackArtist;
String? album = tag?.album;
String? albumArtist = tag?.albumArtist;
String? genre = tag?.genre;
int? year = tag?.year;
int? trackNumber = tag?.trackNumber;
int? trackTotal = tag?.trackTotal;
int? discNumber = tag?.discNumber;
int? discTotal = tag?.discTotal;
int? duration = tag?.duration;
List<Picture>? pictures = tag?.pictures;
```

### Write

```dart
Tag tag = Tag(
    title: "Title",
    trackArtist: "Track Artist",
    album: "Album",
    albumArtist: "Album Artist",
    genre: "Genre",
    year: 2000,
    trackNumber: 1,
    trackTotal: 2,
    discNumber: 1,
    discTotal: 3,
    pictures: [
        Picture(
            bytes: Uint8List.fromList([0, 0, 0, 0]),
            mimeType: null,
            pictureType: PictureType.other
        )
    ]
);

AudioTags.write(path, tag);
```

## Supported Formats

This plugin uses a Rust crate called [`lofty`](https://github.com/Serial-ATA/lofty-rs) to write and read metadata.

The supported formats are listed [here](https://github.com/Serial-ATA/lofty-rs/blob/main/SUPPORTED_FORMATS.md).
