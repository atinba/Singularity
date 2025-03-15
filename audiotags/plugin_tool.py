import argparse, re, os, shutil, sys

FRB_VERSION = "2.7.0"

parser = argparse.ArgumentParser(
    usage="Put this file in your root project directory and execute the commands.",
    description="A tool to help with building a Flutter plugin with Rust."
)

parser.add_argument(
    "-c", "--code-gen",
    action="store_true",
    help="Generates the FFI bridge using flutter_rust_bridge."
)

parser.add_argument(
    "-b", "--build",
    choices=["android", "linux", "windows", "ios", "macos"],
    nargs="*",
    help="Builds the Rust code. This will have to be run on Linux, Windows, and macOS if you want to target all platforms."
)

parser.add_argument(
    "--bump-version",
    type=str,
    help="Bumps the version of the plugin to the given version. Ex. \"1.0.0\""
)

def code_gen():
    print("Generating code with flutter_rust_bridge...\n")

    pubspec = open("./pubspec.yaml", "r+")
    lines = pubspec.readlines()
    for line in range(0, len(lines)):
        if "# rust_lib_audiotags" not in lines[line]:
            continue

        lines[line] = "  rust_lib_audiotags:\n"
        lines[line + 1] = "    path: rust_builder\n"
        pubspec.seek(0)
        pubspec.writelines(lines)
        pubspec.truncate()
        break
    pubspec.close()

    os.system(f"cargo install flutter_rust_bridge_codegen --version {FRB_VERSION}")
    os.system("cargo install cargo-expand --version 1.0.70")
    os.system("flutter_rust_bridge_codegen generate --config-file ./flutter_rust_bridge.yaml")

    pubspec = open("./pubspec.yaml", "r+")
    lines = pubspec.readlines()
    for line in range(0, len(lines)):
        if "rust_lib_audiotags" not in lines[line]:
            continue

        lines[line] = "  # rust_lib_audiotags:\n"
        lines[line + 1] = "  #   path: rust_builder\n"
        pubspec.seek(0)
        pubspec.writelines(lines)
        pubspec.truncate()
        break
    pubspec.close()


def build(targets: list[str]):
    print("Building Rust code...\n")

    package_name = open("./rust/Cargo.toml", "r").read().split("name = \"")[1].split("\"")[0]
    is_linux = sys.platform == "linux"
    is_windows = sys.platform == "win32"
    is_mac = sys.platform == "darwin"

    if (is_linux or is_windows or is_mac) and "android" in targets:
        print("Building Android libraries...\n")

        os.system("rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android")
        os.system("cargo install cargo-ndk")

        architectures = ["arm64-v8a", "armeabi-v7a", "x86", "x86_64"]
        for architecture in architectures:
            path = f"./android/src/main/jniLibs/{architecture}/lib{package_name}.so"
            if os.path.exists(path):
                os.remove(path)

        result = os.system("cd rust && cargo ndk -t arm64-v8a -t armeabi-v7a -t x86 -t x86_64 -o ../android/src/main/jniLibs build --release && cd ..")
        assert result == 0

    if is_linux and "linux" in targets:
        print("Building Linux libraries...\n")

        os.system("rustup target add x86_64-unknown-linux-musl")
        # https://github.com/rust-lang/cargo/issues/7154#issuecomment-561947609
        result = os.system('RUSTFLAGS="-C target-feature=-crt-static" cargo build --release --target x86_64-unknown-linux-musl --manifest-path ./rust/Cargo.toml')
        assert result == 0

        if os.path.exists(f"./linux/lib{package_name}.so"):
            os.remove(f"./linux/lib{package_name}.so")

        shutil.move(f"./rust/target/x86_64-unknown-linux-musl/release/lib{package_name}.so", f"./linux")

    if is_windows and "windows" in targets:
        print("Building Windows libraries...\n")

        os.system("rustup target add x86_64-pc-windows-msvc")
        result = os.system("cargo build --release --target x86_64-pc-windows-msvc --manifest-path ./rust/Cargo.toml")
        assert result == 0

        if os.path.exists(f"./windows/{package_name}.dll"):
            os.remove(f"./windows/{package_name}.dll")

        shutil.move(f"./rust/target/x86_64-pc-windows-msvc/release/{package_name}.dll", "./windows")

    if is_mac:
        if "macos" in targets:
            print("Building macOS libraries...\n")

            # Build for macOS.
            os.system("rustup target add aarch64-apple-darwin x86_64-apple-darwin")
            result = os.system("cargo build --release --target aarch64-apple-darwin --manifest-path ./rust/Cargo.toml")
            assert result == 0
            result = os.system("cargo build --release --target x86_64-apple-darwin --manifest-path ./rust/Cargo.toml")
            assert result == 0
            os.system(f'lipo "./rust/target/aarch64-apple-darwin/release/lib{package_name}.a" "./rust/target/x86_64-apple-darwin/release/lib{package_name}.a" -output "lib{package_name}.a" -create')

            if os.path.exists(f"./macos/Libs/lib{package_name}.a"):
                os.remove(f"./macos/Libs/lib{package_name}.a")

            os.makedirs("./macos/Libs", exist_ok=True)
            shutil.move(f"./lib{package_name}.a", "./macos/Libs")

        if "ios" in targets:
            # Build for iOS
            print("Building iOS libraries...\n")

            os.system("rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios")
            result = os.system("cargo build --release --target aarch64-apple-ios --manifest-path ./rust/Cargo.toml")
            assert result == 0

            result = os.system(f"cargo build --release --target aarch64-apple-ios-sim --manifest-path ./rust/Cargo.toml")
            assert result == 0

            result = os.system("CMAKE_OSX_SYSROOT=$(xcrun --sdk iphonesimulator --show-sdk-path) cargo build --release --target x86_64-apple-ios --manifest-path ./rust/Cargo.toml")
            assert result == 0
            os.system(f'lipo "./rust/target/aarch64-apple-ios-sim/release/lib{package_name}.a" "./rust/target/x86_64-apple-ios/release/lib{package_name}.a" -output "lib{package_name}.a" -create')
            os.system(f"xcodebuild -create-xcframework -library ./rust/target/aarch64-apple-ios/release/lib{package_name}.a -library ./lib{package_name}.a -output {package_name}.xcframework")
            os.remove(f"./lib{package_name}.a")

            if os.path.exists(f"./ios/Frameworks/{package_name}.xcframework"):
                shutil.rmtree(f"./ios/Frameworks/{package_name}.xcframework")

            os.makedirs("./ios/Frameworks", exist_ok=True)
            shutil.move(f"./{package_name}.xcframework", "./ios/Frameworks")


