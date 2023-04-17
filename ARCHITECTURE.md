# metadata-osd

## Program Design

### Metadata Selection

- If the currently playing file is not a video file and has internal **chapters**, these are preferred and shown on the OSD, otherwise file metadata is selected and shown.

  - _Rationale_: Implemented to support music files accompanied with a .cue file where each album track is technically a chapter.

- If autohide is enabled and chapter metadata is available, a second OSD (OSD-2) will show up after OSD-1 had been auto-hidden. In the event of a chapter change during playback, only the second OSD (OSD-2) with chapter title will show up.

  - _Rationale_: Chapter metadata for video files could have been integrated into OSD-1, but displaying the whole dataset repeatedly is disturbing.

- Directory / file name fallback for files with no metadata.

  - _Rationale_: File name and directory name often carry similar information as the per file-format specific metadata. This approach works for media collections organized as e.g.:
    - `<Artist>/<Album>/<Song>` or
    - `<Multimedia_dir>/<Artist - Album>/<Song>`
  - This can be a topic of further changes.

## Program Architecture

### Partial Functional UML Diagrams

![State Machine Diagram](StateMachineDiagram.svg)

![Activity Diagram](ActivityDiagram.svg)

<sub>* UML diagrams created with Dia. [http://live.gnome.org/Dia](http://live.gnome.org/Dia)</sub>
