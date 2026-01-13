# 0d3sa-utils

A collection of utility scripts and tools organized by category.

## Overview

This repository contains various command-line utilities and scripts for different purposes, organized into logical categories for easy navigation and maintenance.

## Repository Structure

```
0d3sa-utils/
├── security/          # Security and penetration testing tools
└── README.md          # This file
```

## Categories

### 🔒 Security

Security-related tools and utilities for network analysis, penetration testing, and security research.

#### Tools

- **[pcap-to-22000](security/pcap-to-22000/)** - Convert PCAP/PCAPNG files containing WPA/WPA2 handshakes to Hashcat-compatible `.22000` format
  - Recursively scans directories for capture files
  - Extracts WPA/WPA2 handshakes using `hcxtools`
  - Supports individual or combined output modes
  - Automatic dependency installation
  - See [detailed documentation](security/pcap-to-22000/README.md)

## Usage

Each tool in this repository is self-contained and includes its own documentation. Navigate to the tool's directory and refer to its README for specific usage instructions.

### Quick Start

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd 0d3sa-utils
   ```

2. Navigate to the tool you need:
   ```bash
   cd security/pcap-to-22000
   ```

3. Read the tool's README for usage instructions:
   ```bash
   cat README.md
   ```

## Contributing

When adding new tools to this repository:

1. **Organize by category** - Place tools in appropriate category directories
2. **Create a subdirectory** - Each tool should have its own directory
3. **Include documentation** - Add a README.md in the tool's directory
4. **Update this README** - Add your tool to the appropriate category section

### Adding a New Category

If you're adding a tool that doesn't fit existing categories:

1. Create a new top-level directory (e.g., `networking/`, `development/`, etc.)
2. Add the category to this README with a brief description
3. Follow the same structure as existing tools

## License

This repository is licensed under the **GNU General Public License v3.0** (GPL-3.0).

See the [LICENSE](LICENSE) file for the full license text.

### Summary

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

## Author

Maintained as part of the 0d3sa-utils collection.
