--[[
metadata_osd. Version 0.6.0

Copyright (c) 2022-2023 Vladimir Chren

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

local opt = require 'mp.options'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

-- defaults
local options = {
    -- Enable OSD on mpv startup
    enable_on_start = true,

    -- Enable OSD for tracks
    enable_for_audio = true,
    enable_for_audio_withalbumart = true,
    enable_for_video = true,
    enable_for_image = false,

    -- Enable OSD-2 (with chapter title metadata if present)
    enable_osd_2 = true,

    -- Enable pathname fallback
    enable_pathname_fallback_dirnameup = true,
    enable_pathname_fallback_dirname = true,
    enable_pathname_fallback_filename = true,

    -- Autohide OSD for tracks
    autohide_for_audio = false,
    autohide_for_audio_withalbumart = false,
    autohide_for_video = true,
    autohide_for_image = true,

    -- Autohide delay in seconds
    autohide_timeout_sec = 5,
    autohide_statusosd_timeout_sec = 5,

    -- Key bindings

    -- Master enable / disable key (killswitch)
    key_toggleenable = 'F1',

    -- Key to enable / disable the OSD autohide feature
    key_toggleautohide = 'F5',

    -- Key to show / hide OSD-1
    --   - current autohide state applies so if autohide is enabled, OSD will hide again
    --     after the specified delay
    key_toggleosd_1 = '',

    -- Key to show / hide OSD-2 (with chapter title metadata if present)
    --   - current autohide state applies (see above)
    --   - OSD-2 needs to be enabled by 'enable_osd_2' config option
    --   - OSD-2 needs to have some data
    key_toggleosd_2 = '',

    -- Reset any user-toggled switches
    key_reset_usertoggled = 'F6',

    -- Key to show status OSD
    --   - displays OSD and autohide state (enabled / disabled)
    key_showstatusosd = '',

    -- Maximum OSD message length
    --   OSD messages will be trimmed after the specified (character) length.
    osd_message_maxlength = 96,

    -- Default OSD-1 layout & content:
    -- ┌─────────────────┐
    -- │ padding top     │
    -- ├─────────────────┤
    -- │ TEXT AREA 1     │
    -- ├─────────────────┤
    -- │ padding top     │
    -- ├─────────────────┼─────────────────────┐
    -- │ TEXT AREA 2     │ TEXT AREA 2 RELDATE │
    -- ├─────────────────┼─────────────────────┘
    -- │ padding top     │
    -- ├─────────────────┤
    -- │ TEXT AREA 3     │
    -- ├─────────────────┤
    -- │ padding top     │
    -- ├─────────────────┤
    -- │ TEXT AREA 4     │
    -- └─────────────────┘

    -- ===================== ========================= ======================
    --  Layout Element        Filled w/Metadata         (for online content)
    -- ===================== ========================= ======================
    --  TEXT AREA 1           Artist                    < empty >
    --  TEXT AREA 2           Album                     Uploader
    --  TEXT AREA 2 RELDATE   Release Year              < empty >
    --  TEXT AREA 3           Title                     Media Title
    --  TEXT AREA 4           Playlist Position /       <--
    --                        Playlist Count
    -- ===================== ========================= ======================

    -- ===================== =========================
    --  Layout Element        Path-name Fallback
    -- ===================== =========================
    --  TEXT AREA 1           Directory name (one above)
    --  TEXT AREA 2           Directory name
    --  TEXT AREA 2 RELDATE   <not applied>
    --  TEXT AREA 3           File name
    --  TEXT AREA 4           <not applied>
    -- ===================== =========================

    -- Default OSD-2 layout & content:
    -- ┌─────────────────┐
    -- │ padding top     │
    -- ├─────────────────┤
    -- │ TEXT AREA 1     │
    -- └─────────────────┘

    --  ================= ======================
    --   Layout Element    Filled w/Metadata
    --  ================= ======================
    --   TEXT AREA 1       Chapter Title
    --  ================= ======================

    -- Styling options

    -- Style: Padding top (in number of half-lines)
    -- Allowed values are integers in range:
    --   0, 1, .. 40
    style_paddingtop_osd_1_textarea_1 = 1,
    style_paddingtop_osd_1_textarea_2 = 0,
    style_paddingtop_osd_1_textarea_3 = 2,
    style_paddingtop_osd_1_textarea_4 = 3,
    style_paddingtop_osd_2_textarea_1 = 3,

    -- Style: Alignment
    -- Values may be string(s) (multiple separated by semicolon ';'):
    --   left_justified (or) centered (or) right_justified ';' subtitle (or) midtitle (or) toptitle
    style_alignment_osd_1 = "left_justified;midtitle",
    style_alignment_osd_2 = "centered;midtitle",

    -- Style: Font style override
    -- Values may be string(s) (multiple separated by semicolon ';'):
    --   italic ';' bold
    style_fontstyle_osd_1_textarea_1 = "bold",
    style_fontstyle_osd_1_textarea_2 = "bold",
    style_fontstyle_osd_1_textarea_2_releasedate = "",
    style_fontstyle_osd_1_textarea_3 = "italic",
    style_fontstyle_osd_1_textarea_4 = "",
    style_fontstyle_osd_2_textarea_1 = "",

    -- Style: Border width of the outline around the text
    -- Allowed values are integers:
    --   0, 1, 2, 3 or 4
    style_bord_osd_1 = 3,
    style_bord_osd_2 = 3,

    -- Style: Shadow depth of the text
    -- Allowed values are integers:
    --   0, 1, 2, 3 or 4
    style_shad_osd_1_textarea_1 = 0,
    style_shad_osd_1_textarea_2 = 0,
    style_shad_osd_1_textarea_3 = 1,
    style_shad_osd_1_textarea_4 = 0,
    style_shad_osd_2_textarea_1 = 0,

    -- Style: Font scale (in percent)
    -- Allowed values are integers in range:
    --   10, 11, .. 400
    style_fsc_osd_1_textarea_1 = 100,
    style_fsc_osd_1_textarea_2 = 100,
    style_fsc_osd_1_textarea_3 = 100,
    style_fsc_osd_1_textarea_4 = 60,
    style_fsc_osd_2_textarea_1 = 100,

    -- Style: Distance between letters
    -- Allowed values are integers in range:
    --   0, 1, .. 40
    style_fsp_osd_1_textarea_1 = 0,
    style_fsp_osd_1_textarea_2 = 0,
    style_fsp_osd_1_textarea_3 = 10,
    style_fsp_osd_1_textarea_4 = 0,
    style_fsp_osd_2_textarea_1 = 0,

    -- Current Chapter Number

    -- Show current chapter number in addition to the current playlist position.
    --   Can be useful (also) for audio files with internal chapters carrying a song
    --   per chapter.

    -- Current playlist position if the setting is activated (see below)
    --   is moved one line down and put between square brackets.
    -- E.g.:
    --   Chapter: 4/16
    --   [1/5]            <-- playlist position

    -- If the chapter number is equal to the current playlist position, the value
    --   is conflated with playlist position (to avoid duplicity).
    -- ^ (reworded) Applied only if not equal to the current playlist position.

    -- If playlist consists of exactly one media, playlist position is omitted
    -- instead and substituted for chapter number.

    show_chapternumber = false,

    -- Current Album Track Number

    -- Show current album track number in addition to the (encompassing) playlist
    -- position (if present in metadata).
    --   Can be useful if the playlist traverses multiple directories.

    -- Current playlist position if the setting is activated (see below)
    --   is moved one line down and put between square brackets.
    -- E.g.:
    --   Track: 3
    --   [4/26]            <-- playlist position

    -- If the track number is equal to the current playlist position, the value
    --   is conflated with playlist position (to avoid duplicity).
    -- ^ (reworded) Applied only if not equal to the current playlist position.

    -- If playlist consists of exactly one media, playlist position is omitted
    -- instead and substituted for album track number.

    -- _Note_: Album track number is scarcely present in metadata,
    --   this can give mixed results.

    show_albumtracknumber = false,

    -- *** UNSTABLE OPTIONS BELOW ***
    -- * Options below are still riping. They might be changed or removed
    -- in the future without further notice. *

    -- OSD layout

    -- Overall layout for elements
    tmpl_layout_osd_1 = "{{CONTENT_TEXTAREA_1_MEDIA}}{{NEWLINE}}{{CONTENT_TEXTAREA_2_MEDIA}}{{CONTENT_TEXTAREA_2_RELDATE_MEDIA}}{{NEWLINE}}{{CONTENT_TEXTAREA_3_MEDIA}}{{NEWLINE}}{{CONTENT_TEXTAREA_4_MEDIA}}",
    tmpl_layout_osd_2 = "{{CONTENT_TEXTAREA_1_MEDIA}}",

    -- Text area content for media type

    -- _Note_: Templating syntax is as yet _unstable_,
    --         it can change in the future.

    -- Tag expansion:
    --   Expand variable with name VAR:
    --     ##VAR##
    --   Conditionally include if value of VAR is a non zero length string:
    --     {{#?VAR}}TEMPLATE_TEXT{{#/}}
    --   The above works also as logical OR, so multiple condidions are possible:
    --     {{#?VAR_1}}TEMPLATE_TEXT_1{{#?VAR_2}}TEMPLATE_TEXT_2{{#/}}

    content_osd_1_textarea_1_audio = "{{#?ARTIST}}##ARTIST##{{#?DIRNAME_UP}}##DIRNAME_UP##{{#/}}",
    content_osd_1_textarea_2_audio = "{{#?ALBUM}}##ALBUM##{{#?DIRNAME}}##DIRNAME##{{#/}}",
    content_osd_1_textarea_2_reldate_audio = "{{#?RELEASE_YEAR}}{{UNICODE_SP}}(##RELEASE_YEAR##){{#/}}",
    content_osd_1_textarea_3_audio = "{{#?TITLE}}##TITLE##{{#?FILENAME}}##FILENAME##{{#/}}",
    content_osd_1_textarea_4_audio = "##TEXTAREA_4_GEN##",
    content_osd_2_textarea_1_audio = "##CHAPTERTITLE##",

    content_osd_1_textarea_1_audio_withalbumart = "{{#?ARTIST}}##ARTIST##{{#?DIRNAME_UP}}##DIRNAME_UP##{{#/}}",
    content_osd_1_textarea_2_audio_withalbumart = "{{#?ALBUM}}##ALBUM##{{#?DIRNAME}}##DIRNAME##{{#/}}",
    content_osd_1_textarea_2_reldate_audio_withalbumart = "{{#?RELEASE_YEAR}}{{UNICODE_SP}}(##RELEASE_YEAR##){{#/}}",
    content_osd_1_textarea_3_audio_withalbumart = "{{#?TITLE}}##TITLE##{{#?FILENAME}}##FILENAME##{{#/}}",
    content_osd_1_textarea_4_audio_withalbumart = "##TEXTAREA_4_GEN##",
    content_osd_2_textarea_1_audio_withalbumart = "##CHAPTERTITLE##",

    content_osd_1_textarea_1_video = "##DIRNAME_UP##",
    content_osd_1_textarea_2_video = "##DIRNAME##",
    content_osd_1_textarea_2_reldate_video = "{{#?RELEASE_YEAR}}{{UNICODE_SP}}(##RELEASE_YEAR##){{#/}}",
    content_osd_1_textarea_3_video = "{{#?TITLE}}##TITLE##{{#?FILENAME}}##FILENAME##{{#/}}",
    content_osd_1_textarea_4_video = "##TEXTAREA_4_GEN##",
    content_osd_2_textarea_1_video = "##CHAPTERTITLE##",

    content_osd_1_textarea_1_image = "{{#?ARTIST}}##ARTIST##{{#?DIRNAME_UP}}##DIRNAME_UP##{{#/}}",
    content_osd_1_textarea_2_image = "{{#?ALBUM}}##ALBUM##{{#?DIRNAME}}##DIRNAME##{{#/}}",
    content_osd_1_textarea_2_reldate_image = "{{#?RELEASE_YEAR}}{{UNICODE_SP}}(##RELEASE_YEAR##){{#/}}",
    content_osd_1_textarea_3_image = "{{#?TITLE}}##TITLE##{{#?FILENAME}}##FILENAME##{{#/}}",
    content_osd_1_textarea_4_image = "##TEXTAREA_4_GEN##",
    content_osd_2_textarea_1_image = "",

    content_osd_1_textarea_1_stream = "",
    content_osd_1_textarea_2_stream = "##UPLOADER##",
    content_osd_1_textarea_3_stream = "##MEDIATITLE##",
    content_osd_1_textarea_4_stream = "##TEXTAREA_4_GEN##",
    content_osd_2_textarea_1_stream = "##CHAPTERTITLE##",

    -- Global string substitutions for pathname fallback

    -- For *_gsubpatt_* options, so called Lua "patterns" apply as documented
    -- in the documentation:
    --   https://www.lua.org/manual/5.1/manual.html#5.4.1

    -- Characters after equal sign '=' are not interpreted specially,
    -- subsequent equal signs or quotes will be part of the value.

    -- For *_gsubrepl_* options, value is taken as such as string replacement.
    -- Optionally, space character can be inserted as %UNICODE_SP% in case of
    -- a need to make it visible (e.g. if it's at the end of the string).

    -- Text Area 1: Directory name one above of the currently loaded media file

    -- (empty slot)
    pathname_fallback_dirnameup_gsubpatt_1 = "",
    pathname_fallback_dirnameup_gsubrepl_1 = "",
    -- (empty slot)
    pathname_fallback_dirnameup_gsubpatt_2 = "",
    pathname_fallback_dirnameup_gsubrepl_2 = "",
    -- (empty slot)
    pathname_fallback_dirnameup_gsubpatt_3 = "",
    pathname_fallback_dirnameup_gsubrepl_3 = "",

    -- Text Area 2: Directory name of the currently loaded media file

    -- (empty slot)
    pathname_fallback_dirname_gsubpatt_1 = "",
    pathname_fallback_dirname_gsubrepl_1 = "",
    -- (empty slot)
    pathname_fallback_dirname_gsubpatt_2 = "",
    pathname_fallback_dirname_gsubrepl_2 = "",
    -- (empty slot)
    pathname_fallback_dirname_gsubpatt_3 = "",
    pathname_fallback_dirname_gsubrepl_3 = "",

    -- Text Area 3: File name without extension

    -- Replace underscore(s) with space character
    pathname_fallback_filename_gsubpatt_1 = "_+",
    pathname_fallback_filename_gsubrepl_1 = "%UNICODE_SP%",
    -- Remove leading track number
    pathname_fallback_filename_gsubpatt_2 = "^%d+%s+-%s+",
    pathname_fallback_filename_gsubrepl_2 = "",
    -- (empty slot)
    pathname_fallback_filename_gsubpatt_3 = "",
    pathname_fallback_filename_gsubrepl_3 = "",

    -- cut-here --
    -- FIXME: Remove options below on next release.
    -- Enable pathname fallback for text area
    enable_pathname_fallback_textarea_1 = true,
    enable_pathname_fallback_textarea_2 = true,
    enable_pathname_fallback_textarea_3 = true,
    -- Enable pathname fallback
    enable_pathname_fallback_dirname_up = true,
}

opt.read_options(options)

local state = {
    SHOWING_OSD_1 = 1,
    SHOWING_OSD_2 = 2,
    OSD_HIDDEN = 3,
}

local mediatype = {
    AUDIO = "audio",
    AUDIO_WITHALBUMART = "audio_withalbumart",
    VIDEO = "video",
    IMAGE = "image",
    STREAM = "stream",
}

local pathname_fallback_type = {
    DIRNAMEUP = "dirnameup",
    DIRNAME = "dirname",
    FILENAME = "filename",
}

local osd_enabled = false
local osd_autohide = false
local osd_enabled_usertoggled = false
local osd_autohide_usertoggled = false
local curr_mediatype = nil
local curr_state = state.OSD_HIDDEN
local osd_overlay_osd_1 = mp.create_osd_overlay("ass-events")
local osd_overlay_osd_2 = mp.create_osd_overlay("ass-events")
local osd_timer -- forward declaration
local pathname_fallback_gsubtable = {}
local ellipsis_str = "..."  -- unicode notation for ellipsis "\u{2026}" works in
                            -- LuaJIT and since Lua5.3 which is not broadly
                            -- available yet.

-- String helper functions

local function utf8_nextcharoffs(u_b1, u_b2, u_b3, u_b4)
    local nextcharoffs = nil

    --[[
    The built-in Lua5.1 byte-oriented string functions are limited,
    for variable length encoded characters present in the UTF-8
    encoding standard, insufficient.

    Until LuaJIT has compile support for Lua5.3, coming with its own
    native UTF-8 string library, a custom implementation deems to be
    necessary.
    ]]

    --[[
    UTF-8 Byte Sequences: Unicode Version 15.0.0, Section 3.9, Table 3-7.
    The Unicode Consortium. The Unicode Standard, Version 15.0.0, (Mountain View, CA: The Unicode Consortium, 2022. ISBN 978-1-936213-32-0)
    https://www.unicode.org/versions/Unicode15.0.0/
    ]]

    -- U+0000..U+007F
    if type(u_b1) == "number"
    then
        if u_b1 >= 0x00 and u_b1 <= 0x7F
        then
            nextcharoffs = 1
        -- U+0080..U+07FF
        elseif u_b1 >= 0xC2 and u_b1 <= 0xDF
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0x80 and u_b2 <= 0xBF
                then
                    nextcharoffs = 2
                end
            end
        -- U+0800..U+0FFF
        elseif u_b1 == 0xE0
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0xA0 and u_b2 <= 0xBF
                then
                    if type(u_b3) == "number"
                    then
                        if u_b3 >= 0x80 and u_b3 <= 0xBF
                        then
                            nextcharoffs = 3
                        end
                    end
                end
            end
        -- U+1000..U+CFFF
        elseif u_b1 >= 0xE1 and u_b1 <= 0xEC
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0x80 and u_b2 <= 0xBF
                then
                    if type(u_b3) == "number"
                    then
                        if u_b3 >= 0x80 and u_b3 <= 0xBF
                        then
                            nextcharoffs = 3
                        end
                    end
                end
            end
        -- U+D000..U+D7FF
        elseif u_b1 == 0xED
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0x80 and u_b2 <= 0x9F
                then
                    if type(u_b3) == "number"
                    then
                        if u_b3 >= 0x80 and u_b3 <= 0xBF
                        then
                            nextcharoffs = 3
                        end
                    end
                end
            end
        -- U+E000..U+FFFF
        elseif u_b1 >= 0xEE and u_b1 <= 0xEF
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0x80 and u_b2 <= 0xBF
                then
                    if type(u_b3) == "number"
                    then
                        if u_b3 >= 0x80 and u_b3 <= 0xBF
                        then
                            nextcharoffs = 3
                        end
                    end
                end
            end
        -- U+10000..U+3FFFF
        elseif u_b1 == 0xF0
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0x90 and u_b2 <= 0xBF
                then
                    if type(u_b3) == "number"
                    then
                        if u_b3 >= 0x80 and u_b3 <= 0xBF
                        then
                            if type(u_b4) == "number"
                            then
                                if u_b4 >= 0x80 and u_b4 <= 0xBF
                                then
                                    nextcharoffs = 4
                                end
                            end
                        end
                    end
                end
            end
        -- U+40000..U+FFFFF
        elseif u_b1 >= 0xF1 and u_b1 <= 0xF3
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0x80 and u_b2 <= 0xBF
                then
                    if type(u_b3) == "number"
                    then
                        if u_b3 >= 0x80 and u_b3 <= 0xBF
                        then
                            if type(u_b4) == "number"
                            then
                                if u_b4 >= 0x80 and u_b4 <= 0xBF
                                then
                                    nextcharoffs = 4
                                end
                            end
                        end
                    end
                end
            end
        -- U+100000..U+10FFFF
        elseif u_b1 == 0xF4
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0x80 and u_b2 <= 0x8F
                then
                    if type(u_b3) == "number"
                    then
                        if u_b3 >= 0x80 and u_b3 <= 0xBF
                        then
                            if type(u_b4) == "number"
                            then
                                if u_b4 >= 0x80 and u_b4 <= 0xBF
                                then
                                    nextcharoffs = 4
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return nextcharoffs
end

local function str_isempty(arg)
    return type(arg) ~= "string" or string.len(arg) == 0
end

local function str_isnonempty(arg)
    return type(arg) == "string" and string.len(arg) > 0
end

local function str_trunc(str)
    local result = str
    local str_truncpos = options.osd_message_maxlength

    if str_isnonempty(str)
    then
        str = string.gsub(str, "[\r\n]", "")
        if str_truncpos > 0
        then
            local str_bytepos = 1
            local str_charcount = 0
            local nextcharoffs = nil
            local u_b1, u_b2, u_b3, u_b4 = nil, nil, nil, nil

            repeat
                u_b1, u_b2, u_b3, u_b4 =
                    string.byte(str, str_bytepos, str_bytepos + 4)
                nextcharoffs =
                    utf8_nextcharoffs(
                        u_b1, u_b2, u_b3, u_b4)
                if nextcharoffs
                then
                    str_charcount = str_charcount + 1
                    str_bytepos = str_bytepos + nextcharoffs
                end
            until nextcharoffs == nil or
                str_charcount >= options.osd_message_maxlength

            if u_b1 == nil and nextcharoffs == nil -- reached end of string
            then
                return result
            elseif u_b1 ~= nil and nextcharoffs == nil -- found invalid utf-8 char
            then
                msg.debug("str_trunc(): found invalid UTF-8 character; falling back to byte-oriented string truncate.")
            elseif u_b1 ~= nil and nextcharoffs ~= nil -- string needs to be trunc-ed
            then
                str_truncpos = str_bytepos - 1
            end
        end

        if string.len(str) > str_truncpos
        then
            result =
                string.sub(str, 1, str_truncpos) ..
                ellipsis_str
        end
    end

    return result
end

local function bool2enabled_str(arg)
    local result = "Disabled"

    if type(arg) == "boolean" and arg then
        result = "Enabled"
    end

    return result
end

local function str_split(s, split_char)
    local token_pass_1 = nil
    local token_pass_2 = nil
    local res_t = {}

    if str_isnonempty(s) and str_isnonempty(split_char) and split_char:len() == 1
    then
        for token_pass_1 in string.gmatch(s, '([^' .. split_char .. ']+)')
        do
            token_pass_2 =
                string.match(
                    token_pass_1, '^[%s]*(.-)[%s]*$')

            if str_isnonempty(token_pass_2)
            then
                msg.trace("str_split(): new token: \"" .. token_pass_2 .. "\"")
                res_t[token_pass_2] = true
            end
        end
    end

    return res_t
end

local function str_split_styleoption(styleopt_str)
    return str_split(styleopt_str, ';')
end

local function parse_styleoption_int_inrange(styleopt_int, range_min, range_max)
    local styleopt_int = tonumber(styleopt_int)
    local res = nil

    if styleopt_int
    then
        styleopt_int = math.floor(styleopt_int)

        if styleopt_int >= range_min and styleopt_int <= range_max
        then
            res = styleopt_int
        end
    end

    return res
end

local function parse_styleoption_alignment(styleopt_alignment)
    local ass_alignment_leftjustified = 1
    local ass_alignment_centered = 2
    local ass_alignment_rightjustified = 3
    local ass_alignment_subtitle = 0
    local ass_alignment_toptitle = 4
    local ass_alignment_midtitle = 8

    local opt_t =
        str_split_styleoption(
            styleopt_alignment)

    local alignment_justification =
        ass_alignment_centered

    if opt_t["left_justified"]
    then
        alignment_justification =
            ass_alignment_leftjustified
    elseif opt_t["centered"]
    then
        alignment_justification =
            ass_alignment_centered
    elseif opt_t["right_justified"]
    then
        alignment_justification =
            ass_alignment_rightjustified
    end

    local alignment_position =
        ass_alignment_midtitle

    if opt_t["subtitle"]
    then
        alignment_position =
            ass_alignment_subtitle
    elseif opt_t["toptitle"]
    then
        alignment_position =
            ass_alignment_toptitle
    elseif opt_t["midtitle"]
    then
        alignment_position =
            ass_alignment_midtitle
    end

    return
        "{\\a" ..
        tostring(alignment_justification + alignment_position) ..
        "}"
end

local function parse_styleoption_bord(styleopt_bord)
    local res_bord = 0
    local styleopt_bord =
        parse_styleoption_int_inrange(styleopt_bord, 0, 4)

    if styleopt_bord
    then
        res_bord = styleopt_bord
    end

    return
        "{\\bord" ..
        tostring(res_bord) ..
        "}"
end

local function parse_styleoption_paddingtop(styleopt_paddingtop)
    local res_paddingtop = 0
    local styleopt_paddingtop =
        parse_styleoption_int_inrange(styleopt_paddingtop, 0, 40)

    if styleopt_paddingtop
    then
        res_paddingtop = styleopt_paddingtop
    end

    return
        string.rep("\\N", res_paddingtop)
end

local function parse_styleoption_shad(styleopt_shad)
    local res_shad = 0
    local styleopt_shad =
        parse_styleoption_int_inrange(styleopt_shad, 0, 4)

    if styleopt_shad
    then
        res_shad = styleopt_shad
    end

    return
        "{\\shad" ..
        tostring(res_shad) ..
        "}"
end

local function parse_styleoption_fsc(styleopt_fsc)
    local res_fsc = 100
    local styleopt_fsc =
        parse_styleoption_int_inrange(styleopt_fsc, 10, 400)

    if styleopt_fsc
    then
        res_fsc = styleopt_fsc
    end

    return
        "{\\fscx" ..
        tostring(res_fsc) ..
        "}" ..
        "{\\fscy" ..
        tostring(res_fsc) ..
        "}"
end

local function parse_styleoption_fsp(styleopt_fsp)
    local res_fsp = 0
    local styleopt_fsp =
        parse_styleoption_int_inrange(styleopt_fsp, 0, 40)

    if styleopt_fsp
    then
        res_fsp = styleopt_fsp
    end

    return
        "{\\fsp" ..
        tostring(res_fsp) ..
        "}"
end

local function parse_styleoption_fontstyle(styleopt_fontstyle)
    local opt_t =
        str_split_styleoption(
            styleopt_fontstyle)
    local italic, bold = false, false

    if opt_t["italic"]
    then
        italic = true
    end

    if opt_t["bold"]
    then
        bold = true
    end

    return italic, bold
end

local function parse_style_options()
    local osd_1_textarea_count = 4 -- for textarea_* loops

    -- prepare empty table variables
    local ass_style = {}
    ass_style.osd_1 = {}
    for i = 1, osd_1_textarea_count
    do
        ass_style.osd_1["textarea_" .. tostring(i)] = {}
    end
    ass_style.osd_1.textarea_2_reldate = {}
    ass_style.osd_2 = {}
    ass_style.osd_2.textarea_1 = {}

    -- Style: Alignment
    ass_style.osd_1.alignment =
        parse_styleoption_alignment(
            options.style_alignment_osd_1)

    ass_style.osd_2.alignment =
        parse_styleoption_alignment(
            options.style_alignment_osd_2)

    -- Style: Border width of the outline around the text
    ass_style.osd_1.bord =
        parse_styleoption_bord(
            options.style_bord_osd_1)

    ass_style.osd_2.bord =
        parse_styleoption_bord(
            options.style_bord_osd_2)

    -- Style: Font style
    for i = 1, osd_1_textarea_count
    do
        ass_style.osd_1["textarea_" .. tostring(i)].fontstyle = {}
        ass_style.osd_1["textarea_" .. tostring(i)].fontstyle.is_italic,
        ass_style.osd_1["textarea_" .. tostring(i)].fontstyle.is_bold =
            parse_styleoption_fontstyle(
                options["style_fontstyle_osd_1_textarea_" .. tostring(i)])
    end

    ass_style.osd_1.textarea_2_reldate.fontstyle = {}
    ass_style.osd_1.textarea_2_reldate.fontstyle.is_italic,
    ass_style.osd_1.textarea_2_reldate.fontstyle.is_bold =
        parse_styleoption_fontstyle(
            options.style_fontstyle_osd_1_textarea_2_releasedate)

    ass_style.osd_2.textarea_1.fontstyle = {}
    ass_style.osd_2.textarea_1.fontstyle.is_italic,
    ass_style.osd_2.textarea_1.fontstyle.is_bold =
        parse_styleoption_fontstyle(
            options.style_fontstyle_osd_2_textarea_1)

    -- Style: Padding top
    for i = 1, osd_1_textarea_count
    do
        ass_style.osd_1["textarea_" .. tostring(i)].paddingtop =
            parse_styleoption_paddingtop(
                options["style_paddingtop_osd_1_textarea_" .. tostring(i)])
    end

    ass_style.osd_1.textarea_2_reldate.paddingtop = ""

    ass_style.osd_2.textarea_1.paddingtop =
        parse_styleoption_paddingtop(
            options.style_paddingtop_osd_2_textarea_1)

    -- Style: Shadow depth of the text
    for i = 1, osd_1_textarea_count
    do
        ass_style.osd_1["textarea_" .. tostring(i)].shad =
            parse_styleoption_shad(
                options["style_shad_osd_1_textarea_" .. tostring(i)])
    end

    ass_style.osd_1.textarea_2_reldate.shad =
        parse_styleoption_shad(
            options.style_shad_osd_1_textarea_2)

    ass_style.osd_2.textarea_1.shad =
        parse_styleoption_shad(
            options.style_shad_osd_2_textarea_1)

    -- Style: Font scale in percent
    for i = 1, osd_1_textarea_count
    do
        ass_style.osd_1["textarea_" .. tostring(i)].fsc =
            parse_styleoption_fsc(
                options["style_fsc_osd_1_textarea_" .. tostring(i)])
    end

    ass_style.osd_1.textarea_2_reldate.fsc =
        parse_styleoption_fsc(
            options.style_fsc_osd_1_textarea_2)

    ass_style.osd_2.textarea_1.fsc =
        parse_styleoption_fsc(
            options.style_fsc_osd_2_textarea_1)

    -- Style: Distance between letters
    for i = 1, osd_1_textarea_count
    do
        ass_style.osd_1["textarea_" .. tostring(i)].fsp =
            parse_styleoption_fsp(
                options["style_fsp_osd_1_textarea_" .. tostring(i)])
    end

    ass_style.osd_1.textarea_2_reldate.fsp =
        parse_styleoption_fsp(
            options.style_fsp_osd_1_textarea_2)

    ass_style.osd_2.textarea_1.fsp =
        parse_styleoption_fsp(
            options.style_fsp_osd_2_textarea_1)

    return ass_style
end

local function prepare_pathname_fallback_gsubtable()
    -- num. of global "pattern" substitution slots in user options
    local slotmax = {
        [pathname_fallback_type.DIRNAMEUP] =
            options.enable_pathname_fallback_dirnameup and 3 or 0,
        [pathname_fallback_type.DIRNAME] =
            options.enable_pathname_fallback_dirname and 3 or 0,
        [pathname_fallback_type.FILENAME] =
            options.enable_pathname_fallback_filename and 3 or 0,
        }

    for fallback_type, slotmax in pairs(slotmax)
    do
        pathname_fallback_gsubtable[fallback_type] = {}
        local useroptname_prefix = "pathname_fallback_" .. fallback_type
        for gsub_idx = 1, slotmax
        do
            local key = options[useroptname_prefix .. "_gsubpatt_" .. gsub_idx]
            local val = options[useroptname_prefix .. "_gsubrepl_" .. gsub_idx]
            val = val:gsub("%%UNICODE_SP%%", " ")
            if str_isnonempty(key) and val
            then
                pathname_fallback_gsubtable[fallback_type][gsub_idx] =
                    { [key] = val }
            end
        end
    end

    msg.trace(
        "prepare_pathname_fallback_gsubtable(): " ..
        utils.to_string(pathname_fallback_gsubtable))
end

local function pathname_fallback_gsubloop(fallback_type, s)
    for _, t in pairs(pathname_fallback_gsubtable[fallback_type])
    do
        for patt, repl in pairs(t)
        do
            msg.debug(
                "pathname_fallback_gsubloop(): " ..
                string.format("%-9s", fallback_type) .. ": " ..
                "<-- \"" .. s .. "\"")
            s = s:gsub(patt, repl)
            msg.debug(
                "pathname_fallback_gsubloop(): " ..
                string.format("%-9s", fallback_type) .. ": " ..
                "patt \"" .. patt .. "\", repl \"" .. repl .. "\"")
            msg.debug(
                "pathname_fallback_gsubloop(): " ..
                string.format("%-9s", fallback_type) .. ": " ..
                "--> \"" .. s .. "\"")
        end
    end

    return s
end

-- SSA/ASS helper functions
--   spec. url: http://www.tcax.org/docs/ass-specs.htm

local ass_tmpl = {
    osd_1 = {
        curr_tmpl = nil,
        tokens_media = {
            audio = nil,
            audio_withalbumart = nil,
            video = nil,
            image = nil,
            stream = nil,
        }
    },
    osd_2 = {
        curr_tmpl = nil,
        tokens_media = {
            audio = nil,
            audio_withalbumart = nil,
            video = nil,
            image = nil,
            stream = nil,
        }
    },
}

local tmpl_token_type = {
    TEXT = "_text_",
    COND_OR = "_cond_or_",
    COND_OR_END = "_cond_or_end_",
}

local function ass_styleoverride_fontstyle(italic, bold, str)
    res = ""

    if italic
    then
        res = res ..
            "{\\i1}"
    end

    if bold
    then
        res = res ..
            "{\\b1}"
    end

    res = res ..
        str

    if bold
    then
        res = res ..
            "{\\b0}"
    end

    if italic
    then
        res = res ..
            "{\\i0}"
    end

    return res
end

local function ass_newline()
    return "\\N"
end

local function ass_prepare_template_textarea(ass_style_textarea, content_textarea)
    res = ""

    if type(ass_style_textarea) == "table" and
        str_isnonempty(content_textarea)
    then
        res =
            ass_style_textarea.shad ..
            ass_style_textarea.fsc ..
            ass_style_textarea.fsp ..
            ass_style_textarea.paddingtop ..
            ass_styleoverride_fontstyle(
                ass_style_textarea.fontstyle.is_italic,
                ass_style_textarea.fontstyle.is_bold,
                content_textarea) ..
            "{\\fsp0}" ..
            "{\\fscx100}" ..
            "{\\fscy100}" ..
            "{\\shad0}"
    end

    return res
end

local function ass_prepare_templates()
    -- sharing ASS/SSA style override code mark '{' with our templates

    local ass_style =
        parse_style_options()

    local textarea_count = { -- for textarea_* loops
        osd_1 = 4,
        osd_2 = 1,
    }
    local ass_tmpl_layout = {
        osd_1 = options.tmpl_layout_osd_1,
        osd_2 = options.tmpl_layout_osd_2,
    }
    local ass_tmpl_media = {
        osd_1 = {},
        osd_2 = {},
    }

    for osd_n, ass_tmpl_layout in pairs(ass_tmpl_layout)
    do
        for _, mediatype_ in pairs(mediatype)
        do
            local ass_tmpl =
                ass_style[osd_n].alignment ..
                ass_style[osd_n].bord ..
                ass_tmpl_layout

            for i = 1, textarea_count[osd_n]
            do
                local tmpl_strid_textarea =
                    "{{CONTENT_TEXTAREA_" .. tostring(i) .. "_MEDIA}}"

                local ass_style_textarea =
                    ass_style[osd_n]["textarea_" .. tostring(i)]

                local content_textarea =
                    options["content_" ..
                            osd_n .. "_" ..
                            "textarea_" ..
                            tostring(i) .. "_" ..
                            mediatype_]

                local ass_tmpl_textarea =
                    ass_prepare_template_textarea(
                        ass_style_textarea,
                        content_textarea)

                ass_tmpl =
                    string.gsub(
                        ass_tmpl,
                        tmpl_strid_textarea,
                        ass_tmpl_textarea)
            end

            if osd_n == "osd_1" -- remnant of bad original design
            then
                ass_tmpl =
                    string.gsub(
                        ass_tmpl,
                        "{{CONTENT_TEXTAREA_2_RELDATE_MEDIA}}",
                        ass_prepare_template_textarea(
                            ass_style[osd_n].textarea_2_reldate,
                            options["content_" ..
                                    osd_n ..
                                    "_textarea_2_reldate_" ..
                                    mediatype_]))
            end

            ass_tmpl =
                string.gsub(
                    ass_tmpl,
                    "{{NEWLINE}}",
                    ass_newline())

            ass_tmpl =
                string.gsub(
                    ass_tmpl,
                    "{{UNICODE_SP}}",
                    " ")

            ass_tmpl_media[osd_n][mediatype_] = ass_tmpl

            msg.trace(
                "ass_prepare_templates(): tmpl_media " ..
                "(" .. osd_n .. "/" .. mediatype_ .. "): " ..
                ass_tmpl)
        end
    end

    for _, mediatype_ in pairs(mediatype)
    do
        for osd_n, ass_tmpl_media in pairs(ass_tmpl_media)
        do
            local tmpl = ass_tmpl_media[mediatype_]
            local token = nil
            local tmpl_tokens = {}
            local curr_pos = 1

            repeat
                local curr_token_type = tmpl_token_type.TEXT
                local idx_section_start,
                    idx_section_end,
                    section_op,
                    section_var,
                    section_text =
                        string.find(tmpl, "{{#([?])(.-)}}(.-){{#/}}", curr_pos)

                if idx_section_start and idx_section_end
                    and section_op and section_var and section_text
                then
                    if idx_section_start ~= curr_pos
                    then
                        token = {
                            token_type =
                                curr_token_type,
                            token_text =
                                string.sub(tmpl, curr_pos, idx_section_start - 1)
                        }
                        table.insert(tmpl_tokens, token)
                    end

                    if section_op == "?"
                    then
                        curr_token_type = tmpl_token_type.COND_OR

                        for section_text, next_section_var in string.gmatch(section_text .. "{{#?}}", "(.-){{#[?](.-)}}")
                        do
                            token = {
                                token_type =
                                    curr_token_type,
                                token_var =
                                    section_var,
                                token_text =
                                    section_text
                            }
                            section_var = next_section_var
                            table.insert(tmpl_tokens, token)
                        end

                        token = {
                            token_type =
                                tmpl_token_type.COND_OR_END,
                            token_var =
                                nil,
                            token_text =
                                nil
                        }
                        table.insert(tmpl_tokens, token)
                    end

                    curr_pos = idx_section_end + 1
                else
                    token = {
                        token_type =
                            curr_token_type,
                        token_text =
                            string.sub(tmpl, curr_pos)
                    }
                    table.insert(tmpl_tokens, token)
                    break
                end
            until curr_pos >= string.len(tmpl)

            ass_tmpl[osd_n].tokens_media[mediatype_] = tmpl_tokens
            msg.trace("ass_prepare_templates(): tmpl_tokens " ..
                "(" .. osd_n .. "/" .. mediatype_ .. "): " ..
                utils.to_string(tmpl_tokens))
        end
    end
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
              -- exiting ought to be quick
            )
    end
end

local function osd_has_data(osd_overlay)
    return str_isnonempty(osd_overlay.data)
end

local function show_osd_1()
    msg.debug("show_osd_1()")

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
    msg.debug("show_osd_2()")

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
    msg.debug("hide_osd()")

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
    msg.debug("toggle_osd_1()")

    if osd_enabled then
        if curr_state == state.SHOWING_OSD_1 then
            hide_osd()
        else
            show_osd_1()
        end
    end
end

local function toggle_osd_2()
    msg.debug("toggle_osd_2()")

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

local function toggle_autohide()
    osd_autohide_usertoggled = true
    osd_autohide = not osd_autohide
    autohide_resettimer()
    show_statusosd()
end

local function reeval_osd_autohide()
    if not osd_autohide_usertoggled then
        osd_autohide = false

        if (curr_mediatype == mediatype.AUDIO and options.autohide_for_audio) or
           (curr_mediatype == mediatype.AUDIO_WITHALBUMART and options.autohide_for_audio_withalbumart) or
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
    msg.debug("reset_usertoggled()")
    osd_enabled_usertoggled = false
    osd_autohide_usertoggled = false
    reeval_osd_enabled()
    reeval_osd_autohide()
    show_statusosd()
end

local function get_abspath()
    local path =
        utils.join_path(
            mp.get_property("working-directory"),
            mp.get_property("path")
        )

    -- replace all current dir refs '/./' with '/'
    path = string.gsub(path, "([/\\])%.[/\\]", "%1")

    return path
end

local function get_chapter_pos()
    local prop_chapter_curr =
        mp.get_property_number("chapter", -1) + 1 -- zero-indexed
    local prop_chapters_total =
        mp.get_property_number("chapters", -1)
    return prop_chapter_curr, prop_chapters_total
end

local function mediatype_is_stream()
    local prop_path           = mp.get_property_osd("path")
    local prop_streamfilename = mp.get_property_osd("stream-open-filename")
    local prop_fileformat     = mp.get_property_osd("file-format")

    return
        prop_fileformat == "hls" or -- hls --> http live streaming
        prop_path ~= prop_streamfilename -- path ~= actual media URL
end

local tmpl_var = {
    playlist_pos = {
        tmpl_key = "PLAYLIST_POS",
    },
    playlist_count = {
        tmpl_key = "PLAYLIST_COUNT",
    },
    chapter_curr = {
        tmpl_key = "CHAPTER_CURR",
    },
    chapter_count = {
        tmpl_key = "CHAPTER_COUNT",
    },
    chaptertitle = {
        tmpl_key = "CHAPTERTITLE",
    },

    artist = {
        tmpl_key = "ARTIST",
        gatherfunc = function()
            local artist_str = mp.get_property_osd("metadata/by-key/artist")
            if str_isempty(artist_str)
            then
                artist_str = mp.get_property_osd("metadata/by-key/album_artist")
                if str_isempty(artist_str)
                then
                    artist_str = mp.get_property_osd("metadata/by-key/composer")
                end
            end

            return artist_str
        end
    },

    album = {
        tmpl_key = "ALBUM",
        gatherfunc = function()
            local prop_chapter_curr, prop_chapters_total =
                get_chapter_pos()
            local album_str =
                mp.get_property_osd("metadata/by-key/album")

            -- For audio files with internal chapters ...
            if prop_chapter_curr > 0 and
                prop_chapters_total > 0 and
                (curr_mediatype == mediatype.AUDIO or
                curr_mediatype == mediatype.AUDIO_WITHALBUMART)
            then
                if str_isempty(album_str)
                then
                    -- meta: Title
                    --   contains _often_ album name, use it in a pinch.
                    --   sometimes, this contains better data than 'album' property,
                    --   but how would we know (switch it on a mouse click?)
                    album_str = mp.get_property_osd("metadata/by-key/title")
                end
            end

            return album_str
        end
    },

    title = {
        tmpl_key = "TITLE",
        gatherfunc = function()
            local prop_chapter_curr, prop_chapters_total =
                get_chapter_pos()
            local title_str = nil

            -- For audio files with internal chapters ...
            if prop_chapter_curr > 0 and
                prop_chapters_total > 0 and
                ( curr_mediatype == mediatype.AUDIO or
                curr_mediatype == mediatype.AUDIO_WITHALBUMART )
            then
                -- meta: Chapter Title
                --   seems to contain song name for audio files with chapters
                title_str =
                    mp.get_property(
                        "chapter-list/" .. tostring(prop_chapter_curr) .. "/title")

            -- meta: Title
            else
                title_str = mp.get_property_osd("metadata/by-key/title")
            end

            return title_str
        end
    },

    release_year = {
        tmpl_key = "RELEASE_YEAR",
        gatherfunc = function()
            local function str_capture4digits(s)
                res = ""
                if str_isnonempty(s) then
                    local _, _, s_match = string.find(s, '([%d][%d][%d][%d])')
                    if s_match then
                        res = s_match
                    end
                end
                return res
            end

            local prop_chapter_curr, prop_chapters_total =
                get_chapter_pos()
            local release_year_str =
                mp.get_property_osd("metadata/by-key/date")
            release_year_str =
                str_capture4digits(release_year_str)

            -- For audio files with internal chapters ...
            if prop_chapter_curr > 0 and
                prop_chapters_total > 0 and
                ( curr_mediatype == mediatype.AUDIO or
                curr_mediatype == mediatype.AUDIO_WITHALBUMART )
            then
                if str_isempty(release_year_str)
                then
                    -- meta: Track
                    --   contains _often_ release date, use it in a pinch.
                    local prop_meta_track = mp.get_property_osd("metadata/by-key/track")
                    prop_meta_track = str_capture4digits(prop_meta_track)

                    if str_isnonempty(prop_meta_track)
                    then
                        release_year_str = prop_meta_track
                    end
                end
            end

            return release_year_str
        end
    },

    albumtrack_num = {
        tmpl_key = "ALBUMTRACK_NUM",
        gatherfunc = function()
            local albumtrack_num_str = nil
            local prop_meta_track = mp.get_property_osd("metadata/by-key/track")

            -- meta: Track Number
            if (curr_mediatype == mediatype.AUDIO or
                curr_mediatype == mediatype.AUDIO_WITHALBUMART) and
                str_isnonempty(prop_meta_track)
            then
                local _, _, s_match = string.find(prop_meta_track, '^(%d+)')
                if s_match
                then
                    local tracknum = tonumber(s_match)
                    if tracknum and
                        tracknum < 999 -- track number can contain release year,
                                    -- skip for more-than-three-digit track numbers
                    then
                        albumtrack_num_str = tostring(tracknum)
                    end
                end
            end

            return albumtrack_num_str
        end
    },

    uploader = {
        tmpl_key = "UPLOADER",
        gatherfunc = function()
            local uploader_str =
                mp.get_property_osd("metadata/by-key/uploader")
            return uploader_str
        end
    },

    mediatitle = {
        tmpl_key = "MEDIATITLE",
        gatherfunc = function()
            local mediatitle_str =
                mp.get_property_osd("media-title")
            return mediatitle_str
        end
    },

    dirname_up = {
        tmpl_key = "DIRNAME_UP",
        gatherfunc = function()
            local dirname_up_str = nil

            if options.enable_pathname_fallback_dirnameup
                -- FIXME: Remove option below on next release
                and options.enable_pathname_fallback_dirname_up
                and options.enable_pathname_fallback_textarea_1
            then
                dirname_up_str =
                    string.match(get_abspath(), ".*[/\\](.*)[/\\].*[/\\].*")

                if dirname_up_str
                then
                    dirname_up_str =
                        pathname_fallback_gsubloop(
                            pathname_fallback_type.DIRNAMEUP, dirname_up_str)
                end
            end

            return dirname_up_str
        end
    },

    dirname = {
        tmpl_key = "DIRNAME",
        gatherfunc = function()
            local dirname_str = nil

            if options.enable_pathname_fallback_dirname
                -- FIXME: Remove option below on next release
                and options.enable_pathname_fallback_textarea_2
            then
                dirname_str =
                    string.match(get_abspath(), ".*[/\\](.*)[/\\].*")

                if dirname_str
                then
                    dirname_str =
                        pathname_fallback_gsubloop(
                            pathname_fallback_type.DIRNAME, dirname_str)
                end
            end

            return dirname_str
        end
    },

    filename = {
        tmpl_key = "FILENAME",
        gatherfunc = function()
            local filename_str = nil

            if options.enable_pathname_fallback_filename
                -- FIXME: Remove option below on next release
                and options.enable_pathname_fallback_textarea_3
            then
                filename_str =
                    mp.get_property_osd("filename/no-ext")

                if filename_str
                then
                    filename_str =
                        pathname_fallback_gsubloop(
                            pathname_fallback_type.FILENAME, filename_str)
                end
            end

            return filename_str
        end
    },

    -- FIXME: Remove on next release. Obsolete code.
    textarea_1_gen = {
        tmpl_key = "TEXTAREA_1_GEN",
    },
    textarea_2_gen = {
        tmpl_key = "TEXTAREA_2_GEN",
    },
    textarea_3_gen = {
        tmpl_key = "TEXTAREA_3_GEN",
    },
    textarea_4_gen = {
        tmpl_key = "TEXTAREA_4_GEN",
    },

    textarea_1_metakey = {
        tmpl_key = "TEXTAREA_1_METAKEY",
    },
    textarea_2_metakey = {
        tmpl_key = "TEXTAREA_2_METAKEY",
    },
    textarea_3_metakey = {
        tmpl_key = "TEXTAREA_3_METAKEY",
    },
    textarea_4_metakey = {
        tmpl_key = "TEXTAREA_4_METAKEY",
    },
}

local function lazyget_tmpl_data(tmpl_data, tmpl_var_s)
    if not tmpl_data[tmpl_var_s]
    then
        local tmpl_var = tmpl_var[string.lower(tmpl_var_s)]

        if tmpl_var and tmpl_var.gatherfunc
        then
            tmpl_data[tmpl_var_s] = tmpl_var.gatherfunc() or ""
        end
    end

    return tmpl_data[tmpl_var_s]
end

local function tmpl_fill_content(tmpl_tokens, tmpl_data)
    local tmpl = ""
    local ORed = false

    for _, token in ipairs(tmpl_tokens)
    do
        msg.trace("tmpl_fill_content(): token: " ..
            utils.to_string(token))

        if ORed and token.token_type == tmpl_token_type.COND_OR_END
        then
            ORed = false
        end

        if token.token_type == tmpl_token_type.TEXT
        then
            tmpl = tmpl .. token.token_text
        elseif token.token_type == tmpl_token_type.COND_OR
                and not ORed -- keep ORed before lazy eval to event. skip it
                and str_isnonempty(lazyget_tmpl_data(tmpl_data, token.token_var))
        then
            tmpl = tmpl .. token.token_text
            ORed = true
        end
    end

    msg.debug("tmpl_fill_content(): tmpl:  " .. tmpl)

    local curr_pos = 1

    repeat
        local idx_start,
        idx_end,
        tmpl_var =
            string.find(tmpl, "##(.-)##", curr_pos)

        if idx_start and idx_end and tmpl_var
        then
            msg.debug("tmpl_fill_content(): found template var: " ..
                tmpl_var)
            -- FIXME: Is it better to build the OSD string here ?
            lazyget_tmpl_data(tmpl_data, tmpl_var)
            curr_pos = idx_end + 1
        else
            break
        end
    until curr_pos >= string.len(tmpl)

    for strid, val in pairs(tmpl_data)
    do
        val = tostring(val)

        msg.debug("tmpl_fill_content(): " ..
            strid .. " --> " .. val)

        tmpl = string.gsub(
            tmpl,
            "##" .. strid .. "##",
            str_isnonempty(val) and
                str_trunc(val) or "",
            1)
    end

    return tmpl
end

local function on_metadata_change(metadata_key, metadata_val)
    --[[
    The incoming table with metadata can have all the possible letter
    capitalizations for table keys which are case sensitive in Lua -->
    properties are always querried via mp.get_property().
    ]]

    local osd_tmpl = ass_tmpl.osd_1.curr_tmpl
    if not osd_tmpl then
        msg.warn("on_metadata_change(): Template for OSD-1 not yet available.")
        return
    end
    local tmpl_data = {}

    if true then -- FIXME: Remove on next release. Obsolete code.
    local playing_file = not mediatype_is_stream()

    -- OSD-1
    -- ┌─────────────────┐
    -- │ TEXT AREA 1     │
    -- └─────────────────┘
    local textarea_1_metakey_str = nil
    local textarea_1_str = nil

    if playing_file
    then
        if str_isnonempty(
            lazyget_tmpl_data(
                tmpl_data, tmpl_var.artist.tmpl_key))
        then
            textarea_1_metakey_str = "Artist"
            textarea_1_str = tmpl_data[tmpl_var.artist.tmpl_key]

        elseif options.enable_pathname_fallback_textarea_1
                and str_isnonempty(lazyget_tmpl_data(
                    tmpl_data, tmpl_var.dirname_up.tmpl_key))
        then
            textarea_1_metakey_str = "Path"
            textarea_1_str = tmpl_data[tmpl_var.dirname_up.tmpl_key]
        end
    else -- is stream
        if str_isnonempty(
            lazyget_tmpl_data(
                tmpl_data, tmpl_var.uploader.tmpl_key))
        then
            textarea_1_metakey_str = "Uploader"
            textarea_1_str = tmpl_data[tmpl_var.uploader.tmpl_key]
        end
    end

    tmpl_data[tmpl_var.textarea_1_metakey.tmpl_key] =
        textarea_1_metakey_str
    tmpl_data[tmpl_var.textarea_1_gen.tmpl_key] =
        textarea_1_str

    -- ┌─────────────────┐
    -- │ TEXT AREA 2     │
    -- └─────────────────┘
    local textarea_2_metakey_str = nil
    local textarea_2_str = nil

    if playing_file
    then
        if str_isnonempty(
            lazyget_tmpl_data(
                tmpl_data, tmpl_var.album.tmpl_key))
        then
            textarea_2_metakey_str = "Album"
            textarea_2_str = tmpl_data[tmpl_var.album.tmpl_key]
        elseif options.enable_pathname_fallback_textarea_2
                and str_isnonempty(lazyget_tmpl_data(
                    tmpl_data, tmpl_var.dirname.tmpl_key))
        then
            textarea_2_metakey_str = "Path"
            textarea_2_str = tmpl_data[tmpl_var.dirname.tmpl_key]
        end

    -- else -- is stream
            -- could be filled with something useful in the future.
    end

    tmpl_data[tmpl_var.textarea_2_metakey.tmpl_key] =
        textarea_2_metakey_str
    tmpl_data[tmpl_var.textarea_2_gen.tmpl_key] =
        textarea_2_str

    -- ┌─────────────────┐
    -- │ TEXT AREA 3     │
    -- └─────────────────┘
    local textarea_3_str = nil
    local textarea_3_metakey_str = nil

    if playing_file
    then
        if str_isnonempty(
            lazyget_tmpl_data(
                tmpl_data, tmpl_var.title.tmpl_key))
        then
            textarea_3_metakey_str = "Title"
            textarea_3_str = tmpl_data[tmpl_var.title.tmpl_key]
        elseif options.enable_pathname_fallback_textarea_3
                and str_isnonempty(lazyget_tmpl_data(
                    tmpl_data, tmpl_var.filename.tmpl_key))
        then
            textarea_3_metakey_str = "File"
            textarea_3_str = tmpl_data[tmpl_var.filename.tmpl_key]
        end

    else -- is stream
        if str_isnonempty(
            lazyget_tmpl_data(
                tmpl_data, tmpl_var.mediatitle.tmpl_key))
        then
            textarea_3_metakey_str = "Media Title"
            textarea_3_str = tmpl_data[tmpl_var.mediatitle.tmpl_key]
        end
    end

    tmpl_data[tmpl_var.textarea_3_metakey.tmpl_key] =
        textarea_3_metakey_str
    tmpl_data[tmpl_var.textarea_3_gen.tmpl_key] =
        textarea_3_str
    end

    -- ┌─────────────────┐
    -- │ TEXT AREA 4     │
    -- └─────────────────┘
    local prop_playlist_curr =
        mp.get_property_number("playlist-pos-1", 0)
    local prop_playlist_total =
        mp.get_property_number("playlist-count", 0)
    local prop_chapter_curr, prop_chapters_total =
        get_chapter_pos()

    local prop_playlist_curr_str =
        tostring(prop_playlist_curr)
    local prop_playlist_total_str =
        tostring(prop_playlist_total)
    local prop_chapter_curr_str =
        tostring(prop_chapter_curr)
    local prop_chapters_total_str =
        tostring(prop_chapters_total)

    -- always set tmpl. vars below
    tmpl_data[tmpl_var.playlist_pos.tmpl_key] =
        prop_playlist_curr_str
    tmpl_data[tmpl_var.playlist_count.tmpl_key] =
        prop_playlist_total_str
    tmpl_data[tmpl_var.chapter_curr.tmpl_key] =
        prop_chapter_curr_str
    tmpl_data[tmpl_var.chapter_count.tmpl_key] =
        prop_chapters_total_str

    local textarea_4_str = nil
    local textarea_4_metakey_str = nil

    -- meta: (Big) Playlist position
    if prop_playlist_curr > 0 and
        prop_playlist_total > 0
    then
        textarea_4_str =
            prop_playlist_curr_str ..
            "/" ..
            prop_playlist_total_str

        -- For files with internal chapters ...
        -- meta: Chapter Number
        if prop_chapter_curr > 0 and
            prop_chapters_total > 0
        then
            if options.show_chapternumber
            then
                local chapternum_metakey_str = "Chapter: "
                local chapternum_str = ""

                if not ((curr_mediatype == mediatype.AUDIO
                        or curr_mediatype == mediatype.AUDIO_WITHALBUMART)
                        and prop_playlist_total == 1)
                then
                    chapternum_str = chapternum_metakey_str
                end

                chapternum_str =
                    chapternum_str ..
                    prop_chapter_curr_str ..
                    "/" ..
                    prop_chapters_total_str

                if prop_playlist_total ~= 1 and
                    (prop_chapter_curr ~= prop_playlist_curr
                    or prop_chapters_total ~= prop_playlist_total)
                then
                    chapternum_str =
                        chapternum_str ..
                        ass_newline() ..
                        "[" ..
                        textarea_4_str ..
                        "]"
                end

                textarea_4_str = chapternum_str
            end

        elseif options.show_albumtracknumber
                and str_isnonempty(
                    lazyget_tmpl_data(
                        tmpl_data, tmpl_var.albumtrack_num.tmpl_key))
        then
            local tracknum_str = tmpl_data[tmpl_var.albumtrack_num.tmpl_key]
            local tracknum = tonumber(tracknum_str, 10)
            local tracknum_metakey_str = "Track: "
            local textarea_4_albumtrack_str = ""

            if prop_playlist_total == 1
            then
                textarea_4_albumtrack_str =
                    tracknum_metakey_str ..
                    tracknum_str

            elseif tracknum ~= prop_playlist_curr
            then
                textarea_4_albumtrack_str =
                    tracknum_metakey_str ..
                    tracknum_str ..
                    ass_newline() ..
                    "[" ..
                    textarea_4_str ..
                    "]"
            end

            if str_isnonempty(textarea_4_albumtrack_str)
            then
                textarea_4_str = textarea_4_albumtrack_str
            end
        end
    end

    tmpl_data[tmpl_var.textarea_4_gen.tmpl_key] =
        textarea_4_str

    osd_overlay_osd_1.data =
        tmpl_fill_content(osd_tmpl, tmpl_data)

    -- OSD-2
    -- ┌─────────────────┐
    -- │ TEXT AREA 1     │
    -- └─────────────────┘
    osd_tmpl = ass_tmpl.osd_2.curr_tmpl

    if osd_tmpl
    then
        -- meta: Chapter Title
        if options.enable_osd_2
            and metadata_key == "chapter-metadata/title"
            and str_isnonempty(metadata_val)
        then
            tmpl_data = {}
            tmpl_data[tmpl_var.chaptertitle.tmpl_key] =
                metadata_val
            osd_overlay_osd_2.data =
                tmpl_fill_content(osd_tmpl, tmpl_data)
        end
    else
        msg.warn("on_metadata_change(): Template for OSD-2 not yet available.")
    end

    if metadata_key == "chapter-metadata/title" and (curr_state == state.SHOWING_OSD_2 or (osd_autohide and curr_state == state.OSD_HIDDEN)) then
        show_osd_2()
    else
        show_osd_1()
    end
end

local function master_osd_enable()
    msg.debug("master_osd_enable()")

    mp.add_key_binding(
        options.key_toggleosd_1,
        "toggleosd_1",
        toggle_osd_1)

    mp.add_key_binding(
        options.key_toggleosd_2,
        "toggleosd_2",
        toggle_osd_2)

    mp.add_key_binding(
        options.key_toggleautohide,
        "toggleautohide",
        toggle_autohide)

    mp.add_key_binding(
        options.key_reset_usertoggled,
        "reset_usertoggled",
        reset_usertoggled)

    mp.observe_property(
        "metadata",
        "native",
        on_metadata_change)

    mp.observe_property(
        "chapter-metadata/title",
        "string",
        on_metadata_change)

    osd_enabled = true
    show_osd_1()
end

local function master_osd_disable()
    msg.debug("master_osd_disable()")

    mp.remove_key_binding(
        "toggleautohide")
    mp.remove_key_binding(
        "toggleosd_1")
    mp.remove_key_binding(
        "toggleosd_2")
    mp.remove_key_binding(
        "reset_usertoggled")

    mp.unobserve_property(
        on_metadata_change)

    hide_osd()
    osd_enabled = false
end

local function toggle_enable()
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
               (curr_mediatype == mediatype.AUDIO_WITHALBUMART and options.enable_for_audio_withalbumart) or
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

local function on_start_file()
    osd_overlay_osd_1.data = nil
    osd_overlay_osd_2.data = nil
end

local function on_tracklist_change(name, tracklist)
    msg.debug("on_tracklist_change()")

    local prev_mediatype = curr_mediatype
    local prev_mediatype_is_stream = curr_mediatype == mediatype.STREAM
    curr_mediatype = nil

    if tracklist then
        msg.debug("on_tracklist_change(): num of tracks: " .. tostring(#tracklist))

        for _, track in ipairs(tracklist) do
            if track.selected then
                if track.type == "audio" and not curr_mediatype then
                    msg.debug("on_tracklist_change(): audio track selected")
                    curr_mediatype = mediatype.AUDIO
                elseif track.type == "video" then
                    msg.debug("on_tracklist_change(): video track selected")
                    curr_mediatype = mediatype.VIDEO
                    if track.image then
                        msg.debug("on_tracklist_change(): video track is image")
                        curr_mediatype = mediatype.IMAGE
                        if track.albumart then
                            msg.debug("on_tracklist_change(): video track is albumart.")
                            curr_mediatype = mediatype.AUDIO_WITHALBUMART
                        end
                    end
                end
            end
        end
    end

    local curr_mediatype_is_stream = mediatype_is_stream()

    if curr_mediatype
        and (prev_mediatype ~= curr_mediatype
        or prev_mediatype_is_stream ~= curr_mediatype_is_stream)
    then
        msg.debug("on_tracklist_change(): current media type: " ..
            curr_mediatype:gsub("^%l", string.upper) ..
            (curr_mediatype_is_stream and " (stream)" or ""))

        ass_tmpl.osd_1.curr_tmpl = nil
        ass_tmpl.osd_2.curr_tmpl = nil

        if curr_mediatype_is_stream
        then
            ass_tmpl.osd_1.curr_tmpl =
                ass_tmpl.osd_1.tokens_media[mediatype.STREAM]
            ass_tmpl.osd_2.curr_tmpl =
                ass_tmpl.osd_2.tokens_media[mediatype.STREAM]
        else
            for _, mediatype_ in pairs(mediatype)
            do
                if curr_mediatype == mediatype_
                then
                    ass_tmpl.osd_1.curr_tmpl =
                        ass_tmpl.osd_1.tokens_media[mediatype_]
                    ass_tmpl.osd_2.curr_tmpl =
                        ass_tmpl.osd_2.tokens_media[mediatype_]
                    break
                end
            end
        end
    end

    reeval_osd_enabled()
    reeval_osd_autohide()
end

ass_prepare_templates()
prepare_pathname_fallback_gsubtable()

mp.add_key_binding(
    options.key_toggleenable,
    "toggleenable",
    toggle_enable)

mp.add_key_binding(
    options.key_showstatusosd,
    "showstatusosd",
    show_statusosd)

mp.register_event(
    "start-file",
    on_start_file)

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
