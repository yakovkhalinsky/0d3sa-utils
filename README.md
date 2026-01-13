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

3. Make the script executable (if needed):
   ```bash
   chmod +x pcap-to-22000.sh
   ```

4. Read the tool's README for usage instructions:
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

Individual tools may have their own licenses. Check each tool's directory for license information.

## Author

Maintained as part of the 0d3sa-utils collection.
