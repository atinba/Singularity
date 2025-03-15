#[derive(Debug)]
pub enum AudioTagsError {
    InvalidPath,
    NoTags,
    OpenFile { message: String },
    Write { message: String },
}

impl std::error::Error for AudioTagsError {}

impl std::fmt::Display for AudioTagsError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self)
    }
}
