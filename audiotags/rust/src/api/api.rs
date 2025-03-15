use super::{error::AudioTagsError, tag::Tag};
use lofty::{Accessor, AudioFile, ItemKey, Probe, TagExt, TaggedFile, TaggedFileExt};

/// Returns a `TaggedFile` at the given path.
fn get_file(path: &str) -> Result<TaggedFile, AudioTagsError> {
    match Probe::open(path) {
        Ok(file) => match file.read() {
            Ok(file) => Ok(file),
            Err(err) => Err(AudioTagsError::OpenFile {
                message: err.to_string(),
            }),
        },
        Err(_) => Err(AudioTagsError::InvalidPath),
    }
}

pub fn read(path: String) -> Result<Tag, AudioTagsError> {
    let file = get_file(&path)?;

    let tag = match file.primary_tag() {
        Some(primary_tag) => Ok(primary_tag),
        None => match file.first_tag() {
            Some(first_tag) => Ok(first_tag),
            None => Err(AudioTagsError::NoTags),
        },
    }?;

    let mut tag = Tag::from(tag);
    let duration = file.properties().duration().as_secs() as u32;
    tag.duration = Some(duration);

    Ok(tag)
}

pub fn write(path: String, data: Tag) -> Result<(), AudioTagsError> {
    let mut file = get_file(&path)?;

    // Remove the existing tags.
    for tag in file.tags() {
        if let Err(err) = tag.remove_from_path(&path) {
            return Err(AudioTagsError::Write {
                message: format!("Could not remove existing tag. {err:?}"),
            });
        }
    }

    // If there is no data to be written, then return.
    if data.is_empty() {
        return Ok(());
    }

    // Create a new tag.
    file.insert_tag(lofty::Tag::new(file.primary_tag_type()));
    let tag = file.primary_tag_mut().unwrap();

    // Title
    if let Some(title) = data.title {
        tag.insert_text(ItemKey::TrackTitle, title);
    }

    // Track Artist
    if let Some(track_artist) = data.track_artist {
        tag.insert_text(ItemKey::TrackArtist, track_artist);
    }

    // Album Title
    if let Some(album) = data.album {
        tag.insert_text(ItemKey::AlbumTitle, album);
    }

    // Album Artist
    if let Some(album_artist) = data.album_artist {
        tag.insert_text(ItemKey::AlbumArtist, album_artist);
    }

    // Year
    if let Some(year) = data.year {
        tag.set_year(year);
    }

    // Track number
    if let Some(track_number) = data.track_number {
        tag.set_track(track_number);
    }

    // Track total
    if let Some(track_total) = data.track_total {
        tag.set_track_total(track_total);
    }

    // Disc number
    if let Some(disc_number) = data.disc_number {
        tag.set_disk(disc_number);
    }

    // Disc total
    if let Some(disc_total) = data.disc_total {
        tag.set_disk_total(disc_total);
    }

    // Genre
    if let Some(genre) = data.genre {
        tag.insert_text(ItemKey::Genre, genre);
    }

    // Pictures
    for (i, picture) in data.pictures.into_iter().enumerate() {
        let mime_type = if let Some(picture_mime) = picture.mime_type {
            Some(picture_mime.into())
        } else {
            None
        };

        tag.set_picture(
            i,
            lofty::Picture::new_unchecked(
                picture.picture_type.into(),
                mime_type,
                None,
                picture.bytes,
            ),
        );
    }

    // Lyrics
    if let Some(lyrics) = data.lyrics {
        tag.insert_text(ItemKey::Lyrics, lyrics);
    }

    match tag.save_to_path(path) {
        Ok(_) => Ok(()),
        Err(err) => Err(AudioTagsError::Write {
            message: format!("Failed to write tag to file. {err:?}"),
        }),
    }
}
