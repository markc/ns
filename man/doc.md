# NetServa Documentation Browser

## Usage
```
ns doc [FILE]
ns docs [FILE]
```

## Description
Interactive documentation browser for NetServa.

Opens documentation in a terminal-based browser with clickable links for easy navigation through the documentation system.

## Arguments
- `FILE` - Path to markdown file (default: doc/README.md)

## Examples

### Basic Usage
```bash
# Open technical documentation index (default)
ns doc

# Open command reference index
ns doc man/README.md

# Open specific documentation
ns doc doc/deployment.md
ns doc man/mount.md
```

### Navigation
When in the documentation browser:
- **Arrow keys**: Navigate up/down
- **Right arrow/Enter**: Follow links
- **Left arrow**: Go back
- **q**: Quit browser
- **/**: Search
- **Space**: Next page

## Documentation Structure

The NetServa documentation is organized in two main directories:

### man/ Directory
Command reference and help files:
- Quick reference for all commands
- Usage examples
- Option descriptions

### doc/ Directory  
Technical documentation:
- Deployment guides
- Configuration tutorials
- Architecture documentation
- Development notes

## Alternative Viewers

You can also use these commands directly:
```bash
# Interactive browser (default)
cmark-gfm -t html man/README.md | lynx -stdin

# Formatted markdown viewer
glow -p man/README.md

# Simple text viewer
less doc/deployment.md
```

## Requirements
- `cmark-gfm` - CommonMark GFM parser
- `lynx` - Text web browser

Install with:
```bash
# Arch/CachyOS
sudo pacman -S cmark-gfm lynx

# Alpine
sudo apk add cmark lynx

# Debian/Ubuntu  
sudo apt install cmark-gfm lynx
```

## Related Commands
- `ns help` - Command-specific help
- `ns help <command>` - Detailed command help