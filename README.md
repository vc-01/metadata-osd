# Metadata OSD for mpv player
This script adds metadata OSD (on-screen display) to mpv.

![Screenshot](screenshot.png)

## Installation & Configuration
Download & place the [metadata_osd.lua](scripts/metadata_osd.lua?raw=true) script in

- `$XDG_CONFIG_HOME/mpv/scripts` (it will be most of the times `~/.config/mpv/scripts`) in Linux, or
- `%APPDATA%\mpv\scripts` in Windows

for autoload.

(_Optional_) Config file with user settings named `metadata_osd.conf` can be put in

- `$XDG_CONFIG_HOME/mpv/script-opts` in Linux, or
- `%APP‐DATA%\mpv\script-opts` in Windows

See the example config file [metadata_osd.conf](script-opts/metadata_osd.conf?raw=true) in this repo.

Configuration options (and their defaults in parenthesis) picked to mention are the following:

* _enable_on_start_ (yes) - enable OSD on mpv start
* _enable_osd_2_ (yes) - enable / disable OSD-2 altogether
* _key_toggleenable_ (F1) - master enable / disable switch key (killswitch)
* _key_toggleautohide_ (F5) - switch key to enable / disable the autohide feature
* _key_toggleosd_1_ (_unassigned_) - key to show / hide OSD-1 (current autohide state applies)
* _key_toggleosd_2_ (_unassigned_) - key to show / hide OSD-2 (current autohide state applies & OSD-2 needs to be enabled in settings & needs to have data)
* _autohide_timeout_sec_ (5) - OSD autohide delay in seconds

## Per media-type enable / autohide
OSD enabled state or auto-hiding after a delay can be triggered either manually by pressing the relevant key (see _key_toggleenable_ and _key_toggleautohide_ above) or determined algorithmically based on the currently playing media type and its related config options settings.

OSD is enabled by default for audio and video media, disabled while viewing pictures. Autohide feature is enabled for video, autohide is disabled (that is, the OSD will stay visible) while playing music, as well as for music files with cover art image.

Currently recognizable media types are namely: _audio_, _audio_withalbumart_, _video_, _image_.

Config options for per media-type OSD enable and autohide are cumulatively:

* _enable_for\_<media_type\>_ (yes/no)
* _autohide_for\_<media_type\>_ (yes/no)

If user presses a button to toggle enable / disable the OSD or the autohide feature, it will override the automatic determining until reset back by presssing a key specified by:

* _key_reset_usertoggled_ (F6)

## Program design
Below is the program design documentation (not necessary to read for program use).

### Metadata selection
- If the currently playing file is not a video file and has internal **chapters**, these are preferred and shown on the OSD, otherwise file metadata is selected and shown.

	- _Rationale_: Implemented to support music files accompanied with a .cue file where each album track is technically a chapter.

- If autohide is enabled and chapter metadata is available, a second OSD (OSD-2) will show up after OSD-1 had been auto-hidden. In the event of a chapter change during playback, only the second OSD (OSD-2) with chapter title will show up.

	- _Rationale_: Chapter metadata for video files could have been integrated into OSD-1, but displaying the whole dataset repeatedly is disturbing.

- Directory / file name fallback for files with no metadata.

	- _Rationale_: File name and directory name often carry similar information as the per file-format specific metadata. This approach works for media collections organized as e.g.:
		- `<Artist>/<Album>/<Song>` or
		- `<Multimedia_dir>/<Artist - Album>/<Song>`
	- This can be a topic of further changes.

### Partial Functional UML Diagrams
![State Machine Diagram](StateMachineDiagram.svg)

![Activity Diagram](ActivityDiagram.svg)

<sub>* UML diagrams created with Dia. [http://live.gnome.org/Dia](http://live.gnome.org/Dia)</sup>
