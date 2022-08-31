--[[
metadata_osd. Version 0.3.0

Copyright (c) 2022 Vladimir Chren

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

require 'mp'
require 'mp.options'
require 'mp.utils'
require 'mp.msg'

-- defaults
local options = {
    enable_on_start = true,
    enable_for_audio = true,
    enable_for_audio_withalbumart = true,
    enable_for_video = true,
    enable_for_image = true,
    enable_osd_2 = true,
    autohide_for_audio = false,
    autohide_for_audio_withalbumart = false,
    autohide_for_video = true,
    autohide_for_image = true,
    key_toggleenable = 'F1',
    key_toggleautohide = 'F5',
    key_toggleosd_1 = '',
    key_toggleosd_2 = '',
    key_reset_usertoggled = 'F6',
    key_showstatusosd = '',
    autohide_timeout_sec = 5,
    autohide_statusosd_timeout_sec = 10,
    osd_message_maxlength = 96,
}

read_options(options, "metadata-osd") -- underscore character blends in better,
                                      -- keeping this for backward compat.
read_options(options)

local state = {
    SHOWING_OSD_1 = 1,
    SHOWING_OSD_2 = 2,
    OSD_HIDDEN = 3,
}

local mediatype = {
    UNKNOWN = "Unknown",
    AUDIO = "Audio",
    AUDIO_ALBUMART = "Audio with albumart",
    VIDEO = "Video",
    IMAGE = "Image",
}

local osd_enabled = false
local osd_autohide = false
local osd_enabled_usertoggled = false
local osd_autohide_usertoggled = false
local curr_mediatype = mediatype.UNKNOWN
local curr_state = state.OSD_HIDDEN
local unicode_ellipsis = "\u{2026}"
local osd_overlay_osd_1 = mp.create_osd_overlay("ass-events")
local osd_overlay_osd_2 = mp.create_osd_overlay("ass-events")
local osd_timer -- forward declaration

-- String helper functions

local function str_trunc(arg)
    local result = arg

    if type(arg) == "string" then
        if string.len(arg) > options.osd_message_maxlength then
            result = string.sub(arg, 0, options.osd_message_maxlength) .. unicode_ellipsis
        end
    end

    return result
end

local function str_isnonempty(arg)
    return type(arg) == "string" and string.len(arg) > 0
end

local function bool2enabled_str(arg)
    local result = "Disabled"

    if type(arg) == "boolean" and arg then
        result = "Enabled"
    end

    return result
end

-- ASS functions
--   link to spec: http://www.tcax.org/docs/ass-specs.htm

local ass_alignment_leftjustified = 1
local ass_alignment_centered = 2
local ass_alignment_rightjustified = 3
local ass_alignment_toptitle = 4
local ass_alignment_midtitle = 8
local ass_borderwidth = 3

local function ass_styleoverride_bold(arg)
    return "{\\b1}" .. arg .. "{\\b0}"
end

local function ass_styleoverride_italic(arg)
    return "{\\i1}" .. arg .. "{\\i0}"
end

local function ass_newline()
    return "\\N"
end

-- OSD functions

local function show_statusosd()
    if osd_enabled then
        mp.osd_message(
            "Metadata OSD: Enabled " ..
            "(" .. options.key_toggleenable .. "), " ..
            "Autohide: " .. bool2enabled_str(osd_autohide) .. " " ..
            "(" .. options.key_toggleautohide .. ")",
            options.autohide_statusosd_timeout_sec
            )
    else
        mp.osd_message(
            "Metadata OSD: Disabled " ..
            "(" .. options.key_toggleenable .. ")",
            1 -- hide abruptly after one second,
              -- quitting ought to be quick
            )
    end
end

local function osd_has_data(osd_overlay)
    return str_isnonempty(osd_overlay.data)
end

local function show_osd_1()
    mp.msg.debug("show_osd_1()")

    if osd_enabled then
        if osd_has_data(osd_overlay_osd_1) then
            osd_overlay_osd_2:remove()
            osd_overlay_osd_1:update()

            if osd_autohide then
                osd_timer:kill()
                osd_timer:resume()
            end

        curr_state = state.SHOWING_OSD_1
        end
    end
end

local function show_osd_2()
    mp.msg.debug("show_osd_2()")

    if osd_enabled then
        if osd_has_data(osd_overlay_osd_2) then
            osd_overlay_osd_1:remove()
            osd_overlay_osd_2:update()

            if osd_autohide then
                osd_timer:kill()
                osd_timer:resume()
            end

        curr_state = state.SHOWING_OSD_2
        end
    end
end

local function hide_osd()
    mp.msg.debug("hide_osd()")

    if osd_enabled then
        osd_overlay_osd_1:remove()
        osd_overlay_osd_2:remove()

        if osd_autohide then
            osd_timer:kill()
        end

        curr_state = state.OSD_HIDDEN
    end
end

local function toggle_osd_1()
    mp.msg.debug("toggle_osd_1()")

    if osd_enabled then
        if curr_state == state.SHOWING_OSD_1 then
            hide_osd()
        else
            show_osd_1()
        end
    end
end

local function toggle_osd_2()
    mp.msg.debug("toggle_osd_2()")

    if osd_enabled then
        if curr_state == state.SHOWING_OSD_2 then
            hide_osd()
        else
            show_osd_2()
        end
    end
end

local function osd_timeout_handler()
    if osd_enabled then
        if osd_autohide then
            if curr_state == state.SHOWING_OSD_1 then
                if osd_has_data(osd_overlay_osd_2) then
                    show_osd_2()
                else
                    hide_osd()
                end
            elseif curr_state == state.SHOWING_OSD_2 then
                hide_osd()
            end
        end
    end
end

local function autohide_resettimer()
    if osd_enabled then
        if osd_autohide then
            osd_timer:kill()
            osd_timer:resume()
        else
            osd_timer:kill()
            show_osd_1()
        end
    end
end

local function toggle_osd_autohide()
    osd_autohide_usertoggled = true
    osd_autohide = not osd_autohide
    autohide_resettimer()
    show_statusosd()
end

local function reeval_osd_autohide()
    if not osd_autohide_usertoggled then
        osd_autohide = false

        if (curr_mediatype == mediatype.AUDIO and options.autohide_for_audio) or
           (curr_mediatype == mediatype.AUDIO_ALBUMART and options.autohide_for_audio_withalbumart) or
           (curr_mediatype == mediatype.VIDEO and options.autohide_for_video) or
           (curr_mediatype == mediatype.IMAGE and options.autohide_for_image)
        then
            osd_autohide = true
        end

        autohide_resettimer()
    end
end

local reeval_osd_enabled -- forward declaration

local function reset_usertoggled()
    mp.msg.debug("reset_usertoggled()")
    osd_enabled_usertoggled = false
    osd_autohide_usertoggled = false
    reeval_osd_enabled()
    reeval_osd_autohide()
    show_statusosd()
end

local function on_metadata_change(propertyname, propertyvalue)
    if type(propertyname.event) == "string" then
        propertyname = propertyname.event
    elseif type(propertyname) ~= "string" then
        propertyname = ""
    end
    mp.msg.debug("on_metadata_change(): " .. propertyname)

    local prop_path           = mp.get_property_osd("path")
    local prop_streamfilename = mp.get_property_osd("stream-open-filename")
    local prop_fileformat     = mp.get_property_osd("file-format")
    local prop_mediatitle     = mp.get_property_osd("media-title")

    local prop_meta_album     = mp.get_property("metadata/by-key/Album")
    local prop_meta_title     = mp.get_property("metadata/by-key/Title")
    local prop_meta_reldate   = mp.get_property("metadata/by-key/Date")
    local prop_meta_track     = mp.get_property("metadata/by-key/Track")

    local prop_playlist_curr  = mp.get_property("playlist-pos-1")
    local prop_playlist_total = mp.get_property("playlist-count")
    local prop_chapter_curr   = mp.get_property("chapter")
    local prop_chapters_total = mp.get_property("chapters")
    local prop_chaptertitle   = mp.get_property("chapter-list/" .. tostring(prop_chapter_curr) .. "/title")

    local is_remote_src =
        prop_fileformat == "hls" -- 'http live streaming'
        or (prop_path ~= prop_streamfilename) -- if processed by yt-dlp / youtube-dl

    -- OSD-1 layout:
    -- ┌─────────────────┐
    -- │ TEXT AREA 1     │
    -- ├─────────────────┤
    -- │ TEXT AREA 2     │
    -- ├─────────────────┤
    -- │ <DIVIDER AREA>  │
    -- ├─────────────────┤
    -- │ TEXT AREA 3     │
    -- ├─────────────────┤
    -- │ <DIVIDER AREA>  │
    -- ├─────────────────┤
    -- │ TEXT AREA 4     │
    -- └─────────────────┘

    local osd_str = "{\\a" .. tostring(ass_alignment_leftjustified + ass_alignment_midtitle) .. "}"
        .. "{\\bord" .. tostring(ass_borderwidth) .. "}"
        .. "{\\shad0}"
        .. string.rep(ass_newline(), 1) -- a bit down

    -- Text Area 1
    if is_remote_src then
        -- process metadata: Uploader
        local prop_uploader = mp.get_property_osd("metadata/by-key/Uploader")

        if str_isnonempty(prop_uploader) then
            osd_str = osd_str
                .. ass_styleoverride_bold(str_trunc(prop_uploader))
        end
    else -- is file
        -- process metadata: Artist
        local prop_meta_artist = mp.get_property("metadata/by-key/Artist")

        if str_isnonempty(prop_meta_artist) then
            osd_str = osd_str
                .. ass_styleoverride_bold(str_trunc(prop_meta_artist))

        -- Foldername-artist fallback
        else
            local folder_upup_pattern = ".*/(.*)/(.*)/.*"

            if prop_path:match(folder_upup_pattern) then
                foldername_artist = prop_path:gsub(folder_upup_pattern, "%1")
                foldername_artist = foldername_artist:gsub("_", " ")
                osd_str = osd_str
                    .. ass_styleoverride_bold(str_trunc(foldername_artist))
            end
        end
    end

    -- Divider area
    osd_str = osd_str
        .. string.rep(ass_newline(), 1)

    -- Text Area 2
    if is_remote_src then
        -- <Empty currently>
    else -- is file
        -- For files with internal chapters ...
        -- process metadata: Title (album name usually)
        if prop_chapter_curr and prop_chapters_total and str_isnonempty(prop_meta_title) then
            osd_str = osd_str
                .. ass_styleoverride_bold(str_trunc(prop_meta_title))

            -- process metadata: Track (release year usually)
            if str_isnonempty(prop_meta_track) then
                osd_str = osd_str
                    .. " (" .. prop_meta_track .. ")"
            end

        -- process metadata: Album
        elseif str_isnonempty(prop_meta_album) then
            osd_str = osd_str
                .. ass_styleoverride_bold(str_trunc(prop_meta_album))

            -- process metadata: Album release date
            if str_isnonempty(prop_meta_reldate) then
                osd_str = osd_str
                    .. " (" .. prop_meta_reldate .. ")"
            end

        -- Foldername-album fallback
        else
            local folder_up_pattern = ".*/(.*)/.*"

            if prop_path:match(folder_up_pattern) then
                foldername_album = prop_path:gsub(folder_up_pattern, "%1")
                foldername_album = foldername_album:gsub("_", " ")
                osd_str = osd_str
                    .. ass_styleoverride_bold(str_trunc(foldername_album))
            end
        end
    end

    -- Divider area
    osd_str = osd_str
        .. string.rep(ass_newline(), 3)

    -- Text Area 3
    osd_str = osd_str
        .. "{\\shad1}"
        .. "{\\fsp10}"

    if is_remote_src then
        -- process metadata: Media Title
        if str_isnonempty(prop_mediatitle) then
            osd_str = osd_str
                .. ass_styleoverride_italic(str_trunc(prop_mediatitle))
        end
    else -- is file
        -- For files with internal chapters ...
        -- process metadata: Chapter title
        if curr_mediatype ~= mediatype.VIDEO and prop_chapter_curr and prop_chapters_total and str_isnonempty(prop_chaptertitle) then
            osd_str = osd_str
                .. ass_styleoverride_italic(str_trunc(prop_chaptertitle))

        -- process metadata: Title
        elseif str_isnonempty(prop_meta_title) then
            osd_str = osd_str
                .. ass_styleoverride_italic(str_trunc(prop_meta_title))

        -- Filename fallback
        else
            filename_noext = mp.get_property_osd("filename/no-ext")
            assumed_title = filename_noext:gsub("_", " ")
            osd_str = osd_str
                .. ass_styleoverride_italic(str_trunc(assumed_title))
        end
    end

    osd_str = osd_str
        .. "{\\fsp0}"
        .. "{\\shad0}"

    -- Divider area
    osd_str = osd_str
        .. string.rep(ass_newline(), 1)

    -- Text Area 4
    -- For files with chapters...
    -- process metadata: Chapter current / chapters total
    if str_isnonempty(prop_chapter_curr) and str_isnonempty(prop_chapters_total) then
        osd_str = osd_str
            .. string.rep(ass_newline(), 3)
            .. "{\\fscx60}{\\fscy60}"
            .. tostring(prop_chapter_curr + 1)
            .. "/"
            .. tostring(prop_chapters_total)

    -- process metadata: Playlist position
    elseif str_isnonempty(prop_playlist_curr) and str_isnonempty(prop_playlist_total) then
        osd_str = osd_str
            .. string.rep(ass_newline(), 3)
            .. "{\\fscx60}{\\fscy60}"
            .. tostring(prop_playlist_curr)
            .. "/"
            .. tostring(prop_playlist_total)
    end

    osd_overlay_osd_1.data = osd_str

    -- OSD-2 layout:
    -- ┌─────────────────┐
    -- │ CHAPTER TITLE   │
    -- └─────────────────┘
    -- process metadata: Chapter Title
    if options.enable_osd_2 and str_isnonempty(propertyname) and propertyname == "chapter-metadata/title" and str_isnonempty(propertyvalue) then
        osd_overlay_osd_2.data =
            "{\\a" .. tostring(ass_alignment_centered + ass_alignment_midtitle) .. "}"
            .. "{\\bord" .. tostring(ass_borderwidth) .. "}"
            .. "{\\shad0}"
            .. string.rep(ass_newline(), 3) -- a bit down
            .. str_trunc(propertyvalue)
            .. "{\\a0}"
    end

    if str_isnonempty(propertyname) and propertyname == "chapter-metadata/title" and (curr_state == state.SHOWING_OSD_2 or (osd_autohide and curr_state == state.OSD_HIDDEN)) then
        show_osd_2()
    else
        show_osd_1()
    end
end

local function master_osd_enable()
    mp.msg.debug("master_osd_enable()")

    mp.add_key_binding(
        options.key_toggleosd_1,
        "toggle_osd_1",
        toggle_osd_1)

    mp.add_key_binding(
        options.key_toggleosd_2,
        "toggle_osd_2",
        toggle_osd_2)

    mp.add_key_binding(
        options.key_toggleautohide,
        "toggle_osd_autohide",
        toggle_osd_autohide)

    mp.add_key_binding(
        options.key_reset_usertoggled,
        "reset_usertoggled",
        reset_usertoggled)

    mp.observe_property(
        "metadata",
        "string",
        on_metadata_change)

    mp.observe_property(
        "chapter-metadata/title",
        "string",
        on_metadata_change)

    osd_enabled = true
    show_osd_1()
end

local function master_osd_disable()
    mp.msg.debug("master_osd_disable()")

    mp.remove_key_binding(
        "toggle_osd_autohide")
    mp.remove_key_binding(
        "toggle_osd_1")
    mp.remove_key_binding(
        "toggle_osd_2")
    mp.remove_key_binding(
        "reset_usertoggled")

    mp.unobserve_property(
        on_metadata_change)

    hide_osd()
    osd_enabled = false
end

local function toggle_osd_enabled()
    osd_enabled_usertoggled = true

    if osd_enabled then
        master_osd_disable()
    else
        master_osd_enable()
        reeval_osd_autohide()
    end

    show_statusosd()
end

reeval_osd_enabled = function()
    if not osd_enabled_usertoggled then
        osd_enabled_currstate = osd_enabled
        osd_enabled_newstate = false

        if options.enable_on_start then
            if (curr_mediatype == mediatype.AUDIO and options.enable_for_audio) or
               (curr_mediatype == mediatype.AUDIO_ALBUMART and options.enable_for_audio_withalbumart) or
               (curr_mediatype == mediatype.VIDEO and options.enable_for_video) or
               (curr_mediatype == mediatype.IMAGE and options.enable_for_image)
            then
                osd_enabled_newstate = true
            end
        end

        if osd_enabled_currstate and not osd_enabled_newstate then
            master_osd_disable()
        elseif not osd_enabled_currstate and osd_enabled_newstate then
            master_osd_enable()
        end
    end
end

local function on_tracklist_change(name, tracklist)
    mp.msg.debug("on_tracklist_change()")

    curr_mediatype = mediatype.UNKNOWN

    if tracklist then
        mp.msg.debug("on_tracklist_change(): num of tracks: " .. tostring(#tracklist))

        for _, track in ipairs(tracklist) do
            if not track.selected then
                goto continue
            end

            if track.type == "audio" and curr_mediatype == mediatype.UNKNOWN then
                mp.msg.debug("on_tracklist_change(): audio track selected")
                curr_mediatype = mediatype.AUDIO
            elseif track.type == "video" then
                mp.msg.debug("on_tracklist_change(): video track selected")
                curr_mediatype = mediatype.VIDEO
                if track.image then
                    mp.msg.debug("on_tracklist_change(): video track is image")
                    curr_mediatype = mediatype.IMAGE
                    if track.albumart then
                        mp.msg.debug("on_tracklist_change(): video track is albumart.")
                        curr_mediatype = mediatype.AUDIO_ALBUMART
                    end
                end
            end

            ::continue::
        end
    end

    mp.msg.debug("on_tracklist_change(): current media type: " .. curr_mediatype)

    reeval_osd_enabled()
    reeval_osd_autohide()
end

mp.add_key_binding(
    options.key_toggleenable,
    "toggleenable",
    toggle_osd_enabled)

mp.add_key_binding(
    options.key_showstatusosd,
    "showstatusosd",
    show_statusosd)

mp.observe_property(
    "track-list",
    "native",
    on_tracklist_change)

-- FIXME: Create but don't start the timer. How?
osd_timer = mp.add_timeout( -- create & start the timer
        options.autohide_timeout_sec,
        osd_timeout_handler
        )
osd_timer:kill() -- stop & reset the timer
