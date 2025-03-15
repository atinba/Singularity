use lofty::{Accessor, ItemKey};

use super::picture::Picture;

/// Represents the metadata of the file.
#[derive(Default)]
pub struct Tag {
    /// The title of the song.
    pub title: Option<String>,
    /// The artist of the song.
    pub track_artist: Option<String>,
    /// The album the song is from.
    pub album: Option<String>,
    /// The artist of the album.
    pub album_artist: Option<String>,
    /// The year that this song was made.
    pub year: Option<u32>,
    /// The genre of the song.
    pub genre: Option<String>,
    /// The position of the song in a list.
    pub track_number: Option<u32>,
    /// The total amount of songs in a list.
    pub track_total: Option<u32>,
    /// The position of the disc in a list.
    pub disc_number: Option<u32>,
    /// The total amount of discs in a list.
    pub disc_total: Option<u32>,
    /// The lyrics of the song.
    pub lyrics: Option<String>,
    /// The duration of the song. Setting this field
    /// when writing will do nothing.
    pub duration: Option<u32>,
    /// All the pictures of the song.
    pub pictures: Vec<Picture>,
}

impl Tag {
    /// Returns `true` if the tag has no data.
    pub fn is_empty(&self) -> bool {
        self.title.is_none()
            && self.track_artist.is_none()
            && self.album.is_none()
            && self.album_artist.is_none()
            && self.year.is_none()
            && self.genre.is_none()
            && self.track_number.is_none()
            && self.track_total.is_none()
            && self.disc_number.is_none()
            && self.disc_total.is_none()
            && self.duration.is_none()
            && self.pictures.is_empty()
            && self.lyrics.is_none()
    }
}

impl From<&lofty::Tag> for Tag {
    fn from(tag: &lofty::Tag) -> Self {
        let pictures = tag
            .pictures()
            .iter()
            .map(|picture| {
                let mime_type = if let Some(picture_mime) = picture.mime_type() {
                    Some(picture_mime.clone().into())
                } else {
                    None
                };

                Picture::new(
                    picture.pic_type().into(),
                    mime_type,
                    picture.data().to_vec(),
                )
            })
            .collect::<Vec<Picture>>();

        Tag {
            title: tag.get_string(&ItemKey::TrackTitle).map(|e| e.to_string()),
            track_artist: tag.get_string(&ItemKey::TrackArtist).map(|e| e.to_string()),
            album: tag.get_string(&ItemKey::AlbumTitle).map(|e| e.to_string()),
            album_artist: tag.get_string(&ItemKey::AlbumArtist).map(|e| e.to_string()),
            year: tag.year(),
            genre: tag.get_string(&ItemKey::Genre).map(|e| e.to_string()),
            track_number: tag.track(),
            track_total: tag.track_total(),
            disc_number: tag.disk(),
            disc_total: tag.disk_total(),
            lyrics: tag.get_string(&ItemKey::Lyrics).map(|e| e.to_string()),
            pictures,
            duration: None,
        }
    }
}
