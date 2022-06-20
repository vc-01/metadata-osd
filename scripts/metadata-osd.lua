--[[
metadata-osd. Version 0.1.0

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
    key_toggleenable = 'F1',
    key_toggleautohide = 'F5',
    key_toggleautohide_autodecide = 'F6',
    key_toggleosd_1 = '',
    key_toggleosd_2 = '',
    key_showstatusosd = '',
    autohide_timeout_sec = 5,
    autohide_statusosd_timeout_sec = 10,
    osd_message_maxlength = 96,
}

local state = {
    SHOWING_OSD_1 = 1,
    SHOWING_OSD_2 = 2,
    OSD_HIDDEN = 3,
}

--[[
    *** String functions ***
]]

function trunc_str(arg)
    local result = arg

    if type(arg) == "string" then
        if string.len(arg) > options.osd_message_maxlength then
            result = string.sub(arg, 0, options.osd_message_maxlength) .. ellipsis
        end
    end

    return result
end

function is_nonempty_str(arg)
    return type(arg) == "string" and string.len(arg) > 0
end

function bool_tostate_str(arg)
    local result = "Disabled"

    if type(arg) == "boolean" then
        if arg then
            result = "Enabled"
        end
    end

    return result
end

--[[
    *** ASS functions ***
    ASS Specs: http://www.tcax.org/docs/ass-specs.htm
]]

local ass_alignment_leftjustified = 1
local ass_alignment_centered = 2
local ass_alignment_rightjustified = 3
local ass_alignment_toptitle = 4
local ass_alignment_midtitle = 8
local ass_borderwidth = 3

function ass_styleoverride_bold(arg)
    return "{\\b1}" .. arg .. "{\\b0}"
end

function ass_styleoverride_italic(arg)
    return "{\\i1}" .. arg .. "{\\i0}"
end

function ass_newline()
    return "\\N"
end

--[[
    *** OSD functions ***
]]

function process_metadata(propertyname, propertyvalue)
    if type(propertyname.event) == "string" then
        propertyname = propertyname.event
    elseif type(propertyname) ~= "string" then
        propertyname = ""
    end
    mp.msg.debug("process_metadata(): " .. propertyname)

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

        if is_nonempty_str(prop_uploader) then
            osd_str = osd_str
                .. ass_styleoverride_bold(trunc_str(prop_uploader))
        end
    else -- is file
        -- process metadata: Artist
        local prop_meta_artist = mp.get_property("metadata/by-key/Artist")

        if is_nonempty_str(prop_meta_artist) then
            osd_str = osd_str
                .. ass_styleoverride_bold(trunc_str(prop_meta_artist))

        -- Foldername-artist fallback
        else
            local folder_upup_pattern = ".*/(.*)/(.*)/.*"

            if prop_path:match(folder_upup_pattern) then
                foldername_artist = prop_path:gsub(folder_upup_pattern, "%1")
                foldername_artist = foldername_artist:gsub("_", " ")
                osd_str = osd_str
                    .. ass_styleoverride_bold(trunc_str(foldername_artist))
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
        if prop_chapter_curr and prop_chapters_total and is_nonempty_str(prop_meta_title) then
            osd_str = osd_str
                .. ass_styleoverride_bold(trunc_str(prop_meta_title))

            -- process metadata: Track (release year usually)
            if is_nonempty_str(prop_meta_track) then
                osd_str = osd_str
                    .. " (" .. prop_meta_track .. ")"
            end

        -- process metadata: Album
        elseif is_nonempty_str(prop_meta_album) then
            osd_str = osd_str
                .. ass_styleoverride_bold(trunc_str(prop_meta_album))

            -- process metadata: Album release date
            if is_nonempty_str(prop_meta_reldate) then
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
                    .. ass_styleoverride_bold(trunc_str(foldername_album))
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
        if is_nonempty_str(prop_mediatitle) then
            osd_str = osd_str
                .. ass_styleoverride_italic(trunc_str(prop_mediatitle))
        end
    else -- is file
        -- For files with internal chapters ...
        -- process metadata: Chapter title
        if not currtrack_isvideo and prop_chapter_curr and prop_chapters_total and is_nonempty_str(prop_chaptertitle) then
            osd_str = osd_str
                .. ass_styleoverride_italic(trunc_str(prop_chaptertitle))

        -- process metadata: Title
        elseif is_nonempty_str(prop_meta_title) then
            osd_str = osd_str
                .. ass_styleoverride_italic(trunc_str(prop_meta_title))

        -- Filename fallback
        else
            filename_noext = mp.get_property_osd("filename/no-ext")
            assumed_title = filename_noext:gsub("_", " ")
            osd_str = osd_str
                .. ass_styleoverride_italic(trunc_str(assumed_title))
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
    if is_nonempty_str(prop_chapter_curr) and is_nonempty_str(prop_chapters_total) then
        osd_str = osd_str
            .. string.rep(ass_newline(), 3)
            .. "{\\fscx60}{\\fscy60}"
            .. tostring(prop_chapter_curr + 1)
            .. "/"
            .. tostring(prop_chapters_total)

    -- process metadata: Playlist position
    elseif is_nonempty_str(prop_playlist_curr) and is_nonempty_str(prop_playlist_total) then
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
    if is_nonempty_str(propertyname) and propertyname == "chapter-metadata/title" and is_nonempty_str(propertyvalue) then
        osd_overlay_osd_2.data =
            "{\\a" .. tostring(ass_alignment_centered + ass_alignment_midtitle) .. "}"
            .. "{\\bord" .. tostring(ass_borderwidth) .. "}"
            .. "{\\shad0}"
            .. string.rep(ass_newline(), 3) -- a bit down
            .. trunc_str(propertyvalue)
            .. "{\\a0}"
    end

    if is_nonempty_str(propertyname) and propertyname == "chapter-metadata/title" and (active_state == state.SHOWING_OSD_2 or (autohide and active_state == state.OSD_HIDDEN)) then
        show_osd_2()
    else
        show_osd_1()
    end
end

function osd_has_data(osd_overlay)
    return is_nonempty_str(osd_overlay.data)
end

function show_osd_1()
    mp.msg.debug("show_osd_1()")

    if osd_enabled then
        if osd_has_data(osd_overlay_osd_1) then
            osd_overlay_osd_2:remove()
            osd_overlay_osd_1:update()

            if autohide then
                osd_timer:kill()
                osd_timer:resume()
            end

        active_state = state.SHOWING_OSD_1
        end
    end
end

function show_osd_2()
    mp.msg.debug("show_osd_2()")

    if osd_enabled then
        if osd_has_data(osd_overlay_osd_2) then
            osd_overlay_osd_1:remove()
            osd_overlay_osd_2:update()

            if autohide then
                osd_timer:kill()
                osd_timer:resume()
            end

        active_state = state.SHOWING_OSD_2
        end
    end
end

function toggle_osd_1()
    mp.msg.debug("toggle_osd_1()")

    if osd_enabled then
        if active_state == state.SHOWING_OSD_1 then
            hide_osd()
        else
            show_osd_1()
        end
    end
end

function toggle_osd_2()
    mp.msg.debug("toggle_osd_2()")

    if osd_enabled then
        if active_state == state.SHOWING_OSD_2 then
            hide_osd()
        else
            show_osd_2()
        end
    end
end

function hide_osd()
    mp.msg.debug("hide_osd()")

    if osd_enabled then
        osd_overlay_osd_1:remove()
        osd_overlay_osd_2:remove()

        if autohide then
            osd_timer:kill()
        end

        active_state = state.OSD_HIDDEN
    end
end

function osd_timeout()
    if osd_enabled then
        if autohide then
            if active_state == state.SHOWING_OSD_1 then
                if osd_has_data(osd_overlay_osd_2) then
                    show_osd_2()
                else
                    hide_osd()
                end
            elseif active_state == state.SHOWING_OSD_2 then
                hide_osd()
            end
        end
    end
end

function enable_osd_overlay()
    mp.msg.debug("enable_osd_overlay()")

    mp.add_key_binding(options.key_toggleautohide, "toggle_autohide", toggle_autohide_osd_overlay)
    mp.add_key_binding(options.key_toggleautohide_autodecide, "toggle_autohide_autodecide", toggle_autohide_autodecide_osd_overlay)
    mp.add_key_binding(options.key_toggleosd_1, "toggle_osd_1", toggle_osd_1)
    mp.add_key_binding(options.key_toggleosd_2, "toggle_osd_2", toggle_osd_2)

    mp.register_event("file-loaded", process_metadata)
    mp.observe_property("chapter-metadata/title", "string", process_metadata)

    osd_enabled = true
    autohide_autodecide_statereset()
    show_osd_1()
end

function disable_osd_overlay()
    mp.msg.debug("disable_osd_overlay()")

    mp.remove_key_binding("toggle_autohide")
    mp.remove_key_binding("toggle_autohide_autodecide")
    mp.remove_key_binding("toggle_osd_1")
    mp.remove_key_binding("toggle_osd_2")

    mp.unregister_event(process_metadata)
    mp.unobserve_property(process_metadata)

    hide_osd()
    osd_enabled = false
end

function toggle_enable_osd_overlay()
    if osd_enabled then
        disable_osd_overlay()
    else
        enable_osd_overlay()
    end

    show_current_state()
end

function autohide_statereset()
    if osd_enabled then
        if autohide then
            osd_timer:kill()
            osd_timer:resume()
        else
            osd_timer:kill()
            show_osd_1()
        end
    end
end

function toggle_autohide_osd_overlay()
    autohide = not autohide
    autohide_autodecide = false
    autohide_statereset()
    show_autohide_state()
end

function autohide_autodecide_statereset()
    if autohide_autodecide then
        autohide = currtrack_isvideo
        autohide_statereset()
    end
end

function toggle_autohide_autodecide_osd_overlay()
    autohide_autodecide = not autohide_autodecide
    autohide_autodecide_statereset()
    show_autohide_autodecide_state()
end

function on_currenttrack_video_change(name, current_tracks_video)
    mp.msg.debug("on_currenttrack_video_change()")

    currtrack_isvideo = false

    if current_tracks_video and (not current_tracks_video.albumart) then
        currtrack_isvideo = true
    end

    autohide_autodecide_statereset()
end

--[[
    *** State info OSD functions ***
]]

function show_current_state()
    if osd_enabled then
        mp.osd_message("Metadata OSD: Enabled (" .. options.key_toggleenable .. "), Autohide: " .. bool_tostate_str(autohide) .. " (" .. options.key_toggleautohide .. "), Autohide auto-decide: " .. bool_tostate_str(autohide_autodecide) .. " (" .. options.key_toggleautohide_autodecide .. ")", options.autohide_statusosd_timeout_sec)
    else
        mp.osd_message("Metadata OSD: Disabled (" .. options.key_toggleenable .. ")", 1)
    end
end

function show_autohide_state()
    if osd_enabled then
        mp.osd_message("Metadata OSD: Enabled (" .. options.key_toggleenable .. "), Autohide: " .. bool_tostate_str(autohide) .. " (" .. options.key_toggleautohide .. ") " .. unicode_rightwards_double_arrow .. " Autohide auto-decide: " .. bool_tostate_str(autohide_autodecide) .. " (" .. options.key_toggleautohide_autodecide .. ")", options.autohide_statusosd_timeout_sec)
    end
end

function show_autohide_autodecide_state()
    if osd_enabled then
        mp.osd_message("Metadata OSD: Enabled (" .. options.key_toggleenable .. "), Autohide auto-decide: " .. bool_tostate_str(autohide_autodecide) .. " (" .. options.key_toggleautohide_autodecide .. ")" .. (autohide_autodecide and " " .. unicode_rightwards_double_arrow .. " " or ", ") .. " Autohide: " .. bool_tostate_str(autohide) .. " (" .. options.key_toggleautohide .. ")", options.autohide_statusosd_timeout_sec)
    end
end

osd_enabled = false
autohide = false
autohide_autodecide = true
currtrack_isvideo = false
active_state = state.OSD_HIDDEN
ellipsis = "..."
unicode_rightwards_double_arrow = "\u{21D2}"

read_options(options, 'metadata-osd') -- read $XDG_CONFIG_HOME/mpv/script-opts/metadata-osd.conf

osd_overlay_osd_1 = mp.create_osd_overlay("ass-events")
osd_overlay_osd_2 = mp.create_osd_overlay("ass-events")

mp.add_key_binding(options.key_toggleenable, "toggleenable", toggle_enable_osd_overlay)
mp.add_key_binding(options.key_showstatusosd, "showcurrentstate", show_current_state)
mp.observe_property("current-tracks/video", "native", on_currenttrack_video_change)

-- FIXME: Create but don't start the timer. How?
osd_timer = mp.add_timeout( -- create & start the timer
        options.autohide_timeout_sec,
        osd_timeout
        )
osd_timer:kill() -- stop & reset the timer

if options.enable_on_start then
    enable_osd_overlay()
end
