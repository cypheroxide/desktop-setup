# Flatpak Override Configurations

This directory contains optional Flatpak override configurations for the applications installed by the desktop setup.

## Usage

Copy the desired override files to `~/.local/share/flatpak/overrides/` or apply them using `flatpak override` commands.

## Available Overrides

### OBS Studio
- Enhanced filesystem access for recordings and streaming
- Access to additional hardware devices

### Spotify
- Basic overrides for better desktop integration

### Bottles
- Windows compatibility layer with necessary system access

### General Guidelines

1. **Filesystem Access**: Grant access to directories where you store content
2. **Hardware Access**: Allow access to webcams, microphones, etc. for media applications
3. **Network Access**: Most applications need network access, but you can restrict it if needed
4. **System Integration**: Enable desktop integration features

## Commands

### Apply an override:
```bash
flatpak override --user --filesystem=home com.obsproject.Studio
```

### View current overrides:
```bash
flatpak override --user --show
```

### Reset overrides:
```bash
flatpak override --user --reset com.obsproject.Studio
```

## Security Notes

- Only grant permissions that applications actually need
- Review overrides periodically
- Be cautious with `--filesystem=host` as it grants access to the entire filesystem
- Consider using specific directory paths instead of broad permissions

For more information, see the [Flatpak documentation](https://docs.flatpak.org/en/latest/sandbox-permissions.html).
