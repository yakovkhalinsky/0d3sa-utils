# pcap-to-22000.sh

A Bash script that recursively scans directories for PCAP/PCAPNG files containing WPA/WPA2 handshakes and converts them into Hashcat-compatible `.22000` format files.

## Overview

This script automates the process of extracting WPA/WPA2 handshakes from network capture files and converting them to a format that can be used with Hashcat for password cracking. It supports both individual output files (one per capture) and a combined output mode.

## Requirements

- **hcxtools** - Specifically the `hcxpcapngtool` utility
  - The script can automatically install this dependency (see [Dependency Management](#dependency-management))
  - Manual installation: `sudo apt-get install hcxtools` (Debian/Ubuntu)
  - Or build from source: https://github.com/ZerBea/hcxtools
- **Bash** 4.x or higher
- Standard Unix utilities: `find`, `grep`, `mktemp`, `basename`

## Installation

1. Clone or download this repository
2. The script is already executable and ready to use

## Dependency Management

The script automatically checks for required dependencies and can attempt to install them if missing. By default, the script will:

1. Check if `hcxpcapngtool` is available in your PATH
2. If missing, detect your package manager (apt, yum, dnf, pacman, zypper, or brew)
3. Attempt to install `hcxtools` using the appropriate package manager

### Supported Package Managers

- **apt** (Debian/Ubuntu) - `sudo apt-get install hcxtools`
- **yum** (RHEL/CentOS) - `sudo yum install hcxtools`
- **dnf** (Fedora) - `sudo dnf install hcxtools`
- **pacman** (Arch Linux) - `sudo pacman -S hcxtools`
- **zypper** (openSUSE) - `sudo zypper install hcxtools`
- **brew** (macOS) - `brew install hcxtools`

### Disabling Auto-Installation

If you prefer to install dependencies manually, use the `--no-auto-install` flag:

```bash
./pcap-to-22000.sh --no-auto-install /path/to/captures
```

This will check for dependencies and report what's missing, but won't attempt automatic installation.

## Usage

### Basic Usage

Process one or more directories containing PCAP files:

```bash
./pcap-to-22000.sh /path/to/captures
./pcap-to-22000.sh /path/to/dir1 /path/to/dir2 /path/to/dir3
```

### Options

- `-c, --combined` - Combine all extracted hashes into a single file named `hashes_22000.22000` (default: individual files)
- `--no-auto-install` - Skip automatic installation of missing dependencies
- `-h, --help` - Display help message and exit

### Examples

#### Example 1: Process a single directory (default mode)

```bash
./pcap-to-22000.sh ~/captures/
```

This will:
- Create a directory called `hashes_22000/`
- Generate one `.22000` file per capture file that contains a valid handshake
- Files are named based on the original capture filename

#### Example 2: Combine all hashes into one file

```bash
./pcap-to-22000.sh -c ~/captures/
```

This will:
- Create a single file `hashes_22000.22000` containing all extracted hashes
- Useful when you want to crack multiple networks at once

#### Example 3: Process multiple directories

```bash
./pcap-to-22000.sh ~/captures/2024/ ~/captures/2023/ ~/old_captures/
```

The script will recursively search all specified directories for PCAP files.

## Output

### Default Mode (Individual Files)

- **Output directory**: `hashes_22000/`
- **File naming**: `<original-capture-name>.22000`
- Only files with valid WPA/WPA2 handshakes are created
- Empty or invalid captures are automatically skipped

### Combine Mode (`-c, --combined` flag)

- **Output file**: `hashes_22000.22000`
- All valid hashes from all processed captures are appended to this single file
- If no hashes are found, the file is automatically removed

## Output Messages

The script provides visual feedback during processing:

- `✔` - Successfully extracted hash from capture
- `✖` - No WPA/WPA2 hash found in capture
- `⚠` - Error processing capture (corrupt file, permission issue, etc.)

## Supported File Formats

- `.pcap` files
- `.pcapng` files
- Case-insensitive matching (e.g., `.PCAP`, `.PcapNG`)

## How It Works

1. **Recursive Search**: The script uses `find` to recursively locate all `.pcap` and `.pcapng` files in the specified directories
2. **Hash Extraction**: Each capture file is processed with `hcxpcapngtool --all` which attempts to extract:
   - PMKID hashes
   - Full 4-way handshake data
3. **Validation**: Only files containing valid WPA/WPA2 hashes (identified by `^WPA*` prefix) are kept
4. **Output**: Hashes are written in Hashcat 22000 format for direct use with Hashcat

## Hashcat Usage

After generating `.22000` files, you can use them with Hashcat:

```bash
# Crack a single hash file
hashcat -m 22000 hashes_22000/capture.22000 wordlist.txt

# Crack combined file
hashcat -m 22000 hashes_22000.22000 wordlist.txt
```

## Script Structure

The script is organized into a modular architecture with separate function files:

### Main Script
- `pcap-to-22000.sh` - Main entry point that sources all modules and orchestrates execution

### Library Modules (`lib/` directory)

- **`lib/config.sh`** - Global configuration variables
  - `OUTDIR`, `COMBINE`, `DIRS`, `COMBINED_FILE`

- **`lib/usage.sh`** - Usage and help functions
  - `usage()` - Display help information and exit

- **`lib/options.sh`** - Command-line option parsing
  - `parse_options()` - Parse command-line arguments

- **`lib/validation.sh`** - Input validation
  - `validate_inputs()` - Validate that directories are provided

- **`lib/dependencies.sh`** - Dependency management
  - `check_dependencies()` - Check and optionally install missing dependencies
  - `command_exists()` - Check if a command is available
  - `detect_package_manager()` - Detect available package manager
  - `install_hcxtools()` - Install hcxtools using detected package manager

- **`lib/output.sh`** - Output management
  - `setup_output()` - Initialize output directory or combined file
  - `print_summary()` - Display final statistics

- **`lib/processing.sh`** - File processing functions
  - `process_capture_file()` - Process a single PCAP file
  - `process_directory()` - Process all captures in a directory

This modular structure makes the codebase easier to maintain, test, and extend. Each module has a single, well-defined responsibility.

## Troubleshooting

### "hcxpcapngtool: command not found"

The script will attempt to install hcxtools automatically. If auto-installation fails or you prefer manual installation:

**Debian/Ubuntu:**
```bash
sudo apt-get install hcxtools
```

**RHEL/CentOS:**
```bash
sudo yum install hcxtools
```

**Fedora:**
```bash
sudo dnf install hcxtools
```

**Arch Linux:**
```bash
sudo pacman -S hcxtools
```

**macOS (Homebrew):**
```bash
brew install hcxtools
```

For other systems or to build from source, visit: https://github.com/ZerBea/hcxtools

### "No WPA/WPA2 hash found"

This means the capture file doesn't contain a valid WPA/WPA2 handshake. The capture may:
- Not contain any wireless traffic
- Contain only encrypted traffic without handshake
- Be corrupted or incomplete

### Permission Errors

Ensure you have:
- Read permissions on input directories and files
- Write permissions in the current directory (for output)

## License

MIT License - See script header for details

## Author

ChatGPT (2024-01-11)
