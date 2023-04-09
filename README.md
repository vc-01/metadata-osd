# Metadata OSD script for mpv player

This script adds metadata OSD (on-screen display) to mpv.

![Screenshot](sshots/sshot_osd_1.png)

<sub>* Screenshot taken on a packaged mpv on Arch Linux; font type and size may vary on other platforms.</sub>

## Installation & Configuration

Download & place [metadata_osd.lua](scripts/metadata_osd.lua?raw=true) script into

- `$XDG_CONFIG_HOME/mpv/scripts` (it will be most of the times `~/.config/mpv/scripts`) on Linux, or
- `%APPDATA%\mpv\scripts` on Windows

for autoload.

(_Optional_) Config file with user settings named `metadata_osd.conf` can be created in

- `$XDG_CONFIG_HOME/mpv/script-opts` on Linux, or
- `%APP‐DATA%\mpv\script-opts` on Windows

See the example configuration file [metadata_osd.conf](script-opts/metadata_osd.conf?raw=true) in this repo for available user config options.

## Key Bindings

The following table summarizes the script's default key bindings and their config options:

| Key           | Action                                | Config Option Name    | Binding Name (for input.conf) |
| -------------:|:------------------------------------- |:--------------------- |:----------------------------- |
| <kbd>F1</kbd> | Master enable / disable (killswitch)  | key_toggleenable      | toggleenable                  |
| <kbd>F5</kbd> | Enable / disable the autohide feature | key_toggleautohide    | toggleautohide                |
| _unassigned_  | Show / hide OSD-1                     | key_toggleosd_1       | toggleosd_1                   |
| _unassigned_  | Show / hide OSD-2                     | key_toggleosd_2       | toggleosd_2                   |
| <kbd>F6</kbd> | Reset any user-toggled switches       | key_reset_usertoggled | reset_usertoggled             |
| _unassigned_  | Show status OSD                       | key_showstatusosd     | showstatusosd                 |

Key bindings can be configured either via script's config file, see [metadata_osd.conf](script-opts/metadata_osd.conf?raw=true) example with pre-filled defaults, or via _input.conf_.

Default bindings in _input.conf_ format are listed below again for clarity:

```
F1 script-binding metadata_osd/toggleenable
F5 script-binding metadata_osd/toggleautohide
#<unassigned> script-binding metadata_osd/toggleosd_1
#<unassigned> script-binding metadata_osd/toggleosd_2
F6 script-binding metadata_osd/reset_usertoggled
#<unassigned> script-binding metadata_osd/showstatusosd
```

## Per media-type enable / autohide

OSD enabled state or auto-hiding after a delay can be triggered either manually by pressing the relevant key (see _key_toggleenable_ and _key_toggleautohide_ [above](#key-bindings)) or determined algorithmically based on the currently playing media type and its related config options settings.

OSD is enabled by default for audio and video media, disabled while viewing pictures. Autohide feature is enabled for video, autohide is disabled (that is, the OSD will stay visible) while playing music, as well as for music files with cover art image.

Currently recognizable media types are namely: _audio_, _audio_withalbumart_, _video_, _image_.

Config options for per media-type OSD enable and autohide are cumulatively:

* _enable_for\_<media_type\>_ (yes/no)
* _autohide_for\_<media_type\>_ (yes/no)

If user presses a button to toggle enable / disable the OSD or the autohide feature, it will override the automatic determining until reset back by presssing a key specified by:

* _key_reset_usertoggled_ / _reset_usertoggled_ (F6) (see [above](#key-bindings))

## Current Chapter & Track Number

Current chapter number (disabled by default) can be enabled by configuration setting:

`show_chapternumber=yes`

See example screenshot below:

![Chapter Number](sshots/sshot_chapternumber.png)

Same goes for album track number (disabled by default):

`show_albumtracknumber=yes`

See example screenshot below:

![Album Track Number](sshots/sshot_albumtracknumber.png)

_Note_: Album track number is scarcely present in metadata, this can give mixed results.

Current playlist position if the setting above is activated is moved one line down and put between square brackets.

For both options, if the chapter and/or track number is equal to the current playlist position, the values are conflated (to avoid duplicity). Only for this particular setting, if playlist items tally to *1*, playlist position is omitted and substituted for chapter and/or track number.

## Program Design & Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) (not a necessary read for program use).
