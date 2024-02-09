#!/bin/bash

dependencies=(git node npm rsvg-convert lc0 stockfish)

missing_commands=()

check_command() {
    local cmd=$1
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "✅ $cmd"
    else
        echo "❌ $cmd is not installed (or not in \$PATH)."
        if $cmd == "rsvg-convert"; then
            missing_commands+=("librsvg")
        else
            missing_commands+=("$cmd")
        fi
    fi
}

echo "⏳ Checking dependencies..."

for cmd in "${dependencies[@]}"; do
    check_command "$cmd"
done

check_install_homebrew() {
    echo "⏳ Checking if Homebrew is installed..."

    if ! command -v brew >/dev/null 2>&1; then
        echo "❌ Homebrew not found. Attempting to install..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        if [ -d "/opt/homebrew/bin" ]; then
            # For Apple silicon
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -d "/usr/local/bin/brew" ]; then
            # For Intel Mac
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        echo "✅ Homebrew is installed."
    fi
}

install_missing_dependencies() {
    for cmd in "${missing_commands[@]}"; do
        echo "Attempting to install $cmd with Homebrew..."
        if ! brew install "$cmd"; then
            echo "Could not install $cmd. You may need to manually install this package or check the package name in Homebrew."
        fi
    done
}

if [ ${#missing_commands[@]} -gt 0 ]; then
    echo -e "\n❌Some dependencies are missing: ${missing_commands[*]}\n"
    check_install_homebrew
    install_missing_dependencies
else
    echo -e "✅ All dependencies are met.\n"
fi

if [ -d "nibbler_src" ]; then
    echo "⏳ Deleting old Nibbler sources..."
    rm -rf "nibbler_src"
    echo -e "✅ Old Nibbler sources have been deleted.\n"
fi

if [ -d "Nibbler" ]; then
    echo "⏳ Deleting old Nibbler build folder..."
    rm -rf "Nibbler"
    echo -e "✅ Old Nibbler build folder has been deleted.\n"
fi

if [ -d "Nibbler.app" ]; then
    echo "⏳ Deleting old Nibbler build..."
    rm -rf "Nibbler.app"
    echo -e "✅ Old Nibbler build has been deleted.\n"
fi

echo "⏳ Cloning Nibbler sources..."
git clone git@github.com:rooklift/nibbler.git nibbler_src
echo -e "✅ Nibbler sources have been cloned.\n"

echo "⏳ Retrieving Nibbler version from Git tag..."
version=$(git -C nibbler_src describe --tags $(git -C nibbler_src rev-list --tags --max-count=1) | cut -c 2-)
echo -e "✅ $version\n"

echo "⏳ Creating empty electron app..."
npx create-electron-app Nibbler
echo -e "✅ Empty electron app has been created.\n"

cd Nibbler
rm -r src
cd ..
echo "⏳ Moving sources from repo to empty electron app..."
cp -r nibbler_src/files/src Nibbler/
echo -e "✅ Sources have been moved.\n"

echo "⏳ Converting SVG to PNGs..."
input_svg="nibbler_src/files/res/nibbler.svg"
iconset_name="Nibbler.iconset"
mkdir -p $iconset_name

sizes=(16 32 64 128 256 512)
for size in "${sizes[@]}"; do
    double_size=$((size * 2))
    rsvg-convert "$input_svg" -w "$size" -h "$size" -o "${iconset_name}/icon_${size}x${size}.png"
    rsvg-convert "$input_svg" -w "$double_size" -h "$double_size" -o "${iconset_name}/icon_${size}x${size}@2x.png"
done

echo -e "✅ SVG has been resized to required PNG sizes.\n"

echo "⏳ Converting PNGs to Apple iconset..."

iconutil -c icns "${iconset_name}"

echo -e "✅ Conversion to Apple Icon file complete.\n"

rm -rf $iconset_name

rm -rf nibbler_src

cd Nibbler/src
mv main.js index.js
cd ..

echo "⏳ Changing package.json version to Git tag from repository..."
sed -i '' "s/\"version\": \".*\"/\"version\": \"$version\"/" package.json
echo -e "✅ package.json version has been changed.\n"

echo "⏳ Creating Nibbler.app..."
npm run make
echo -e "✅ Nibbler.app has been created.\n"

mv out/nibbler-darwin-$(uname -m | sed 's/x86_64/x64/')/nibbler.app ../Nibbler.app
cd ..

echo "⏳ Replacing icon..."
mv nibbler.icns Nibbler.app/Contents/Resources/electron.icns
echo -e "✅ Icon replaced.\n"

echo "⏳ Attempting to delete build folder..."
sleep 1

if rm -rf Nibbler; then
    echo -e "✅ Build folder deleted.\n"
else
    error_code=$?
    if [ $error_code -eq 1 ]; then
        echo "Failed to delete the build folder due to permission denied."
    else
        echo "Failed to delete the build folder. Error code: $error_code"
    fi
fi

app_path="/Applications/Nibbler.app"

if [ -d "$app_path" ]; then
    echo "⚠️  Nibbler.app already exists in /Applications."

    old_app_path="/Applications/Nibbler_old.app"

    if [ -d "$old_app_path" ]; then
        echo -e "⚠️  Nibbler_old.app also found.\n⏳ Deleting Nibbler_old.app..."
        rm -rf "$old_app_path"
    fi

    echo "⏳ Renaming existing Nibbler.app to Nibbler_old.app..."
    mv "$app_path" "$old_app_path"
fi

echo "⏳ Moving Nibbler.app to /Applications..."
mv Nibbler.app /Applications
echo -e "✅ Nibbler.app moved to /Applications."

open /Applications/Nibbler.app
