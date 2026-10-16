PORTRAIT_CONFIG = {
    -- Single source of truth for the mod version: build.py parses it from
    -- here, and the Zygisk packaging refuses to ship a module.prop that
    -- disagrees with it. Bump this, module.prop and the CHANGELOG together.
    version = "2.8.1",
    background_animated_default = true,
    background_cycle_seconds = 480, -- 14 stops at the original 240 / 7 seconds per stop
    background_max_frame_seconds = 0.25, -- no colour jump after suspension/stalls
    -- Alternate original felt tones and vivid peaks at the original transition pace.
    -- RGB colours are normalized to the original green's luma once on first use.
    background_palette = {
        {80/255,132/255,110/255}, -- green: original felt
        {32/255,154/255,77/255}, -- vivid emerald
        {73/255,127/255,135/255}, -- teal
        {28/255,148/255,175/255}, -- vivid turquoise
        {94/255,116/255,148/255}, -- blue
        {45/255,110/255,220/255}, -- vivid blue
        {131/255,108/255,149/255}, -- violet
        {166/255,78/255,220/255}, -- vivid purple
        {150/255,103/255,125/255}, -- burgundy
        {204/255,72/255,151/255}, -- vivid raspberry
        {153/255,106/255,99/255}, -- dark red
        {215/255,78/255,89/255}, -- vivid crimson
        {150/255,115/255,86/255}, -- burnt orange
        {203/255,104/255,42/255}, -- vivid amber
    },
    scale_factor = 0.63,
    hud_top_space = 13, -- legacy compatibility; native run geometry uses layout below
    bottom_margin = 0.35,
    splash_scale_mult = 10 / 13,
    card_scale = 0.8, -- legacy compatibility; use layout.hand_scale/inventory_scale
    button = {
        width = 4,
        height = 2,
        text_scale = 0.8,
        width_landscape = 3.2,
        height_landscape = 1.3,
        text_scale_landscape = 0.45,
    },
    blind = {
        scale = 0.34,
        dim = 1.0,
        scale_landscape = 0.4,
        dim_landscape = 1.5,
    },
    row_sizes = {3, 4, 4},
    row_sizes_landscape = {5, 6},
    tab_breakpoints = {
        rows_5_6 = 3,
        rows_7_plus = 4,
    },
    challenge_page_size = 5,
    challenge_page_size_landscape = 10,
    jokers_y = 11, -- legacy compatibility; use layout.top_margin
    anti_jitter_threshold = 3.5,
    touch_drag_threshold = 9, -- logical points travelled since press, not per event
    touch_target_points = 44,
    diagnostics_page_size = 15,
    build_revision = "ios-portrait-rc3-ui-lifecycle",
    -- Run composition, in room tiles. The resolver measures the safe viewport
    -- and actual HUD/buttons, so these are gaps/ratios rather than device offsets.
    layout = {
        side_margin = 0.28,
        hud_side_margin = 0.18,
        top_margin = 0.65,
        bottom_margin = 0.16,
        inventory_gap = 0.38,
        consumable_width = 3.35,
        inventory_scale = 1.16,
        inventory_wrap_scale = 0.96,
        inventory_panel_scale = 0.84,
        joker_wrap_after = 8, -- 0-8 held Jokers: one row; 9+: two; capacity alone never wraps
        consumable_wrap_after = 3,
        inventory_row_gap = 0.15,
        hand_scale = 1.42,
        hand_scale_short = 1.28,
        short_height = 23,
        deck_scale = 0.72,
        deck_footer_padding = 0.16,
        deck_counter_height = 0.65,
        deck_gap = 0.35,
        hud_gap = 0.65,
        action_gap = 0.10,
        selection_clearance = 1.25,
        panel_gap = 0.55,
        panel_inventory_gap = 0.28,
        panel_deck_gap = 0.12,
    },
    pack = {
        columns = 3, max_columns = 5, card_scale = 1.35, hand_scale = 1.02, gap = 0.18,
        min_step_ratio = 0.82,
        top_gap = 0.35, hand_clearance = 0.65,
        row_controls = 1.15, footer_height = 1.25,
        highlight_lift = 0.22, button_height = 0.85,
    },
    quality = {
        -- Preserve the user's CRT slider, but reduce the distortion/colour
        -- fringing it applies to small portrait text. Zero is perfectly flat.
        crt_multiplier = 0.12,
        native_canvas_dpi = true,
        prefer_2x_textures = true,
    },
    fps_cap = 'auto', -- 'auto' = match display refresh rate (90/120 Hz), or a number like 60
    disable_touch_tilt = true, -- kill the cursor-lean tilt on touch (root fix for sheared-card warp)
    score_text_mult = 1.3, -- portrait multiplier for floating score/attention popups
    deck_position = 'shelf', -- legacy compatibility; native layout docks deck in HUD footer
    gestures = {
        enabled = true,
        min_swipe = 1.4, -- min vertical travel in game units to count as a flick
        max_dx_ratio = 0.6, -- horizontal drift allowed relative to vertical travel
        max_time = 0.45, -- max press-to-release seconds for a flick
        max_selected_time = 1.2,
        require_selected_card = true,
        group_follow = true, -- selected cards visually follow a vertical drag together
    },
    swipe_only = {
        -- Global scale boost is disabled (1.0): changing TILESCALE mid-session
        -- desynced every position computed before the change (shop layouts,
        -- the boot splash, card area widths). The mode's value is the removed
        -- buttons and the lower hand. Set below 1.0 at your own risk.
        scale_mult = 1.0,
        hand_base_offset = 2.3, -- bottom space when only the sort row remains
    },
    hand_preview = {
        enabled = true,
        scale = 0.55,
        y_offset = -1.15, -- distance above the hand area
    },
    joker_slots = {
        enabled = true,
        alpha = 0.16, -- outline opacity for empty joker/consumable slots
        slot_scale = 0.94, -- slot size vs card size; shared by the outline AND the
                           -- card placement so held cards center exactly on slots
    },
    -- Top inset kept clear of the notch / Dynamic Island / display cutout, in
    -- room tiles. On iOS this is only a FLOOR: the real per-device safe-area
    -- inset is read at runtime (see get_mobile_safe_area_top) so a bigger island
    -- (iPhone 14 Pro / 15 / 16) gets pushed down enough. Android keeps this exact
    -- tuned value to avoid regressing the many devices already dialed in.
    safe_area_y = 0.85,
    -- Extra breathing gap (room tiles) added under the *measured* iOS inset only.
    -- Bump this a touch if the score still hugs the island on some device.
    safe_area_extra_ios = 0.0,
    -- Extra bottom gap (room tiles) kept above the home indicator, iOS only.
    -- Bump this if the menu / corner buttons still crowd the swipe bar.
    safe_area_bottom_extra_ios = 0.0,
    -- The same breathing room at the bottom of the title screen on Android, in
    -- room tiles. It cannot be measured there the way it is on iOS: LOVE reads
    -- the Android safe area from the display cutout, which covers the notch and
    -- says nothing about the gesture bar, and the game runs immersive so the
    -- bar is hidden anyway. Without it the menu panel sits flush against the
    -- bottom edge of the screen. Measured against this phone's gesture inset
    -- (64px at density 640, so 16dp, about half a tile) with a little over it.
    menu_bottom_gap_android = 1.15,
    tooltip_screen_padding = 0.12,
    tooltip_safe_margin_points = 8,
    tooltip_max_width = 11.5,
    tooltip_min_text_points = 11,
    -- Gap in room tiles between a card and its tooltip on touch. Large enough
    -- that a thumb on the card does not cover the text; raise it if a bigger
    -- hand still reaches the popup.
    tooltip_card_gap = 0.9,
    tooltip_touch_gap = 1.6,
    -- How far a selected booster-pack card lifts (fraction of card height) so its
    -- USE button has clear room to appear beneath it instead of overlapping art.
    pack_highlight_lift = 0.4,
    -- How far the hand row sits above its anchor during a booster (card heights).
    -- Raised above the 1.8 desktop default so a lifted pack card clears the hand.
    pack_hand_lift = 2.2,
    -- How far a focused shop card lifts (fraction of card height) so its Buy/Open
    -- button is revealed above the shop panel instead of tucking under it.
    shop_highlight_lift = 0.45,
    main_menu = {
        row_width = 5.55, -- Play button width; the other rows match it
        row_gap = 0.34,   -- space between the middle buttons
        row_height = 1.25,
        x_offset_base = 0.1,
        x_offset_plus = 0.2,
        y_offset_base = -1.55,
        corner_y_offset = -2.15,
        -- Extra lift (room tiles) for the two bottom corner buttons on iOS.
        -- Rounded display corners are not part of the safe area iOS reports,
        -- so a box that clears the home indicator can still reach the curve:
        -- measured off the #45 screenshot, the profile box sat 4.5pt from the
        -- left edge with the corner arc cutting 2.5pt in at that height, about
        -- 2pt of daylight. Lifting the pair clear of the arc costs nothing
        -- else. Android has no such report and keeps 0.
        corner_lift_ios = 0.4,
        -- Horizontal half of the same nudge, in room tiles. Lifting alone tops
        -- out at the 4pt the box already keeps from the side edge, so the pair
        -- also steps inward, away from the arc. There is ~23 tiles-worth of
        -- daylight to the menu column at this width, so this stays clear of it.
        corner_inset_ios = 0.25,
        -- Smallest gap (room tiles) a corner box keeps from the menu column.
        -- The inset above is cut back, down to zero, to keep this (#48).
        corner_clearance = 0.15,
        -- The menu column ends this far above the bottom of the screen, in room
        -- tiles, measured at 390x844. The lift below is the device's own bottom
        -- inset minus this, so the panel finishes level with the safe area and
        -- the home indicator gets the strip to itself instead of sitting on the
        -- panel (#45).
        menu_gap_tiles = 0.26,
    },
    -- Steamodded's newer New Run screen does not fit a phone, so portrait turns
    -- its "vanilla run select" option on the first time it sees the setting.
    -- Set this to false to leave the option alone entirely.
    smods_vanilla_run_select = true,
    -- Compact name/control, two description lines and a small category label.
    mod_list_row_h = 3.2,
    mod_list_icon_size = 0.85,
    mod_list_text_scale = 0.4,
    -- Mods shown per page on a phone. Has to divide the number Steamodded pages
    -- by (below) so a page of ours never straddles two of theirs. Three keeps the
    -- window short enough that its back bar stays well clear of the home
    -- indicator; the rest of the mods are one page turn away.
    mod_list_page_size = 3,
    -- Mods per page upstream. Steamodded's own number, used to find which of
    -- its pages one of ours sits in.
    mod_list_per_page = 12,
    -- Room tiles taken off the mod window so its frame is visible rather than
    -- flush with the screen edges. Measured on the rig at 390x844: the window
    -- adds 1.14 tiles of padding and emboss around whatever its content asks
    -- for, so this is that plus roughly half a tile of daylight each side.
    mod_list_margin = 2.1,
    deck_view = {
        screen_margin = 1.6, -- frame, padding and clearance, both sides combined
        chrome_height = 3.8, -- Remaining / Full Deck, Back and outer frame
        summary_height = 6.2, -- title, tallies, rank counts and optional notes
        card_scale = 0.64,
        cards_per_row = 13,
        index_fraction = 0.30, -- exposed width of each overlapping card
        row_gap = 0.06, -- fraction of card height, scales with expanded decks
        panel_padding = 0.08,
        text_scale = 0.34,
        title_scale = 0.42,
        ranks_per_row = 7,
    },
    game_over_scale = 1.2,
    game_over_scale_landscape = 1.5,
    tag_align = {
        first_x_left = -0.2,
        first_x_right = 0.2,
        width = 0.9, -- measured tag UIBox width in room tiles
        screen_margin = 0.1,
    },
    usable_w_factor = 0.96,
    hand_screen_padding = 0.28,
    hand_base_offset = 3.1,
    discard_x_offset = 0.3,
    mobile_ui = {
        hud_scale_tall = 0.46,
        hud_scale_normal = 0.46,
        hud_scale_short = 0.48,
        hud_panel_minw = 12.0,
        hud_panel_chrome = 0.14,
        hud_top_right_minw = 6.7,
        hud_score_minw = 6.6,
        hud_chip_box_minw = 5.2,
        hud_chip_label_minw = 1.18,
        hud_current_hand_minw = 6.6,
        hud_hand_meter_minw = 3.0,
        hud_money_minw = 3.05,
        hud_spacing = 0.07,
        hud_stat_pad = 0.035,
        hud_stat_minw = 1.95,
        hud_stat_label_scale = 0.82,
        hud_stat_count_scale = 1.72,
        hud_stats_gap = 0.1,
        hud_blind_minw = 4.65,
        hud_blind_minh = 3.12,
        hud_blind_body_minh = 1.92,
        hud_blind_dim = 0.82,
        hud_blind_name_h = 0.46,
        hud_blind_name_minw = 2.38,
        hud_blind_name_scale = 1.42,
        hud_blind_body_pad = 0.018,
        hud_blind_body_maxw = 3.12,
        hud_blind_lower_pad = 0.02,
        hud_blind_score_minw = 2.15,
        hud_blind_score_maxw = 2.05,
        hud_blind_score_label_scale = 0.34,
        hud_blind_reward_scale = 0.34,
        hud_blind_dollar_scale = 0.4,
        hud_blind_line_h = 0.24,
        hud_blind_debuff_scale = 0.88,
        hud_blind_chip_row_h = 0.48,
        hud_blind_reward_h = 0.34,
        hud_button_minw = 3.0,
        hud_button_minh = 0.78,
        card_button_mult = 1.4, -- portrait size multiplier for Use/Sell buttons on cards
        run_setup_back_desc_scale = 0.72,
        run_setup_back_min_dims = 0.76,
        run_setup_back_desc_h = 1.9,
        blind_choice = {
            prompt_pad = 0.05,
            prompt_scale_1 = 0.66,
            prompt_scale_2 = 0.66,
            choice_pad = 0.02,
            choice_extra_gap = 0.12, -- horizontal only; keep card sizes and side margins
            wrapper_pad = 0.012,
            wrapper_inner_pad = 0.018,
            panel_pad = 0.018,
            inner_pad = 0.026,
            button_pad = 0.018,
            button_scale = 0.62,
            name_scale = 0.62,
            desc_scale = 0.46,
            score_label_scale = 0.42,
            reward_scale = 0.46,
            chip_size = 2.4,
            score_minw = 2.95,
            text_maxw = 2.75,
            tag_pad = 0.12,
            tag_button_pad = 0.10,
            tag_skip_scale = 0.52,
            tag_reward_scale = 0.5,
        },
        collection_blinds = {
            chip_size = 1.15,
            cell_pad = 0.06,
            ante_minw = 0.55,
            base_minw = 2.5,
            text_scale = 0.36,
            box_pad = 0.05,
        },
        shop_sign = {
            w = 2.45,
            h = 1.23,
            panel_w = 2.65,
            panel_h = 1.65,
            text_scale = 0.26,
        },
    },
}

function get_portrait_scale(w, h)
    local aspect = h / w
    local s
    if aspect > 2.2 then
        s = 0.58
    elseif aspect > 1.8 then
        s = 0.63
    elseif aspect > 1.5 then
        s = 0.70
    else
        s = 0.80
    end
    -- Swipe Only mode: no Play/Discard buttons, so scale the whole UI up to
    -- fill the freed space (smaller divisor = bigger UI). Reads the session-
    -- latched flag, never the live setting, so layout stays consistent.
    if G and G.F_SWIPE_ONLY and PORTRAIT_CONFIG.swipe_only then
        s = s * (PORTRAIT_CONFIG.swipe_only.scale_mult or 0.92)
    end
    return s
end

function portrait_touch_height(height)
    if not (G and G.F_PORTRAIT and G.TILESCALE and G.TILESIZE) then return height end
    local unit = G.TILESCALE * G.TILESIZE
    if unit <= 0 then return height end
    return math.max(height or 0, PORTRAIT_CONFIG.touch_target_points/unit)
end

-- Top inset (in room tiles) that keeps the HUD clear of a notch / Dynamic Island
-- / display cutout. Off-mobile it is 0. On Android it returns the tuned static
-- value unchanged. On iOS it converts the device's *real* top safe-area inset
-- (love.window.getSafeArea, in DPI-scaled pixels) into room tiles and uses that,
-- so an iPhone with a tall Dynamic Island gets pushed down enough instead of
-- relying on one hard-coded guess. The static value stays as a floor, and every
-- lookup is guarded so a missing API or a zero inset just falls back to it.
-- Must be called after G.TILESCALE is set for the current frame.
function get_mobile_safe_area_top(os_name)
    os_name = os_name or (love.system and love.system.getOS and love.system.getOS())
    if os_name ~= 'Android' and os_name ~= 'iOS' then return 0 end

    local fallback = (PORTRAIT_CONFIG and PORTRAIT_CONFIG.safe_area_y) or 0.85
    if os_name ~= 'iOS' then return fallback end

    if not (love.window and love.window.getSafeArea
            and G and G.TILESCALE and G.TILESIZE
            and G.TILESCALE > 0 and G.TILESIZE > 0) then
        return fallback
    end

    local ok, _sx, sy = pcall(love.window.getSafeArea)
    if not ok or type(sy) ~= 'number' or sy <= 0 then
        return fallback
    end

    -- px -> room tiles, the same conversion used for room width/height.
    local inset_tiles = sy / (G.TILESCALE * G.TILESIZE)
    inset_tiles = inset_tiles + ((PORTRAIT_CONFIG and PORTRAIT_CONFIG.safe_area_extra_ios) or 0)
    return math.max(inset_tiles, fallback)
end

-- Tiles to trim off the room HEIGHT so bottom-anchored UI stays on screen.
-- The room is shifted down by the top inset but has always kept its full
-- window height, so it overshoots the physical bottom by that same inset.
-- Every bottom offset (main-menu buttons, corner buttons, the hand) was tuned
-- on Android with the static 0.85-tile overshoot baked in, so Android trims
-- nothing and keeps its dialed-in look. On iOS the measured island inset is
-- ~2 tiles and the home indicator adds a bottom inset on top of that, which
-- is what clipped the title-screen buttons (#35): trim the overshoot beyond
-- the tuned floor plus the real bottom inset, so the Android-tuned bottom
-- spacing is reproduced relative to the iOS safe-area bottom edge instead of
-- a point below the screen. Falls back to 0 (old behaviour) whenever the
-- safe-area API is unavailable. Must be called after G.TILESCALE is set.
function get_mobile_room_bottom_trim(os_name, safe_top)
    os_name = os_name or (love.system and love.system.getOS and love.system.getOS())
    if os_name ~= 'iOS' then return 0 end

    local floor_inset = (PORTRAIT_CONFIG and PORTRAIT_CONFIG.safe_area_y) or 0.85
    local trim = math.max((safe_top or 0) - floor_inset, 0)

    if not (love.window and love.window.getSafeArea
            and love.graphics and love.graphics.getHeight
            and G and G.TILESCALE and G.TILESIZE
            and G.TILESCALE > 0 and G.TILESIZE > 0) then
        return trim
    end

    local ok, _sx, sy, _sw, sh = pcall(love.window.getSafeArea)
    if not ok or type(sy) ~= 'number' or type(sh) ~= 'number' then
        return trim
    end

    local bottom_px = love.graphics.getHeight() - (sy + sh)
    if bottom_px > 0 then
        trim = trim + bottom_px / (G.TILESCALE * G.TILESIZE)
    end
    trim = trim + ((PORTRAIT_CONFIG and PORTRAIT_CONFIG.safe_area_bottom_extra_ios) or 0)
    return math.max(trim, 0)
end

-- How far to nudge the main-menu corner buttons (profile on the left, language
-- on the right) away from the corner, in room tiles: up first, then inward.
-- iOS reports the home indicator in its safe area but not the rounded display
-- corners, so those two boxes can clear the swipe bar and still graze the curve
-- (#45). Returns lift, inset. Applied on iOS only, and only on a device that
-- reports a bottom inset, which is the same set of devices that has the
-- rounded corners. Everything else, every Android phone included, gets 0, 0.
function get_portrait_corner_nudge(os_name)
    os_name = os_name or (love.system and love.system.getOS and love.system.getOS())
    if os_name ~= 'iOS' and os_name ~= 'Android' then return 0, 0 end

    local menu = PORTRAIT_CONFIG and PORTRAIT_CONFIG.main_menu
    local lift = (menu and menu.corner_lift_ios) or 0
    local inset = (menu and menu.corner_inset_ios) or 0
    if lift <= 0 and inset <= 0 then return 0, 0 end

    -- Android phones have the same rounded display corners but report nothing
    -- about them, so they get the same nudge on the same flat terms.
    if os_name == 'Android' then return lift, inset end

    if not (love.window and love.window.getSafeArea
            and love.graphics and love.graphics.getHeight) then
        return 0, 0
    end

    local ok, _sx, sy, _sw, sh = pcall(love.window.getSafeArea)
    if not ok or type(sy) ~= 'number' or type(sh) ~= 'number' then return 0, 0 end
    if love.graphics.getHeight() - (sy + sh) <= 0 then return 0, 0 end

    return lift, inset
end

-- Lift for the main menu column in room tiles, so its bottom edge finishes at
-- the safe-area bottom rather than under the home indicator. Derived from the
-- inset the device reports, so a phone with a taller bar lifts further and a
-- device with no bar lifts not at all. iOS only, like the corner nudge.
function get_portrait_menu_lift(os_name)
    os_name = os_name or (love.system and love.system.getOS and love.system.getOS())
    if os_name == 'Android' then
        return math.max(0, (PORTRAIT_CONFIG and PORTRAIT_CONFIG.menu_bottom_gap_android) or 0)
    end
    if os_name ~= 'iOS' then return 0 end

    if not (love.window and love.window.getSafeArea
            and love.graphics and love.graphics.getHeight
            and G and G.TILESCALE and G.TILESIZE
            and G.TILESCALE > 0 and G.TILESIZE > 0) then
        return 0
    end

    local ok, _sx, sy, _sw, sh = pcall(love.window.getSafeArea)
    if not ok or type(sy) ~= 'number' or type(sh) ~= 'number' then return 0 end

    local bottom_px = love.graphics.getHeight() - (sy + sh)
    if bottom_px <= 0 then return 0 end

    local menu = PORTRAIT_CONFIG and PORTRAIT_CONFIG.main_menu
    local gap = (menu and menu.menu_gap_tiles) or 0
    return math.max(0, bottom_px / (G.TILESCALE * G.TILESIZE) - gap)
end

-- Plain-text device/layout report shown in Options -> Diagnostics and copied
-- to the clipboard from there. This exists because the project is developed
-- without an iOS device: a pasted report turns "the buttons look off" into
-- exact inset and tile numbers. Every probe is guarded so a partial LOVE API
-- (or being called before boot finishes) degrades to "?" instead of erroring.
function portrait_diagnostics_report()
    local lines = {}
    local function add(label, value)
        lines[#lines + 1] = label .. ": " .. tostring(value == nil and "?" or value)
    end
    local function fmt(n) return type(n) == "number" and string.format("%.2f", n) or "?" end

    add("Portrait mod", PORTRAIT_CONFIG and PORTRAIT_CONFIG.version)
    add("Build revision", PORTRAIT_CONFIG and PORTRAIT_CONFIG.build_revision)
    add("Game version", G and G.VERSION)
    local os_name = love.system and love.system.getOS and love.system.getOS()
    add("OS", os_name)
    if love.getVersion then
        local maj, min, rev = love.getVersion()
        add("LOVE", maj .. "." .. min .. "." .. rev)
    end
    if love.graphics and love.graphics.getWidth then
        add("Window", love.graphics.getWidth() .. "x" .. love.graphics.getHeight())
    end
    -- Reported refresh rate and the cap the loop is actually using. The two
    -- disagreeing is the difference between "the panel is 60" and "we are
    -- capping ourselves at 60", which is not something a frame counter alone
    -- can tell apart (#45).
    local ok_mode, _mw, _mh, mode_flags = pcall(function() return love.window.getMode() end)
    add("Refresh rate", ok_mode and mode_flags and mode_flags.refreshrate or "?")
    add("FPS cap", (G and G.FPS_CAP) or (PORTRAIT_CONFIG and PORTRAIT_CONFIG.fps_cap) or "?")
    if love.window and love.window.getDPIScale then
        add("DPI scale", love.window.getDPIScale())
    end
    if love.graphics and love.graphics.getPixelDimensions then
        local pw, ph = love.graphics.getPixelDimensions()
        add("Drawable pixels", pw .. "x" .. ph)
    end
    if love.graphics and love.graphics.getDimensions then
        local w, h = love.graphics.getDimensions()
        add("Orientation", h > w and 'portrait' or 'landscape')
    end
    add("High DPI requested", ok_mode and mode_flags and tostring(mode_flags.highdpi) or '?')
    if os_name == 'iOS' then
        local native = require('portrait_ios').info()
        add("iOS version", native.version)
        add("Native scale", native.native_scale)
        add("UIKit scale", native.scale)
        add("Panel maximum Hz", native.max_fps)
        if native.error then add("Native probe", native.error) end
    end
    if love.window and love.window.getSafeArea then
        local ok, sx, sy, sw, sh = pcall(love.window.getSafeArea)
        if ok and type(sy) == "number" then
            add("Safe area (logical)", "x=" .. sx .. " y=" .. sy .. " w=" .. sw .. " h=" .. sh)
            add("Safe bottom (logical)", love.graphics.getHeight() - sy - sh)
        end
    end
    if G then
        add("Tile scale", fmt(G.TILESCALE))
        if G.ROOM and G.ROOM.T then
            add("Room tiles", "w=" .. fmt(G.ROOM.T.w) .. " h=" .. fmt(G.ROOM.T.h) .. " y=" .. fmt(G.ROOM.T.y))
        end
        add("Portrait", G.F_PORTRAIT and "yes" or "no")
        add("Swipe only", G.F_SWIPE_ONLY and "yes" or "no")
        for _, key in ipairs({'hand', 'jokers', 'consumeables', 'play', 'HUD', 'buttons', 'shop'}) do
            local area = G[key] and G[key].T
            if area then
                add(key, fmt(area.x) .. ',' .. fmt(area.y) .. ' ' .. fmt(area.w) .. 'x' .. fmt(area.h))
            end
        end
        if G.CANVAS and G.CANVAS.getPixelDimensions then
            local pw, ph = G.CANVAS:getPixelDimensions()
            add("Canvas pixels", pw .. 'x' .. ph)
        end
    end
    local top_ok, top = pcall(get_mobile_safe_area_top, os_name)
    add("Safe top (tiles)", top_ok and fmt(top) or "?")
    local trim_ok, trim = pcall(get_mobile_room_bottom_trim, os_name, top_ok and top or 0)
    add("Bottom trim (tiles)", trim_ok and fmt(trim) or "?")
    local zygisk_ok, shaders = pcall(require, "portrait_shaders")
    if zygisk_ok and type(shaders) == "table" then
        local n = 0
        if shaders.replace then for _ in pairs(shaders.replace) do n = n + 1 end end
        add("Build", "zygisk (readabletro shaders: " .. n .. ")")
    else
        add("Build", "bundled (build.py)")
    end
    if love.timer and love.timer.getFPS then
        add("FPS", love.timer.getFPS())
    end
    return table.concat(lines, "\n")
end

-- Steamodded builds every Collection card page through one helper, sized for a
-- desktop room. On a phone the outer cards end up cut off by the screen edge
-- (#42). The helper already takes size multipliers, so portrait feeds it ones
-- derived from the live room width instead of rewriting Steamodded's layout.
-- Idempotent, a no-op without Steamodded, and it leaves pages that already fit
-- exactly as Steamodded built them.
function portrait_hook_smods_collection()
    if not (G and G.F_PORTRAIT) then return end
    if not (SMODS and type(SMODS.card_collection_UIBox) == 'function') then return end
    if SMODS.portrait_collection_hooked then return end

    local smods_card_collection_UIBox = SMODS.card_collection_UIBox
    SMODS.card_collection_UIBox = function(_pool, rows, args)
        args = args or {}
        local widest = 0
        for _, count in ipairs(rows or {}) do
            if type(count) == 'number' and count > widest then widest = count end
        end
        local card_w = G.CARD_W or 0
        local room_w = (G.ROOM and G.ROOM.T and G.ROOM.T.w) or 0

        if G.F_PORTRAIT and widest > 0 and card_w > 0 and room_w > 0 then
            -- Steamodded sizes each row as (w_mod*columns + 0.25) cards wide, so
            -- solve that for the width the room can actually show. Pages that
            -- already fit are left alone; the ones that do not (more columns than
            -- the mod's own five, or a page asking for oversized cards like the
            -- booster packs) are scaled down by the ratio they overshoot by, which
            -- keeps the page's own proportions intact.
            local usable = room_w - 1.5
            local max_w_mod = ((usable/card_w) - 0.25)/widest
            local base_w_mod = args.w_mod or 1
            if max_w_mod > 0 and base_w_mod > max_w_mod then
                local shrink = max_w_mod/base_w_mod
                args.w_mod = base_w_mod*shrink
                -- The cards have to come down with the row or they overlap in it.
                args.card_scale = (args.card_scale or 1)*shrink
                args.h_mod = (args.h_mod or 1)*shrink
            end
        end
        return smods_card_collection_UIBox(_pool, rows, args)
    end
    SMODS.portrait_collection_hooked = true
end

-- Steamodded appends its MODS button to the main menu panel and restyles that
-- panel on the way past, which left the button hanging beside the menu with the
-- rest of it knocked out of line (#44). Takes the finished definition, lifts the
-- button out and seats it next to Options and Quit at their size, and puts the
-- panel's own styling back. Runs only when that button is actually there, so a
-- build without Steamodded keeps the menu exactly as it was.
-- Steamodded's mod list is laid out for a desktop window: three boxes to a row,
-- a pane asking for a fixed 17 tiles of width and a list area with a fixed 5
-- tiles of height. On a phone the row ran off both edges with the last mod's
-- toggle out of reach, and the pane's frame sat off screen entirely (#45).
--
-- Three things are done to it, all measured rather than guessed, because a mod
-- box is as wide as its name, author and version make it:
--   * every box gets its own row, which is the narrowest the list can be laid
--     out and so the only arrangement that survives a long mod name,
--   * anything asking for more width than the room has is clamped to the room,
--     which brings the pane's frame back on screen,
--   * the list area is grown to whatever the rows actually measure once they
--     are built, since Steamodded attaches them as a child UIBox that does not
--     resize its host, so a page of them simply drew over the header and pager.
-- Pagination, ordering and the boxes themselves stay Steamodded's, so this
-- holds across its releases. Idempotent, and a no-op without it or in landscape.
-- Steamodded's mod list is laid out for a desktop window: twelve mods a page,
-- three to a row, a pane asking for a fixed 17 tiles of width and a list area
-- with a fixed 5 tiles of height. On a phone the rows ran off both edges with
-- the last mod's toggle out of reach, and the pane's frame sat off screen
-- entirely (#45).
--
-- Rather than squeeze twelve desktop-sized rows onto a phone, the page is made
-- smaller and the pager it already draws does the rest:
--   * one mod per row, which is the narrowest the list goes and so the only
--     arrangement a long mod name cannot break,
--   * a page holds mod_list_page_size of them instead of twelve, so the window
--     is a fixed, comfortable height with its back bar well clear of the home
--     indicator, whatever the mod count,
--   * the page selector is rebuilt for the new page count, so every mod is
--     still reachable, one page turn away,
--   * anything asking for more width than the room has is clamped to it, which
--     brings the pane's frame back on screen.
-- The boxes, their order and the page mechanism stay Steamodded's, so this
-- holds across its releases. Idempotent, and a no-op without it or in landscape.
function portrait_hook_smods_mod_list()
    if not (G and G.F_PORTRAIT) then return end
    if not (SMODS and SMODS.GUI and type(SMODS.GUI.dynamicModListContent) == 'function') then return end
    if SMODS.portrait_mod_list_hooked then return end

    -- Our page size has to divide Steamodded's, so a page of ours never
    -- straddles two of theirs and can always be cut out of one build.
    local function page_size()
        local cfg = PORTRAIT_CONFIG or {}
        local upstream = cfg.mod_list_per_page or 12
        local size = cfg.mod_list_page_size or 6
        if size < 1 or upstream % size ~= 0 then return upstream, upstream end
        return size, upstream
    end

    local function page_count()
        local size = page_size()
        local total = #((SMODS and SMODS.mod_list) or {})
        return math.max(1, math.ceil(total/size)), size, total
    end

    local function page_label(index, count)
        return (localize and localize('k_page') or 'Page') .. ' ' .. index .. '/' .. count
    end

    -- Rebuild the page selector for our page count. Steamodded hands the cycle
    -- an option list and gets the chosen index back, so swapping the list is
    -- all it takes for the same control to page through our smaller pages.
    if type(SMODS.GUI.createOptionSelector) == 'function' then
        local smods_selector = SMODS.GUI.createOptionSelector
        SMODS.GUI.createOptionSelector = function(args)
            if G.F_PORTRAIT and type(args) == 'table' and args.opt_callback == 'update_mod_list' then
                local count = page_count()
                local current = math.min(math.max(SMODS.portrait_mod_page or 1, 1), count)
                SMODS.portrait_mod_page = current
                local options = {}
                for i = 1, count do options[i] = page_label(i, count) end
                args.options = options
                args.current_option = options[current]
            end
            return smods_selector(args)
        end
    end

    if type(SMODS.GUI.staticModListContent) == 'function' then
        local smods_static = SMODS.GUI.staticModListContent
        SMODS.GUI.staticModListContent = function(...)
            local pane = smods_static(...)
            local cfg = PORTRAIT_CONFIG or {}
            local room = G.F_PORTRAIT and G.ROOM and G.ROOM.T
            if not (room and room.w and room.w > 0) then return pane end

            local usable = room.w - (cfg.mod_list_margin or 2.1)
            local size = page_size()
            local list_h = size*(cfg.mod_list_row_h or 1.6)

            local seen = {}
            local function fit(node)
                if type(node) ~= 'table' or seen[node] then return end
                seen[node] = true
                local config = node.config
                if type(config) == 'table' then
                    -- The pane asks for a fixed 17 tiles, which put its frame
                    -- off both edges of a phone screen.
                    if type(config.minw) == 'number' and config.minw > usable then config.minw = usable end
                    if type(config.maxw) == 'number' and config.maxw > usable then config.maxw = usable end

                    -- Steamodded hangs the rows off this node as a child UIBox,
                    -- which does not resize its host, so the host is given the
                    -- height a full page of rows takes. Fixed, so the window is
                    -- the same size whether you have three mods or thirty.
                    local holds_list = false
                    for _, child in ipairs(node.nodes or {}) do
                        if type(child) == 'table' and child.config and child.config.id == 'modsList' then
                            holds_list = true
                        end
                    end
                    if holds_list and type(config.minh) == 'number' and list_h > config.minh then
                        config.minh = list_h
                    end
                end
                for _, child in ipairs(node.nodes or {}) do fit(child) end
            end
            fit(pane)
            return pane
        end
    end

    local smods_mod_list = SMODS.GUI.dynamicModListContent
    SMODS.GUI.dynamicModListContent = function(page)
        if not G.F_PORTRAIT then return smods_mod_list(page) end

        local count, size, total = page_count()
        local index = math.min(math.max(tonumber(page) or SMODS.portrait_mod_page or 1, 1), count)
        SMODS.portrait_mod_page = index

        -- Build the Steamodded page our slice sits in, then cut the slice out.
        local _, upstream = page_size()
        local first = (index - 1)*size + 1
        local upstream_page = math.floor((first - 1)/upstream) + 1
        local pane = smods_mod_list(upstream_page)
        if not (pane and type(pane.nodes) == 'table') then return pane end

        local entries, template = {}, nil
        for _, row in ipairs(pane.nodes) do
            if type(row) ~= 'table' or type(row.nodes) ~= 'table' then return pane end
            template = template or row
            for _, entry in ipairs(row.nodes) do entries[#entries + 1] = entry end
        end
        if not template or #entries == 0 then return pane end

        local offset = first - (upstream_page - 1)*upstream
        local last = math.min(offset + size - 1, #entries, total - (upstream_page - 1)*upstream)

        local rows = {}
        local usable=G.ROOM.T.w-PORTRAIT_CONFIG.mod_list_margin
        local function fit_entry(node)
            local c=node.config or {}
            -- Upstream reserves 68 physical pixels for its tag. In portrait
            -- that is taller than a whole row; use logical UI dimensions.
            if c.object and c.w and c.h then
                c.w=PORTRAIT_CONFIG.mod_list_icon_size;c.h=c.w
            end
            if c.button and c.button:find('^openModUI_') then
                if c.minw then c.minw=usable-2.2;c.maxh=nil
                else c.minh=0.55;c.minw=0.65 end
            end
            if c.maxw and c.maxw<=4.5 then c.maxw=usable-3.5 end
            if node.n==G.UIT.T and c.scale then
                c.scale=math.max(c.scale,PORTRAIT_CONFIG.mod_list_text_scale)
            end
            for _,child in ipairs(node.nodes or {}) do fit_entry(child) end
        end
        for i = offset, last do
            if entries[i] then
                fit_entry(entries[i])
                entries[i] = require('portrait_mod_info').decorate_entry(entries[i])
                -- Fresh config per row: UIBox writes layout results back into
                -- it, so the split rows cannot share one table.
                local config = {}
                for k, v in pairs(template.config or {}) do config[k] = v end
                config.align = 'cm'
                config.padding = 0.06
                rows[#rows + 1] = {n = template.n, config = config, nodes = {entries[i]}}
            end
        end
        if #rows > 0 then pane.nodes = rows end
        -- This definition becomes its own UIBox. A column root recalculates
        -- from the box's screen coordinates and adds its parent offset twice
        -- when ON/OFF or the next-run badge changes text length.
        pane.n = G.UIT.ROOT
        return pane
    end
    SMODS.portrait_mod_list_hooked = true
end

-- Recent Steamodded replaced the New Run screen with a wide deck grid and a
-- panel beside it, laid out for a desktop window: on a phone it runs off both
-- edges and the Select button with it, so a deck cannot be picked at all (#47).
-- Steamodded keeps the old screen behind its own "vanilla run select" option,
-- and that one is the layout portrait is already built around, so on a phone it
-- is the default. Only set when the option has never been chosen, so anyone who
-- turns it off in Steamodded's own settings keeps their choice.
function portrait_default_smods_run_select()
    if not (G and G.F_PORTRAIT) then return end
    if not (SMODS and type(SMODS.config) == 'table') then return end
    if PORTRAIT_CONFIG and PORTRAIT_CONFIG.smods_vanilla_run_select == false then return end
    if SMODS.config.vanilla_run_select == nil then
        SMODS.config.vanilla_run_select = true
    end
end

function portrait_adopt_mods_button(definition)
    if not (G and G.F_PORTRAIT and definition and definition.nodes) then return definition end

    -- The MODS button is the way into the mod list, so hook it while we are here.
    if portrait_hook_smods_mod_list then portrait_hook_smods_mod_list() end
    if portrait_default_smods_run_select then portrait_default_smods_run_select() end

    -- UIBox_button wraps the real button one level down: the id and height live
    -- on that child, and the width lives on its label rows.
    local function button_id(node)
        local inner = node and node.nodes and node.nodes[1]
        return inner and inner.config and inner.config.id
    end
    local function size_button(node, width, height)
        local inner = node and node.nodes and node.nodes[1]
        if not inner then return end
        if height and inner.config then inner.config.minh = height end
        for _, label_row in ipairs(inner.nodes or {}) do
            if label_row.config then
                label_row.config.minw = width
                label_row.config.maxw = width - 0.2
            end
        end
    end

    local outer = definition.nodes[1]
    local panel = outer and outer.nodes and outer.nodes[1]
    if not (panel and panel.nodes) then return definition end

    local mods_index, mods_node
    for i, child in ipairs(panel.nodes) do
        if button_id(child) == 'mods_button' then mods_index, mods_node = i, child end
    end
    if not mods_node then return definition end

    table.remove(panel.nodes, mods_index)
    panel.config = {align = "cm", padding = 0.15, r = 2, emboss = 0.1, colour = G.C.L_BLACK, mid = true}

    local column = panel.nodes[1]
    local rows = column and column.nodes
    local button_row = rows and rows[2]
    if not (button_row and button_row.nodes) then
        table.insert(panel.nodes, mods_node)
        return definition
    end

    table.insert(button_row.nodes, mods_node)

    -- Line every row up on the Play button's width. Left alone, the extra button
    -- made the middle row wider than the rows above and below it and the panel
    -- grew dead corners (#44). The middle buttons share that width whatever
    -- their number: a phone build hides Quit, so it is two there and three here.
    local menu = PORTRAIT_CONFIG.main_menu or {}
    local menu_w = menu.row_width or 5.55
    local gap = menu.row_gap or 0.34
    local count = #button_row.nodes
    if count > 0 then
        local each = (menu_w - gap*(count - 1))/count
        for _, button in ipairs(button_row.nodes) do
            size_button(button, each, menu.row_height or 1.25)
        end
    end

    local collection_row = rows[3]
    size_button(collection_row and collection_row.nodes and collection_row.nodes[1], menu_w, 1.55)

    return definition
end

-- Where the first HUD tag hangs off the joker row. That row nearly fills a
-- portrait screen, so the fixed side offset put the tag a third of its width
-- past the edge (#44). This keeps the same placement but pulls it back until it
-- sits inside the room. Returns the alignment and offset for the tag UIBox.
function get_portrait_first_tag_align()
    local pc = (PORTRAIT_CONFIG and PORTRAIT_CONFIG.tag_align) or {}
    local left_side = (G.SETTINGS.play_main_hand == 1)
    local align = left_side and 'bl' or 'br'
    local offset_x = left_side and (pc.first_x_left or -0.2) or (pc.first_x_right or 0.2)

    -- Tag sprite plus the UIBox padding around it, in room tiles.
    local tag_w = pc.width or 0.9
    local margin = pc.screen_margin or 0.1

    if G.jokers and G.jokers.T and G.ROOM and G.ROOM.T and G.ROOM.T.w then
        if left_side then
            local left_edge = G.jokers.T.x - tag_w + offset_x
            if left_edge < margin then offset_x = offset_x + (margin - left_edge) end
        else
            local right_edge = G.jokers.T.x + G.jokers.T.w + offset_x + tag_w
            local limit = G.ROOM.T.w - margin
            if right_edge > limit then offset_x = offset_x - (right_edge - limit) end
        end
    end

    return align, {x = offset_x, y = 0}
end

-- Some vanilla windows are laid out for a desktop-width room and run off the
-- sides of a phone screen (#42: Credits, Language, Card Stats). Given a window's
-- natural width in room tiles, this returns the multiplier that makes it fit the
-- current room with a margin, or 1 when it already fits. Reading the live room
-- width keeps it correct on every aspect ratio instead of one tuned device.
function get_portrait_fit_scale(nominal_w, margin)
    if not (G and G.F_PORTRAIT and G.ROOM and G.ROOM.T and G.ROOM.T.w) then return 1 end
    if type(nominal_w) ~= 'number' or nominal_w <= 0 then return 1 end
    local usable = G.ROOM.T.w - (margin or 1.0)
    if usable <= 0 then return 1 end
    return math.min(1, usable/nominal_w)
end

-- Flattens one blind description line into plain text.
-- Vanilla stores loc_debuff_lines as strings, but Steamodded rewrites
-- Blind:set_text so the same table holds parsed localization nodes instead.
-- The HUD renders those lines through a plain text node, which would print
-- "table: 0x..." for a node table (#42), so anything that needs a string goes
-- through here first. Mirrors the assembly the blind popup already does.
function portrait_flatten_blind_line(line, vars)
    if type(line) == 'string' then return line end
    if type(line) ~= 'table' then return '' end

    local assembled = ''
    for _, part in ipairs(line) do
        if type(part) == 'string' then
            assembled = assembled..part
        elseif type(part) == 'table' and part.strings then
            for _, subpart in ipairs(part.strings) do
                if type(subpart) == 'string' then
                    assembled = assembled..subpart
                else
                    local var_value = vars and subpart and vars[tonumber(subpart[1])]
                    assembled = assembled..tostring(var_value or '')
                end
            end
        end
    end
    return assembled
end

--Bottom space reserved under the hand: smaller in Swipe Only mode, where only
--the compact sort row remains below the cards.
function get_hand_base_offset()
    if G and G.F_SWIPE_ONLY and PORTRAIT_CONFIG.swipe_only then
        return PORTRAIT_CONFIG.swipe_only.hand_base_offset or PORTRAIT_CONFIG.hand_base_offset
    end
    return PORTRAIT_CONFIG.hand_base_offset
end

-- All run coordinates are local to the room. Use the safe rectangle itself,
-- not ROOM.h (which retains a legacy overshoot for the menu animation).
function portrait_deck_view_metrics(suits)
    local p, room = PORTRAIT_CONFIG.deck_view, G.ROOM.T
    local width, height = room.w, room.h
    local unit = G.TILESCALE * G.TILESIZE
    if love.window.getSafeArea and unit > 0 then
        local ok, _, _, sw, sh = pcall(love.window.getSafeArea)
        if ok and type(sw) == 'number' and sw > 0 and type(sh) == 'number' and sh > 0 then
            width, height = math.min(width, sw/unit), math.min(height, sh/unit)
        end
    end
    width = math.max(G.CARD_W, width - p.screen_margin)
    local rows = 0
    for _, cards in pairs(suits) do rows = rows + math.ceil(#cards/p.cards_per_row) end
    local scale = math.min(p.card_scale,
        width/(G.CARD_W*(1 + (p.cards_per_row-1)*p.index_fraction)),
        math.max(G.CARD_H, height-p.chrome_height-p.summary_height)/math.max(rows, 1)/G.CARD_H/(1+p.row_gap))
    return {width = width, scale = scale, row_height = G.CARD_H*scale*(1+p.row_gap),
        per_row = p.cards_per_row}
end

-- Shared by the base game and Steamodded: a measured grid above the hand.
function portrait_pack_ui(count, title)
    local contracts=PortraitGameplay and PortraitGameplay.modules.contracts
    if contracts and contracts.refresh_hud then contracts.refresh_hud() end
    local p, l = PORTRAIT_CONFIG.pack, portrait_run_layout(true)
    local cols = math.min(count, p.columns)
    local rows = math.ceil(count/cols)
    local width = l.width-2*PORTRAIT_CONFIG.layout.side_margin-0.3
    local top = PORTRAIT_CONFIG.layout.top_margin+l.inventory_h+p.top_gap
    local footer = portrait_touch_height(p.footer_height)
    local controls = math.max(p.row_controls,portrait_touch_height(p.button_height)+p.highlight_lift+0.12)
    local available = l.hand_y-p.hand_clearance-top-footer-0.3
    local scale = 0
    for candidate=cols,math.min(count,p.max_columns) do
        local candidate_rows=math.ceil(count/candidate)
        -- Permit the light overlap used by native card areas before shrinking.
        local candidate_scale=math.min(p.card_scale,width/((1+(candidate-1)*p.min_step_ratio)*G.CARD_W),
            (available-candidate_rows*controls)/(candidate_rows*G.CARD_H))
        if candidate_scale>scale then cols,rows,scale=candidate,candidate_rows,candidate_scale end
    end
    scale = math.max(0.45, scale)
    G.pack_cards = CardArea(0,0,width,rows*(G.CARD_H*scale+controls),
        {card_limit=count,type='consumeable',highlight_limit=1,negative_info=true,
         portrait_pack_scale=scale,portrait_pack_columns=cols,portrait_pack_controls=controls})
    return {n=G.UIT.ROOT,config={align='cm',colour=G.C.CLEAR,padding=0.08},nodes={
        {n=G.UIT.R,config={align='cm'},nodes={{n=G.UIT.O,config={object=G.pack_cards}}}},
        {n=G.UIT.R,config={align='cm',padding=0.08,colour=G.C.UI.TRANSPARENT_DARK,r=0.15},nodes={
            {n=G.UIT.C,config={align='cm',minw=width-3.2,maxw=width-3.2},nodes={
                {n=G.UIT.R,config={align='cm'},nodes={{n=G.UIT.T,config={text=title,scale=0.42,colour=G.C.WHITE,shadow=true}}}},
                {n=G.UIT.R,config={align='cm'},nodes={
                    {n=G.UIT.T,config={text=localize('k_choose')..' ',scale=0.34,colour=G.C.WHITE}},
                    {n=G.UIT.T,config={ref_table=G.GAME,ref_value='pack_choices',scale=0.34,colour=G.C.WHITE}},
                }},
            }},
            {n=G.UIT.C,config={align='cm',minw=2.7,minh=footer,r=0.15,colour=G.C.GREY,
                button='skip_booster',func='can_skip_booster',one_press=true,hover=true,shadow=true},nodes={
                {n=G.UIT.T,config={text=localize('b_skip'),scale=0.45,colour=G.C.WHITE,shadow=true,
                    focus_args={button='y',orientation='bm'},func='set_button_pip'}},
            }},
        }},
    }}
end

function portrait_pack_slot(area, index)
    local p, cols = PORTRAIT_CONFIG.pack, area.config.portrait_pack_columns
    local row = math.floor((index-1)/cols)
    local n = math.min(cols,#area.cards-row*cols)
    local w, h = G.CARD_W*area.config.portrait_pack_scale, G.CARD_H*area.config.portrait_pack_scale
    local step=n>1 and math.min(w+p.gap,(area.T.w-w)/(n-1)) or 0
    return area.T.x+(area.T.w-w-(n-1)*step)/2+((index-1)%cols)*step,
        area.T.y+row*(h+area.config.portrait_pack_controls)+p.highlight_lift
end

function portrait_footer_deck_metrics()
    local p = PORTRAIT_CONFIG.layout
    local scale = math.max(p.deck_scale, portrait_touch_height(0)/G.CARD_W)
    return {scale=scale, w=G.CARD_W*scale+2*p.deck_footer_padding,
        h=G.CARD_H*scale+p.deck_counter_height+2*p.deck_footer_padding}
end

function portrait_run_layout(opening_pack)
    local p, room = PORTRAIT_CONFIG.layout, G.ROOM.T
    local unit = G.TILESCALE * G.TILESIZE
    local height = room.h
    if love.window.getSafeArea then
        local ok, _, _, _, sh = pcall(love.window.getSafeArea)
        if ok and type(sh) == 'number' and sh > 0 then height = math.min(height, sh/unit) end
    end
    local scale = height < p.short_height and p.hand_scale_short or p.hand_scale
    local combat = G.STATE == G.STATES.SELECTING_HAND or G.STATE == G.STATES.DRAW_TO_HAND or G.STATE == G.STATES.HAND_PLAYED
    local action_h = G.buttons and G.buttons.T.h or (combat and (G.F_SWIPE_ONLY and 1.8 or 3) or 0)
    local hud_h = G.HUD and G.HUD.T.h or 6
    local action_y = height - p.bottom_margin - action_h
    local hud_y = action_y - p.action_gap - hud_h
    local workspace_hud_y = hud_y
    local s = G.STATES
    local pack = opening_pack or G.STATE==s.TAROT_PACK or G.STATE==s.PLANET_PACK or
        G.STATE==s.SPECTRAL_PACK or G.STATE==s.STANDARD_PACK or G.STATE==s.BUFFOON_PACK or
        (s.SMODS_BOOSTER_OPENED and G.STATE==s.SMODS_BOOSTER_OPENED)
    if pack then scale=math.min(scale,PORTRAIT_CONFIG.pack.hand_scale) end
    if pack and PortraitGameplay and PortraitGameplay.modules.contracts then
        -- Pack cards and the hand share a stable workspace budget. The real HUD
        -- still collapses its contract row completely when it has no icons.
        local row = G.HUD and G.HUD:get_UIE_by_ID('portrait_contracts')
        workspace_hud_y = hud_y + (row and row.T.h or 0) - 0.92
    end
    local _, inventory_scale = portrait_inventory_metrics()
    local inventory_h = math.max(portrait_inventory_height(G.jokers), portrait_inventory_height(G.consumeables))
    if G.HUD_tags and #G.HUD_tags>0 then inventory_h=inventory_h+1.1 end
    local table_top = p.top_margin + inventory_h + p.selection_clearance
    scale = math.min(scale, (workspace_hud_y-p.hud_gap-table_top-p.selection_clearance)/(2*G.CARD_H))
    local hand_h = G.CARD_H * scale
    local hand_y = workspace_hud_y - p.hud_gap - hand_h
    local play_y = table_top + math.max(0, (hand_y - p.selection_clearance - hand_h - table_top)/2)
    return {width=room.w, height=height, scale=scale, hand_h=hand_h,
        hand_y=hand_y, play_y=play_y, hud_y=hud_y, action_y=action_y,
        inventory_h=inventory_h, inventory_scale=inventory_scale, table_top=table_top}
end

function portrait_inventory_metrics(area)
    local p = PORTRAIT_CONFIG.layout
    local joker_rows = G.jokers and G.jokers.cards and #G.jokers.cards > p.joker_wrap_after and 2 or 1
    local consume_rows = G.consumeables and G.consumeables.cards and #G.consumeables.cards > p.consumable_wrap_after and 2 or 1
    local rows = math.max(joker_rows, consume_rows)
    -- Each shelf owns its row count and scale. Extra consumables must not
    -- shrink a normal Joker row or reserve an empty second row beneath it.
    if area and area == G.jokers then rows = joker_rows
    elseif area and area == G.consumeables then rows = consume_rows end
    local scale = rows > 1 and p.inventory_wrap_scale or p.inventory_scale
    local s = G.STATES
    if rows > 1 and (G.STATE == s.SHOP or G.STATE == s.BLIND_SELECT or G.STATE == s.ROUND_EVAL
        or G.STATE == s.TAROT_PACK or G.STATE == s.PLANET_PACK or G.STATE == s.SPECTRAL_PACK
        or G.STATE == s.STANDARD_PACK or G.STATE == s.BUFFOON_PACK
        or (s.SMODS_BOOSTER_OPENED and G.STATE == s.SMODS_BOOSTER_OPENED)) then scale = p.inventory_panel_scale end
    return rows, scale
end

function portrait_inventory_height(area)
    local rows, scale = portrait_inventory_metrics(area)
    return G.CARD_H*scale*rows + PORTRAIT_CONFIG.layout.inventory_row_gap*(rows-1)
end

function portrait_inventory_count(area)
    -- Negative editions add capacity, not mandatory empty columns. Keep the
    -- normal empty slots, then distribute extra held cards over the same shelf.
    return math.max(#area.cards, math.min(area.config.card_limit, area == G.jokers and 5 or 2))
end

function portrait_inventory_slot(area, index, count)
    local rows, scale = portrait_inventory_metrics(area)
    local columns = math.ceil(count/rows)
    local row = math.floor((index-1)/columns)
    local col = (index-1)%columns
    local card_h = G.CARD_H*scale
    local x = area.T.x + (columns == 1 and area.T.w/2 or area.card_w/2 + (area.T.w-area.card_w)*col/(columns-1))
    local y = area.T.y + card_h/2 + row*(card_h+PORTRAIT_CONFIG.layout.inventory_row_gap)
    return x,y
end

function portrait_canvas_settings()
    local settings = {type='2d', readable=true}
    if G.F_PORTRAIT and PORTRAIT_CONFIG.quality.native_canvas_dpi then
        -- LOVE uses logical coordinates for input/layout; DPI belongs to the
        -- render target. Never multiply TILESCALE or touch coordinates by DPI.
        settings.dpiscale = love.graphics.getDPIScale()
    end
    return settings
end

function portrait_anchor_run_ui(box, y)
    if not box then return end
    box:set_alignment({type='a'})
    box:set_role({role_type='Major'})
    box.T.x = (G.ROOM.T.w - box.T.w)/2
    box.T.y = y
end

function portrait_position_run_areas()
    local p, l = PORTRAIT_CONFIG.layout, portrait_run_layout()
    local full_w = l.width - 2*p.side_margin
    G.jokers.T.x, G.jokers.T.y = p.side_margin, p.top_margin
    G.jokers.T.w, G.jokers.T.h = full_w-p.consumable_width-p.inventory_gap, portrait_inventory_height(G.jokers)
    G.consumeables.T.x, G.consumeables.T.y = l.width-p.side_margin-p.consumable_width, p.top_margin
    G.consumeables.T.w, G.consumeables.T.h = p.consumable_width, portrait_inventory_height(G.consumeables)
    -- Keep the original earned-tag UIBoxes in one row below the inventory.
    -- Re-anchor every tag independently so removal never leaves a broken chain.
    local tags=G.HUD_tags or {}
    local tag_y=math.max(G.jokers.T.y+G.jokers.T.h,G.consumeables.T.y+G.consumeables.T.h)+0.18
    local tag_x=p.side_margin
    local tag_size=math.min(0.8,math.max(0.1,full_w/math.max(1,#tags)-0.24))
    local total=0
    for _,tag in ipairs(tags) do
        local icon=tag.UIRoot.children[1].children[1]
        if icon.config.w~=tag_size then
            icon.config.w,icon.config.h=tag_size,tag_size
            icon.config.object.T.w,icon.config.object.T.h=tag_size,tag_size
            tag:recalculate()
        end
        total=total+tag.T.w
    end
    local gap=#tags>1 and math.min(0.12,math.max(0,(full_w-total)/(#tags-1))) or 0
    for _,tag in ipairs(tags) do
        tag:set_alignment({type='tli',major=G.ROOM_ATTACH,bond='Weak',
            offset={x=tag_x-G.ROOM_ATTACH.T.x,y=tag_y-G.ROOM_ATTACH.T.y}})
        tag_x=tag_x+tag.T.w+gap
    end
    local deck = portrait_footer_deck_metrics()
    G.deck.T.w, G.deck.T.h = G.CARD_W*deck.scale, G.CARD_H*deck.scale
    G.hand.T.w, G.hand.T.h = full_w, l.hand_h
    G.hand.T.x = p.side_margin
    G.play.T.x, G.play.T.y = p.side_margin, l.play_y
    G.play.T.w, G.play.T.h = full_w, l.hand_h
    G.discard.T.x, G.discard.T.y = l.width+p.deck_gap, l.play_y
    -- Counters are measured UIBoxes, not stretchable labels. Recreate them
    -- when a negative inventory changes row count and the hand resizes.
    for _, area in ipairs({G.hand, G.jokers, G.consumeables, G.deck}) do
        local size = area.portrait_counter_size
        if size and (math.abs(size.w-area.T.w)>0.001 or math.abs(size.h-area.T.h)>0.001) then
            if area.children.area_uibox then area.children.area_uibox:remove(); area.children.area_uibox=nil end
        end
        if not size or size.w ~= area.T.w or size.h ~= area.T.h then
            area.portrait_counter_size = {w=area.T.w, h=area.T.h}
        end
    end
    portrait_anchor_run_ui(G.HUD, l.hud_y)
    portrait_anchor_run_ui(G.buttons, l.action_y)
    local dock = G.HUD and G.HUD:get_UIE_by_ID('portrait_deck_dock')
    if dock then
        G.deck.T.x = dock.T.x+(dock.T.w-G.deck.T.w)/2
        G.deck.T.y = dock.T.y+(dock.T.h-G.deck.T.h-p.deck_counter_height)/2
    else
        G.deck.T.x = l.width-p.side_margin-G.deck.T.w
        G.deck.T.y = l.hud_y+ (G.HUD and G.HUD.T.h or 6)-deck.h+p.deck_footer_padding
    end
    local panel = G.STATE == G.STATES.SHOP and G.shop or G.STATE == G.STATES.BLIND_SELECT and G.blind_select or G.STATE == G.STATES.ROUND_EVAL and G.round_eval
    if panel and panel.portrait_target_y and math.abs(panel.alignment.offset.y-panel.portrait_target_y)<0.001 then
        if panel.portrait_inventory_h ~= l.inventory_h or panel.portrait_h ~= panel.T.h or panel.portrait_hud_y ~= l.hud_y then
            portrait_anchor_run_panel(panel)
        end
    end
    return l
end

-- Panels share the middle workspace. Keep their existing entrance/exit
-- animations; only replace the final anchor when each panel opens.
function portrait_anchor_run_panel(box, below_hand)
    local p, l = PORTRAIT_CONFIG.layout, portrait_run_layout()
    if below_hand then
        box:set_alignment({major=G.ROOM_ATTACH, type='tmi', bond='Weak',
            offset={x=0, y=p.top_margin+l.inventory_h+PORTRAIT_CONFIG.pack.top_gap-G.ROOM_ATTACH.T.y}})
        return
    end
    local top = below_hand and l.table_top+l.hand_h+p.panel_gap or p.top_margin+l.inventory_h+p.panel_inventory_gap
    local bottom = l.hud_y-p.hud_gap
    local y = top + math.max(0, (bottom-top-box.T.h)/2)
    box:set_alignment({major=G.ROOM_ATTACH, type='tmi', bond='Weak', offset={x=0, y=y-G.ROOM_ATTACH.T.y}})
    box.portrait_target_y = box.alignment.offset.y
    box.portrait_inventory_h, box.portrait_h, box.portrait_hud_y = l.inventory_h, box.T.h, l.hud_y
end

-- Change actual dimensions (including hitboxes), preserving special Joker
-- proportions. The previous dimensions are transient and never enter saves.
function portrait_scale_area_cards(area)
    local p, scale = PORTRAIT_CONFIG.layout, 1
    if G.F_PORTRAIT then
        if area == G.hand or area == G.play then scale = portrait_run_layout().scale
        elseif area == G.jokers or area == G.consumeables then local _, s = portrait_inventory_metrics(area); scale = s
        elseif area == G.deck then scale = portrait_footer_deck_metrics().scale
        elseif area == G.pack_cards then scale = area.config.portrait_pack_scale or 1 end
    end
    if area == G.hand or area == G.play or area == G.jokers or area == G.consumeables or area == G.deck or area == G.pack_cards then
        area.card_w = (area.config.card_w or G.CARD_W)*scale
    end
    for _, card in ipairs(area.cards) do
        local prev = card.portrait_dimensions
        local w, h = card.T.w, card.T.h
        if not prev or prev.scale ~= scale or math.abs(w-prev.w) > 0.0001 or math.abs(h-prev.h) > 0.0001 then
            if prev then
                if math.abs(w-prev.w) < 0.0001 then w = w/prev.scale end
                if math.abs(h-prev.h) < 0.0001 then h = h/prev.scale end
            end
            card.T.w, card.T.h = w*scale, h*scale
            card.portrait_dimensions = {w=card.T.w, h=card.T.h, scale=scale}
        end
    end
end

function apply_portrait_tooltip_fit(config)
    if config and G and G.F_PORTRAIT then
        if config.can_collide == nil then config.can_collide = false end
        if config.can_drag == nil then config.can_drag = false end
        if config.fit_to_room == nil then config.fit_to_room = true end
        if config.fit_to_room then
            config.lr_clamp = false
        elseif config.lr_clamp == nil then
            config.lr_clamp = true
        end
        -- Popups are already placed above or below their card depending on where
        -- that card sits, so pushing them clear of the finger on top of that only
        -- made them jump around as the touch moved (#44). Off unless a caller
        -- explicitly asks for it.
        if config.touch_above_cursor == nil then config.touch_above_cursor = false end
        if config.snap_to_fit == nil then config.snap_to_fit = true end
    end

    return config
end

function prepare_portrait_popup_fit(box)
    if not (G and G.F_PORTRAIT and box) then return end

    if box.config then
        apply_portrait_tooltip_fit(box.config)
    end
    if box.states then
        if box.states.collide then box.states.collide.can = false end
        if box.states.drag then box.states.drag.can = false end
    end

    if require("portrait_popup_layout").place(box) then return end
    if box.align_to_major then box:align_to_major() end
    if box.fit_to_room then box:fit_to_room() end
    if box.hard_set_VT then box:hard_set_VT() end
    if box.UIRoot and box.UIRoot.initialize_VT then
        box.UIRoot:initialize_VT(true)
    end
end

function get_portrait_room_fit_delta(box, opts)
    opts = opts or {}

    if not (G and G.F_PORTRAIT and G.ROOM and G.ROOM.T and box and box.T) then
        return 0, 0
    end

    local viewport=require('portrait_popup_layout').viewport(opts,box.container)
    local left,top=viewport.x,viewport.y
    local right,bottom=left+viewport.w,top+viewport.h
    local min_x = box.T.x
    local min_y = box.T.y
    local max_x = box.T.x + box.T.w
    local max_y = box.T.y + box.T.h
    local dx = 0
    local dy = 0

    if opts.touch_above_cursor and G.CONTROLLER and G.CONTROLLER.HID and G.CONTROLLER.HID.touch and G.CONTROLLER.cursor_position and G.TILESCALE and G.TILESIZE then
        local touch_gap = opts.touch_gap or (PORTRAIT_CONFIG and PORTRAIT_CONFIG.tooltip_touch_gap) or 1.25
        local cursor_y = G.CONTROLLER.cursor_position.y / (G.TILESCALE * G.TILESIZE) - (G.ROOM.T.y or 0)
        local desired_bottom = cursor_y - touch_gap
        if max_y + dy > desired_bottom then
            dy = desired_bottom - max_y
        end
    end

    if box.T.w >= (right - left) then
        dx = left - min_x
    else
        if min_x + dx < left then dx = left - min_x end
        if max_x + dx > right then dx = right - max_x end
    end

    if box.T.h >= (bottom - top) then
        dy = top - min_y
    else
        if min_y + dy < top then dy = top - min_y end
        if max_y + dy > bottom then dy = bottom - max_y end
    end

    return dx, dy
end

function fit_portrait_side_tooltip(box, parent)
    if not (G and G.F_PORTRAIT and G.ROOM and G.ROOM.T and box and box.T and parent) then return end

    local padding = (PORTRAIT_CONFIG and PORTRAIT_CONFIG.tooltip_screen_padding) or 0.12
    if box.T.x < padding then
        box:set_alignment({
            major = parent,
            type = 'cr',
            bond = 'Strong',
            offset = {x = 0.03, y = 0},
            lr_clamp = false
        })
        box:align_to_major()
    end

    box.config.fit_to_room = true
    box.config.lr_clamp = false
    box.config.touch_above_cursor = false
    box.config.screen_padding = padding
    if box.fit_to_room then box:fit_to_room() end
    if prepare_portrait_popup_fit then
        prepare_portrait_popup_fit(box)
    elseif box.UIRoot and box.UIRoot.initialize_VT then
        box.UIRoot:initialize_VT()
    end
end

function get_portrait_side_tooltip_config(parent)
    local align = 'cl'
    local offset = {x = -0.03, y = 0}
    if G and G.F_PORTRAIT and G.ROOM and G.ROOM.T and parent and parent.T then
        local parent_cx = parent.T.x + parent.T.w/2
        if parent_cx < G.ROOM.T.w/2 then
            align = 'cr'
            offset = {x = 0.03, y = 0}
        end
    end
    return align, offset
end

-- Preferred direction only; UIBox measures every section before flip/clamp.
function get_portrait_top_popup_config(sprite, opts)
    opts=opts or {}
    local parent=opts.parent or sprite
    if not (G and G.F_PORTRAIT and G.ROOM and sprite and sprite.T) then
        return {align='cl',offset={x=-.1,y=0},parent=parent}
    end
    local dir=sprite.T.y+sprite.T.h/2>G.ROOM.T.h/2 and 'tm' or 'bm'
    return {major=parent,parent=parent,type=dir,offset={x=0,y=0},
        fit_to_room=true,snap_to_fit=true,can_drag=false}
end