def bump_version(version: str):
    def replace_string_in_file(file, regex, replacement):
        new_text = re.sub(regex, replacement, file.read(), count=1)
        file.seek(0)
        file.write(new_text)
        file.seek(0)


    # pubspec.yaml
    pubspec = open("./pubspec.yaml", "r+")
    replace_string_in_file(pubspec, r"version: [\d|\.]+\s", f"version: {version}\n")
    pubspec.close()

    # Cargo.toml
    cargo = open("./rust/Cargo.toml", "r+")
    replace_string_in_file(cargo, r'version = "[\d|\.]+"\s', f'version = "{version}"\n')
    cargo.close()

    # Android CMake
    android_cmake = open("./android/CMakeLists.txt", "r+")
    replace_string_in_file(android_cmake, r'set\(Version "[\d|\.]+"\)\s', f'set(Version "{version}")\n')
    android_cmake.close()

    # Linux CMake
    linux_cmake = open("./linux/CMakeLists.txt", "r+")
    replace_string_in_file(linux_cmake, r'set\(Version "[\d|\.]+"\)\s', f'set(Version "{version}")\n')
    linux_cmake.close()

    # Windows CMake
    windows_cmake = open("./windows/CMakeLists.txt", "r+")
    replace_string_in_file(windows_cmake, r'set\(Version "[\d|\.]+"\)\s', f'set(Version "{version}")\n')
    windows_cmake.close()

    pubspec_text = open("./pubspec.yaml", "r").read()
    package_name = pubspec_text.split("name: ")[1].split("\n")[0].strip()

    # macOS podspec
    macos_podspec = open(f"./macos/{package_name}.podspec", "r+")
    replace_string_in_file(macos_podspec, r'version = "[\d|\.]+"\s', f'version = "{version}"\n')
    replace_string_in_file(macos_podspec, r"s\.version\s+= '[\d|\.]+'\s", f"s.version          = '{version}'\n")
    macos_podspec.close()

    # iOS podspec
    ios_podspec = open(f"./ios/{package_name}.podspec", "r+")
    replace_string_in_file(ios_podspec, r'version = "[\d|\.]+"\s', f'version = "{version}"\n')
    replace_string_in_file(ios_podspec, r"s\.version\s+= '[\d|\.]+'\s", f"s.version          = '{version}'\n")
    ios_podspec.close()


if __name__ == "__main__":
    args = parser.parse_args()

    if args.code_gen:
        code_gen()

    if args.build != None:
        targets = args.build
        if len(args.build) == 0:
            targets = ["android", "linux", "windows", "ios", "macos"]
        build(targets)

    if args.bump_version:
        bump_version(args.bump_version)