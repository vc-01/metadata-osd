# Metadata OSD script for mpv
This script will add metadata OSD (on-screen display) to mpv.

![Screenshot](screenshot.png)

## Installation & Configuration
Place the script `metadata-osd.lua` into directory `$XDG_CONFIG_HOME/mpv/scripts/` for autoload.

To set custom options, place a configuration file named `metadata-osd.conf` into directory `$XDG_CONFIG_HOME/mpv/script-opts/` and edit the options, as for example:

```
enable_on_start=yes
key_toggleenable=F1
```

The options (and their defaults in parenthesis) are the following:

* _enable_on_start_ (yes) - enable metadata OSD on mpv startup
* _key_toggleenable_ (F1) - master enable / disable switch key
* _key_toggleautohide_ (F5) - autohide enable / disable switch key
* _key_toggleautohide_autodecide_ (F6) - switch key for the autohide state to be automatically decided (see [Autohide / auto-decide](#autohide--auto-decide) below)
* _key_toggleosd_1_ (unassigned) - OSD-1 show / hide key (current autohide state applies)
* _key_toggleosd_2_ (unassigned) - OSD-2 show / hide key (current autohide state applies)
 * _autohide_timeout_sec_ - auto-hide timeout in seconds

## Autohide / auto-decide
Automatic OSD hiding after a timeout can be triggered either manually or decided algorithmically based on the currently playing track. 

Autohide will be auto-enabled while viewing pictures or playing video files, deactivated while playing music (also for music files with an album art picture).

## Metadata selection
- If the currently playing file is not a video file and has internal **chapters**, these are preferred and shown on the OSD, otherwise file metadata is selected and shown.

	- _Rationale_: Implemented to support music files accompanied with a .cue file where each album track is technically a chapter.
	
- If autohide is enabled and chapter metadata is available, a second OSD (OSD-2) will be shown after OSD-1 had been auto-hidden. In the event of a chapter change during playback, only the second OSD (OSD-2) will pop up.

	- _Rationale_: Chapter metadata for video files could have been integrated into OSD-1, but it is convenient to be informed only about the chapter change during playback, not displaying the whole dataset repeatedly.

- Directory / file name fallback for files with no metadata.

	- _Rationale_: File name and directory name often carry similar information as the internal file metadata. This will work for media collections organized as e.g. `<Artist>/<Album>/<Song>` or `<Multimedia folder>/<Artist - Album>/<Song>`.
	- This can be a topic of further changes.

## UML Diagrams
![State Machine Diagram](StateMachineDiagram.svg)

![Activity Diagram](ActivityDiagram.svg)

<sub>* UML diagrams created with Dia. [http://live.gnome.org/Dia](http://live.gnome.org/Dia)</sup>
