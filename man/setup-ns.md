# SETUP-NS(1) - NetServa Manual

## NAME
setup-ns - Install or update the NetServa management system

## SYNOPSIS
**setup-ns**

## DESCRIPTION
**setup-ns** is the installer script for the NetServa server management system. It clones or updates the NetServa repository from GitHub and configures the environment for immediate use.

The script performs the following actions:
- Checks if NetServa is already installed in ~/.ns
- If installed, updates the existing installation via git pull
- If not installed, clones the repository from GitHub
- Makes all scripts in bin/ executable
- Initializes the SSH manager configuration
- Updates ~/.bashrc to source NetServa functions on login

## INSTALLATION BEHAVIOR

### First-time Installation
1. Clones the NetServa repository to ~/.ns
2. Sets execute permissions on all bin/ scripts
3. Runs `sshm init` to set up SSH configuration structure
4. Adds NetServa initialization to ~/.bashrc (sources lib/nsrc.sh)

### Updates
If ~/.ns already exists, performs a git pull to update to the latest version.

## REQUIREMENTS
- **git** - Required for cloning and updating the repository
- **bash** - Shell environment
- Write access to $HOME directory

## EXIT STATUS
- **0** - Success
- **1** - Error (missing git or clone failure)

## FILES
- **~/.ns/** - NetServa installation directory
- **~/.ns/lib/nsrc.sh** - Main NetServa initialization file
- **~/.bashrc** - Modified to source NetServa nsrc.sh
- **~/.myrc** - User customization file (reloaded with 'es' alias)
- **~/.ssh/config.d/** - SSH configuration directory (created by sshm init)

## EXAMPLES
Install NetServa for the first time:
```bash
curl -s https://raw.githubusercontent.com/markc/ns/main/bin/setup-ns | bash
```

Update existing installation:
```bash
setup-ns
```

## AFTER INSTALLATION
After successful installation:
1. Run `source ~/.bashrc` to load NetServa functions
2. Use `ns help` to see available commands
3. Use `sethost` to configure environment variables
4. Use the `es` alias to reload configuration after changes to ~/.myrc

## SEE ALSO
**ns**(1), **sshm**(1), **mount**(1)

## AUTHOR
Mark Constable <mc@netserva.org>

## COPYRIGHT
Copyright (C) 1995-2025 Mark Constable (MIT License)