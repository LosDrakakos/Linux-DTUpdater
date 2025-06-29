# Linux-DTUpdater

> Because running TexTools under Linux can be tricky, here's a bash script to upgrade TexTools and Penumbra modpacks for Dawntrail compatibilty in batch with parallel processing through CLI

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Bash-5+-brightgreen)](https://www.gnu.org/software/bash/)
[![GNU Parallel](https://img.shields.io/badge/GNU_parallel-Powered-lightgrey)](https://www.gnu.org/software/parallel/)

---

## Features

- **Recursive** scan of `.pmp` and `.ttmp2` files in the input directory  
- **Skips** files already processed to the output directory  
- **Parallel processing** with `GNU parallel`  
- Configurable via `.ini` or CLI arguments (CLI has priority)  
- Optional `--debug` mode for verbose logs  

---

## Required Setup

Before using `dtupdater.sh`, perform the following steps:

### 1. Download and Extract TexTools

Download **FFXIV TexTools** under zip format from the [GitHub Releases](https://github.com/TexTools/FFXIV_TexTools_UI/releases) and extract it to a directory of your choice.

To use the script with its default parameters, extract it to:

```
~/bin/FFXIV_TexTools/
```

Make sure `ConsoleTools.exe` is present at:

```
~/bin/FFXIV_TexTools/ConsoleTools.exe
```

### 2. Configure `console_config.json`

Inside the TexTools directory, create or edit the file with your game path:

```
~/bin/FFXIV_TexTools/console_config.json
```

Example contents (make sure the path matches your actual system):

```json
{
  "XivPath": "Z:\\home\\<your-username>\\.xlcore\\ffxiv\\game\\sqpack\\ffxiv",
  "Language": "en"
}
```

This is the default path if you're using XIVLauncher, else ensure you provide ConsoleTools with your actual game path.
If you're using a default XIVLauncher setup just replace `<your-username>` with your username. This file ensures ConsoleTools has the correct game install path and language.

### 3. Install .NET 4.8 with Winetricks

Using the **same Wine binaries and Wine prefix** as you use to run the game, install the required .NET runtime:

```
WINEPREFIX=~/.xlcore/wineprefix \
WINE=~/.xlcore/compatibilitytool/wine/unofficial-wine-xiv-staging-ntsync-10.10/bin/wine \
winetricks dotnet48
```

⚠️ **Important:** Back up your Wine prefix (`~/.xlcore/wineprefix`) before running this command, in case something goes wrong.

This step ensures that TexTools can run properly under Wine by providing the required .NET runtime environment.

---

## Requirements

Make sure these tools are installed:

- `bash` 5.x+
- `wine`
- `winetricks`
- `parallel` (GNU Parallel, it should be in your OS official repo)

---

## Quick Start

```bash
git clone https://github.com/yourusername/dtupdater.git
cd dtupdater
chmod +x dtupdater.sh
./dtupdater.sh --help
```

---

## Configuration

### `.ini` File

When first run, `dtupdater.sh` creates a config file at:

```
~/.local/dtupdater/dtupdater.ini
```

Example:

```ini
INPUT_DIR=~/Downloads/toconvert
OUTPUT_BASE=~/Downloads/converted
MAX_JOBS=4
WINEPREFIX=~/.xlcore/wineprefix
WINE_BINARY=~/.xlcore/compatibilitytool/wine/unofficial-wine-xiv-staging-ntsync-10.10/bin/wine
CONSOLE_TOOL=~/bin/FFXIV_TexTools/ConsoleTools.exe
```

You can modify it or override its values using CLI options.
If provided with CLI option at first run, these values will be used to populate the config instead of defaults values.
Be sure to check the if the `WINE_BINARY` Path exists, as I'm using a non default one from [here](https://github.com/rankynbass/unofficial-wine-xiv-git), and the current one I'm using is the default value.

---

## CLI Usage

```bash
./dtupdater.sh [options]
```

### Options

| Flag            | Description                                                                 |
|-----------------|-----------------------------------------------------------------------------|
| `--input`       | Input directory (default from `.ini`)                                       |
| `--output`      | Output base directory (default from `.ini`)                                 |
| `--wineprefix`  | Wine prefix to use                                                          |
| `--wine`        | Path to the Wine binary used for FFXIV                                      |
| `--tool`        | Path to the `ConsoleTools.exe`                                              |
| `--jobs`        | Number of parallel jobs (default: 4)                                        |
| `--debug`       | Enable verbose debug output                                                 |

---

## Example

```bash
./dtupdater.sh --debug \
  --input ~/Downloads/toconvert \
  --output ~/Downloads/converted \
  --wineprefix ~/.xlcore/wineprefix \
  --wine ~/.xlcore/compatibilitytool/wine/unofficial-wine-xiv-staging-ntsync-10.10/bin/wine \
  --tool ~/bin/FFXIV_TexTools/ConsoleTools.exe \
  --jobs 8
```

---

## How It Works

For each input file like:

```
~/Downloads/toconvert/mods/hair/customhair.pmp
```

It creates:

```
~/Downloads/converted/mods/hair/customhair.pmp
```

Calling:

```bash
WINEPREFIX=... wine ConsoleTools.exe /upgrade "Z:\..." "Z:\..."
```

Paths are automatically converted to Wine-friendly `Z:` equivalents.

---

## Notes

- Processes only `.pmp` and `.ttmp2` files  
- Input directory structure is replicated in the output  
- Debug logs are printed only when `--debug` is passed  
- Uses `GNU parallel` for high performance on multicore systems  

---

## Reporting Issues

If you encounter any bugs, unexpected behavior, or have feature suggestions, please [open an issue](https://github.com/LosDrakakos/Linux-DTUpdater/issues) on this repository.

When reporting a problem, include:

- Your operating system and version
- Wine version used
- The contents of your `dtupdater.ini` (omit any sensitive info)
- The full command you ran
- Terminal output with `--debug` enabled, if possible
- Try running the conversion manually to isolate issues with Wine or the tool:

```bash
WINEDEBUG=-all \
  WINEPREFIX=~/.xlcore/wineprefix \
  ~/.xlcore/compatibilitytool/wine/unofficial-wine-xiv-staging-ntsync-10.10/bin/wine \
  ~/bin/FFXIV_TexTools/ConsoleTools.exe \
  /upgrade "Z:\\home\\<user>\\Downloads\\toconvert\\example.ttmp2" \
           "Z:\\home\\<user>\\Downloads\\converted\\example.ttmp2"
```

Replace `<user>` with your actual Linux username, and `example.ttmp2` with a file you're trying to convert. This can help determine if the issue lies with TexTools, Wine, or the script itself.

Logs help me reproduce and resolve issues faster. Contributions and feedback are always welcome!

--

## License

This project is licensed under the **GNU General Public License v3.0**.  
See the [LICENSE](LICENSE) file for more information.

---

## Acknowledgements

- [FFXIV TexTools](https://www.ffxiv-textools.net/)  
- [GNU Parallel](https://www.gnu.org/software/parallel/)  
- The open-source Wine community
