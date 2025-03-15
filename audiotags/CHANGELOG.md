## 1.4.3

- Updated FRB to `2.7.0`
- Fixed tests

## 1.4.2

- Fix `ld: library 'macos' not found` (thanks @terrakok)

## 1.4.1

- Support Gradle 8 (thanks @josereia)
- Fix CI

## 1.4.0

**BREAKING**: `MimeType.none` is removed. Instead, `null` is used to indicate no mimetype.

- Update lofty dependency (thanks @dannyglover)
- Change Linux target to `x86_64-unknown-linux-musl`

## 1.3.0

**BREAKING**: `artist` is now `trackArtist`

- Add support for more metadata fields (thanks @dannyglover)
  - `albumArtist`
  - `discNumber`
  - `discTotal`

## 1.2.1

- Update `.pubignore`

## 1.2.0

- Add custom errors.
- Add support for `trackNumber` and `trackTotal` metadata.
- Fix Android libraries not being extracted during build.
- Update `lofty` dependency.

## 1.1.3

- Update `flutter_rust_bridge` version.

## 1.1.2

- Add CI/CD
- Download binaries from release assets.
- Specify exact `flutter_rust_bridge` version.

## 1.1.1

- BREAKING: Enum variants are camelCased.

## 1.1.0

- Improve support for pictures.

## 1.0.3

- Return null if the file does not have a tag.

## 1.0.2

- CI builds on older Ubuntu version to support older `glibc` versions.

## 1.0.1

- Fix typo in Linux CMakeLists

## 1.0.0

Initial release.
