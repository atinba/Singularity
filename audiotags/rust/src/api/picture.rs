use std::fmt::Debug;

/// An object representing a picture metadata.
pub struct Picture {
    /// The type of picture (ex. front cover)
    pub picture_type: PictureType,
    /// The mime type of the picture (ex. `image/jpg`)
    pub mime_type: Option<MimeType>,
    /// The picture data, in bytes.
    pub bytes: Vec<u8>,
}

impl Picture {
    pub fn new(picture_type: PictureType, mime_type: Option<MimeType>, bytes: Vec<u8>) -> Self {
        Picture {
            picture_type,
            mime_type,
            bytes,
        }
    }
}

impl Debug for Picture {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Picture")
            .field("picture_type", &self.picture_type)
            .field("format", &self.mime_type)
            .field("bytes", &self.bytes.len())
            .finish()
    }
}

/// Implements the `From` trait to allow the `lofty` enums to be converted.
macro_rules! impl_enum_from
{
    ($from_enum:ty, $for_enum:ty; $($variant:ident),+) => {
        impl From<$from_enum> for $for_enum {
            fn from(value: $from_enum) -> Self {
                match value {
                    $(<$from_enum>::$variant => <$for_enum>::$variant),*
                }
            }
        }

        impl From<$for_enum> for $from_enum {
            fn from(value: $for_enum) -> Self {
                match value {
                    $(<$for_enum>::$variant => <$from_enum>::$variant),*
                }
            }
        }
    };

    ($from_enum:ty, $for_enum:ty, $default_variant:ident; $($variant:ident),+) => {
        impl From<$from_enum> for $for_enum {
            fn from(value: $from_enum) -> Self {
                match value {
                    $(<$from_enum>::$variant => <$for_enum>::$variant),*,
                    _ => <$for_enum>::$default_variant
                }
            }
        }

        impl From<$for_enum> for $from_enum {
            fn from(value: $for_enum) -> Self {
                match value {
                    $(<$for_enum>::$variant => <$from_enum>::$variant),*,
                }
            }
        }
    };
}

// Almost the same as lofty's PictureType except without
// the undefined type.
/// The type of picture of the song.
#[derive(Debug)]
pub enum PictureType {
    Other,
    Icon,
    OtherIcon,
    CoverFront,
    CoverBack,
    Leaflet,
    Media,
    LeadArtist,
    Artist,
    Conductor,
    Band,
    Composer,
    Lyricist,
    RecordingLocation,
    DuringRecording,
    DuringPerformance,
    ScreenCapture,
    BrightFish,
    Illustration,
    BandLogo,
    PublisherLogo,
}

impl_enum_from!(
    lofty::PictureType,
    PictureType,
    Other;
    Other,
    Icon,
    OtherIcon,
    CoverFront,
    CoverBack,
    Leaflet,
    Media,
    LeadArtist,
    Artist,
    Conductor,
    Band,
    Composer,
    Lyricist,
    RecordingLocation,
    DuringRecording,
    DuringPerformance,
    ScreenCapture,
    BrightFish,
    Illustration,
    BandLogo,
    PublisherLogo
);

// The same as lofty's MimeType.
// TODO: Support unknown type (code gen doesn't work for it) https://github.com/fzyzcjy/flutter_rust_bridge/issues/1073
/// The MIME type of the picture.
#[derive(Debug)]
pub enum MimeType {
    Png,
    Jpeg,
    Tiff,
    Bmp,
    Gif,
    // An unknown mimetype. Represented by the string.
    // Unknown(String),
}

impl_enum_from!(
    lofty::MimeType,
    MimeType,
    Png;
    Png,
    Jpeg,
    Tiff,
    Bmp,
    Gif
);
