# NetServa Changelog

All notable changes to the NetServa project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure and core architecture
- Master `bin/ns` command-line interface with comprehensive help system
- Modular library system in `lib/` directory
- Enhanced `lib/nsrc.sh` master environment loader with:
  - Advanced OS detection (Alpine, Debian, Ubuntu, CachyOS, Manjaro, Arch, OpenWrt, macOS)
  - Architecture detection (x86_64, ARM64, ARMv7)
  - NetServa path auto-detection for development and deployment environments
  - Environment reload functionality for `es` alias integration
- Service management functions in `lib/services.sh` with multi-OS support
- Security testing integration in `lib/security.sh`
- Network and SSH mounting functions in `lib/network.sh`
- Comprehensive documentation in `doc/` directory with interactive browsing via `ns doc`
- Planning document `doc/plan.md` with architectural overview
- Color-coded logging system with multiple levels (ERROR, WARN, INFO, DEBUG)
- Dry-run capability for safe testing of operations
- Global configuration system via `lib/netserva.sh`
- Setup system with `ns setup` command for host initialization
- Comprehensive help system using Glow markdown renderer
- Interactive documentation browser using cmark-gfm and lynx
- **NetServa Path Variables**: Standardized 5-character naming convention:
  - `NSDIR` - NetServa Directory (root path)
  - `NSBIN` - NetServa Binaries (`$NSDIR/bin`)
  - `NSLIB` - NetServa Libraries (`$NSDIR/lib`)
  - `NSETC` - NetServa Configurations (`$NSDIR/etc`)
  - `NSDOC` - NetServa Documentation (`$NSDIR/doc`)
  - `NSMAN` - NetServa Manual pages (`$NSDIR/man`)
- **Host Configuration Variables**: Systematic 5-character naming organized by function:
  - Admin/Auth (A*): `ADMIN`, `AHOST`, `AMAIL`, `ANAME`, `APASS`, `A_GID`, `A_UID`
  - Config paths (C*): `CIMAP`, `CSMTP`, `C_DNS`, `C_FPM`, `C_SQL`, `C_SSL`, `C_WEB`
  - Database (D*): `DBMYS`, `DBSQL`, `DHOST`, `DNAME`, `DPASS`, `DPATH`, `DTYPE`, `DUSER`
  - System info (H*/O*/I*): `HDOMN`, `HNAME`, `IP4_0`, `OSMIR`, `OSREL`, `OSTYP`
  - User/Virtual (U*/V*): `UPASS`, `UPATH`, `UUSER`, `U_GID`, `U_UID`, `VHOST`, `VPATH`, `VUSER`
  - Web/WordPress (W*): `WPASS`, `WPATH`, `WPUSR`, `WUGID`
- **Configuration Persistence**: Host configs saved to `~/.vhosts/<hostname>` for:
  - Server provisioning with tailored configurations
  - Environment consistency across all NetServa tools
  - Auto-generated secure passwords for each service
  - OS-specific path adaptation (CachyOS, Alpine, Debian, etc.)

### Changed
- Updated `lib/netserva.sh` header with MIT License and new creation date
- Enhanced `lib/nsrc.sh` with comprehensive OS detection and path management
- Modified `lib/aliases.sh` to integrate `es` alias with `nsrc_reload()` function
- Refactored `lib/services.sh` to leverage existing `sc()` function for cross-platform compatibility
- Updated `bin/ns` to use `lib/nsrc.sh` for environment initialization
- Improved multi-OS support for OpenWrt, Alpine, and systemd-based systems

### Technical Details
- Created unified command routing system with getopt argument parsing
- Implemented dynamic library loading for modular functionality
- Added comprehensive error handling and logging framework
- Established consistent naming conventions for library functions
- Set up service detection for systemd services and LXC containers

### Documentation
- Created `CLAUDE.md` with comprehensive project guidance
- Added detailed architectural planning in `doc/plan.md`
- Established documentation standards for ongoing development

## [0.1.0] - 2025-07-21

### Added
- Initial project setup and directory structure
- Basic bin/, lib/, doc/, etc/, mnt/, tmp/ organization
- Core library files: `netserva.sh`, `functions.sh`, `aliases.sh`, `hostname.sh`
- SSH management script `bin/sshm` with comprehensive functionality
- TLS security testing tools: `tls-security-check.sh`, `tls-audit-report.sh`, `tls-quick-check.sh`
- Configuration templates for nginx, postfix, dovecot, powerdns
- Mount management scripts for SSH filesystem mounting
- Container management utilities

### Infrastructure
- CachyOS development environment setup
- Alpine/Debian target system support
- SSH key and host management framework
- Server mounting system via SSHFS with user mapping

### Legacy Integration
- Maintained compatibility with existing sh/hcp project patterns
- Preserved AGPL-3.0 licensed components where applicable
- Integrated proven configuration templates and utilities