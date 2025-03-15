mod api;
mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */

#[cfg(test)]
mod tests {
    use crate::api::api;
    use crate::api::picture;
    use crate::api::tag::Tag;
    use anyhow::Context;
    use std::io::Read;

    fn read_tag_mp3() -> anyhow::Result<()> {
        let tag = api::read("samples/test.mp3".to_string()).context("Could not read tag.")?;

        println!("{:?}", tag.title);
        println!("{:?}", tag.track_artist);
        println!("{:?}", tag.album);
        println!("{:?}", tag.album_artist);
        println!("{:?}", tag.year);
        println!("{:?}", tag.track_number);
        println!("{:?}", tag.track_total);
        println!("{:?}", tag.disc_number);
        println!("{:?}", tag.disc_total);
        println!("{:?}", tag.genre);
        println!("{:?}", tag.lyrics);
        println!("{:?}", tag.duration);
        println!("{:?}", tag.pictures);

        Ok(())
    }

    #[test]
    fn clear_tag_mp3() {
        api::write(
            "samples/test.mp3".to_string(),
            Tag {
                title: None,
                track_artist: None,
                album: None,
                album_artist: None,
                year: None,
                genre: None,
                track_number: None,
                track_total: None,
                disc_number: None,
                disc_total: None,
                lyrics: None,
                duration: None,
                pictures: Vec::new(),
            },
        )
        .expect("Could not write tag.");

        assert!(read_tag_mp3().is_err());
    }

    #[test]
    fn write_tag_mp3() {
        let picture1 = picture::Picture::new(
            picture::PictureType::CoverFront,
            Some(picture::MimeType::Jpeg),
            std::fs::File::open("samples/picture1.jpg")
                .unwrap()
                .bytes()
                .map(|b| b.unwrap())
                .collect(),
        );

        let picture2 = picture::Picture::new(
            picture::PictureType::CoverBack,
            Some(picture::MimeType::Jpeg),
            std::fs::File::open("samples/picture2.jpg")
                .unwrap()
                .bytes()
                .map(|b| b.unwrap())
                .collect(),
        );

        api::write(
            "samples/test.mp3".to_string(),
            Tag {
                title: Some("Title".to_string()),
                track_artist: Some("Track Artist".to_string()),
                album: Some("Album".to_string()),
                album_artist: Some("Album Artist".to_string()),
                year: Some(2022),
                track_number: Some(1),
                track_total: Some(2),
                disc_number: Some(1),
                disc_total: Some(3),
                genre: Some("Genre".to_string()),
                lyrics: Some("Lyrics - test string".to_string()),
                pictures: vec![picture1, picture2],
                ..Default::default()
            },
        )
        .expect("Failed to write tag.");

        assert!(read_tag_mp3().is_ok());
    }

    fn read_tag_mp4() -> anyhow::Result<()> {
        let tag = api::read("samples/test.mp4".to_string()).context("Could not read tag.")?;

        println!("{:?}", tag.title);
        println!("{:?}", tag.track_artist);
        println!("{:?}", tag.album);
        println!("{:?}", tag.album_artist);
        println!("{:?}", tag.year);
        println!("{:?}", tag.track_number);
        println!("{:?}", tag.track_total);
        println!("{:?}", tag.disc_number);
        println!("{:?}", tag.disc_total);
        println!("{:?}", tag.genre);
        println!("{:?}", tag.lyrics);
        println!("{:?}", tag.duration);
        println!("{:?}", tag.pictures);

        Ok(())
    }

    #[test]
    fn clear_tag_mp4() {
        api::write(
            "samples/test.mp4".to_string(),
            Tag {
                title: None,
                track_artist: None,
                album: None,
                album_artist: None,
                year: None,
                genre: None,
                track_number: None,
                track_total: None,
                disc_number: None,
                disc_total: None,
                lyrics: None,
                duration: None,
                pictures: Vec::new(),
            },
        )
        .expect("Could not write tag.");

        assert!(read_tag_mp4().is_err());
    }

    #[test]
    fn write_tag_mp4() {
        let picture1 = picture::Picture::new(
            picture::PictureType::CoverFront,
            Some(picture::MimeType::Jpeg),
            std::fs::File::open("samples/picture1.jpg")
                .unwrap()
                .bytes()
                .map(|b| b.unwrap())
                .collect(),
        );

        let picture2 = picture::Picture::new(
            picture::PictureType::CoverBack,
            Some(picture::MimeType::Jpeg),
            std::fs::File::open("samples/picture2.jpg")
                .unwrap()
                .bytes()
                .map(|b| b.unwrap())
                .collect(),
        );

        api::write(
            "samples/test.mp4".to_string(),
            Tag {
                title: Some("Title".to_string()),
                track_artist: Some("Track Artist".to_string()),
                album: Some("Album".to_string()),
                album_artist: Some("Album Artist".to_string()),
                year: Some(2022),
                track_number: Some(1),
                track_total: Some(2),
                disc_number: Some(1),
                disc_total: Some(3),
                genre: Some("Genre".to_string()),
                lyrics: Some("Lyrics - test string".to_string()),
                pictures: vec![picture1, picture2],
                ..Default::default()
            },
        )
        .expect("Failed to write tag.");

        assert!(read_tag_mp4().is_ok());
    }
}
