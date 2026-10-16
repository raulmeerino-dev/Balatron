-- Runs only inside tools/desktop_qa.py's isolated test archive.
local function write(name, data)
    local f = assert(io.open(QA.out .. '/' .. name, 'wb'))
    f:write(data); f:close()
end
local log = {}
local function record(message)
    log[#log + 1] = message
    write('result.txt', table.concat(log, '\n'))
end
love.errorhandler = function(message)
    record('FAIL: ' .. tostring(message) .. '\n' .. debug.traceback())
    return function() return 1 end
end
love.errhand = love.errorhandler

local steps = {}
local function step(name, fn, delay)
    steps[#steps + 1] = {name = name, fn = fn, delay = delay or 1.0}
end
local function close()
    if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end
end
step('main_menu', function()
    G.SETTINGS.tutorial_complete = true
    G.SETTINGS.tutorial_progress = nil
    G:delete_run(); G:main_menu()
end, 2)
if QA.skin then
    step('skin_selector', function()
        CardSkins.select(2)
        G.FUNCS.customize_deck()
    end)
    step('skin_default', function()
        G.FUNCS.change_card_skin({to_key=1})
        for _, card in pairs(G.I.CARD) do
            if card.children.front then assert(not card.children.front.atlas.name:find('skin_'), 'Default did not restore cards') end
        end
    end)
    step('skin_deck1', function()
        G.FUNCS.change_card_skin({to_key=2})
        for key, front in pairs(G.P_CARDS) do
            local card = Card(0,0,G.CARD_W,G.CARD_H,front,G.P_CENTERS.c_base)
            assert(card.children.front.atlas.name=='skin_deck1_fronts', key..' atlas missing')
            assert(card.children.front.sprite_pos.x==front.pos.x and card.children.front.sprite_pos.y==front.pos.y, key..' UV wrong')
            assert(card.children.back.atlas.name=='skin_deck1_back', key..' back wrong')
            card:set_ability(G.P_CENTERS.m_gold, true)
            assert(card.children.front.atlas.name=='skin_deck1_enhanced', 'gold hidden by paper')
            card:set_ability(G.P_CENTERS.c_base, true)
            assert(card.children.front.atlas.name=='skin_deck1_fronts', 'base paper did not return')
            card:remove()
        end
        G.SETTINGS.colourblind_option=true; G.FUNCS.refresh_contrast_mode()
        assert(CardSkins.active()=='deck1', 'contrast reset skin')
        G.SETTINGS.colourblind_option=false; G.FUNCS.refresh_contrast_mode()
    end)
end
for _, name in ipairs({'options', 'settings', 'your_collection', 'your_collection_jokers',
    'your_collection_tarots', 'your_collection_planets', 'your_collection_spectrals',
    'your_collection_blinds', 'your_collection_tags', 'your_collection_vouchers',
    'your_collection_decks', 'your_collection_boosters', 'profile_select', 'high_scores',
    'usage', 'challenge_list', 'language_selection',
    'setup_run', 'open_portrait_diagnostics', 'next_portrait_diagnostics'}) do
    local callback = name
    step(name, function() close(); G.FUNCS[callback]({config = {id = 'qa'}}) end)
end
step('blind_selection', function()
    close(); G:delete_run(); G:start_run({seed = 'PORTRAIT'})
end, 3)
step('hand', function()
    G.FUNCS.select_blind({config = {ref_table = G.P_BLINDS.bl_small}, UIBox=G.blind_select})
end, 4)
for _, name in ipairs({'run_info', 'deck_info', 'current_hands'}) do
    local callback = name
    step(name, function() close(); G.FUNCS[callback]() end)
end
step('one_joker', function()
    close()
    local c = create_card('Joker', G.jokers, nil, nil, nil, nil, 'j_joker')
    c:add_to_deck(); G.jokers:emplace(c)
end)
step('five_jokers', function()
    for i = 1, 4 do
        local c = create_card('Joker', G.jokers, nil, nil, nil, nil, 'j_joker')
        c:add_to_deck(); G.jokers:emplace(c)
    end
end)
step('consumables', function()
    for _, key in ipairs({'c_fool', 'c_pluto'}) do
        local c = create_card(nil, G.consumeables, nil, nil, nil, nil, key)
        c:add_to_deck(); G.consumeables:emplace(c)
    end
end)
step('left_deck', function() G.SETTINGS.play_main_hand = 1; set_screen_positions() end)
step('swipe_only', function() on_swipe_only_setting_changed(true) end)
step('restore_buttons', function()
    G.SETTINGS.play_main_hand = 2; on_swipe_only_setting_changed(false)
end)
step('eight_jokers', function()
    for i = 1, 3 do
        local c = create_card('Joker', G.jokers, nil, nil, nil, nil, 'j_joker')
        c:set_edition({negative = true}, true); c:add_to_deck(); G.jokers:emplace(c)
    end
end)
step('twelve_jokers', function()
    for i=1,4 do
        local c = create_card('Joker', G.jokers, nil, nil, nil, nil, 'j_joker')
        c:set_edition({negative=true}, true); c:add_to_deck(); G.jokers:emplace(c)
    end
end)
step('negative_consumables', function()
    for i=1,4 do
        local c = create_card(nil, G.consumeables, nil, nil, nil, nil, 'c_pluto')
        c:set_edition({negative=true}, true); c:add_to_deck(); G.consumeables:emplace(c)
    end
end)
step('two_row_reorder', function()
    for _, area in ipairs({G.jokers,G.consumeables}) do
        local card=area.cards[1]
        card.states.drag.is=true
        card.T.x=area.T.x+area.T.w-card.T.w/2
        card.T.y=area.T.y+area.T.h-card.T.h
        area:align_cards()
        assert(area.cards[#area.cards]==card, 'drag across inventory rows changed order incorrectly')
        card.states.drag.is=false; area:align_cards()
        card:click(); assert(card.highlighted, 'inventory card cannot be selected'); card:click()
    end
end)
step('joker_tooltip', function() G.jokers.cards[1]:hover() end)
step('selected_hand', function()
    G.jokers.cards[1]:stop_hover()
    for i = 1, 5 do G.hand:add_to_highlighted(G.hand.cards[i]) end
end)
step('modified_cards', function()
    G.hand.cards[1]:set_edition({foil = true}, true, true)
    G.hand.cards[1]:set_seal('Red', true, true)
    G.hand.cards[2]:set_ability(G.P_CENTERS.m_mult)
end)
step('large_hand', function()
    G.hand:unhighlight_all()
    G.hand.config.card_limit = 12
    for i = 1, 4 do draw_card(G.deck, G.hand, i*10, 'up', true) end
end, 3)
step('five_selected', function()
    for i = 1, 5 do G.hand:add_to_highlighted(G.hand.cards[i]) end
end)
step('resume', function()
    save_run(); love.visible(false); love.visible(true)
    assert(love.filesystem.getInfo('1/save.jkr'), 'run checkpoint was not saved')
    local saved = get_compressed('1/save.jkr')
    assert(saved and STR_UNPACK(saved), 'checkpoint cannot be decoded')
    record('PASS: checkpoint persisted and decoded')
end)
step('play_hand', function() G.SETTINGS.GAMESPEED=4; G.FUNCS.play_cards_from_highlighted() end, 16)
step('cashout', function()
    assert(G.round_eval, 'natural round payout did not open')
end, 3)
step('shop', function()
    G:delete_run(); G:start_run({seed = 'PORTRAIT'})
    G.STATE = G.STATES.SHOP; G.STATE_COMPLETE = false
end, 4)
local bought_card
step('shop_buy', function()
    assert(G.shop and G.shop_jokers, 'shop not available')
    G.GAME.dollars = 100
    bought_card = G.shop_jokers.cards[#G.shop_jokers.cards]
    G.FUNCS.buy_from_shop({config = {ref_table = bought_card, id = 'buy'}})
end, 3)
step('shop_sell', function()
    assert(bought_card.area ~= G.shop_jokers, 'purchase did not move the card')
    G.FUNCS.sell_card({config = {ref_table = bought_card}})
end, 3)
step('shop_reroll', function() G.FUNCS.reroll_shop() end, 3)
step('shop_negative_inventory', function()
    for i=1,12 do
        local c = create_card('Joker', G.jokers, nil, nil, nil, nil, 'j_joker')
        if i>5 then c:set_edition({negative=true},true) end
        c:add_to_deck(); G.jokers:emplace(c)
    end
    for i=1,6 do
        local c = create_card(nil, G.consumeables, nil, nil, nil, nil, 'c_pluto')
        if i>2 then c:set_edition({negative=true},true) end
        c:add_to_deck(); G.consumeables:emplace(c)
    end
end)
step('shop_pack', function()
    G.FUNCS.use_card({config = {ref_table = G.shop_booster.cards[1]}})
end, 5)
step('pack_close', function() G.FUNCS.skip_booster() end, 4)
for _, key in ipairs({'p_arcana_normal_1', 'p_celestial_normal_1', 'p_spectral_normal_1', 'p_standard_normal_1', 'p_buffoon_normal_1'}) do
    local pack_key = key
    step(pack_key, function()
        local c = Card(G.shop_booster.T.x, G.shop_booster.T.y, G.CARD_W, G.CARD_H, nil, G.P_CENTERS[pack_key])
        G.shop_booster:emplace(c); G.GAME.dollars = 100
        G.FUNCS.use_card({config = {ref_table = c}})
    end, 4)
    step(pack_key..'_selected', function()
        assert(G.pack_cards and G.pack_cards.cards[1], 'pack did not open')
        G.pack_cards:add_to_highlighted(G.pack_cards.cards[1])
    end)
    step(pack_key..'_close', function() G.FUNCS.skip_booster() end, 3)
end
step('victory', function()
    G.SETTINGS.paused = true
    G.FUNCS.overlay_menu{definition = create_UIBox_win()}
end)
step('game_over', function()
    close(); G.SETTINGS.paused = true
    G.FUNCS.overlay_menu{definition = create_UIBox_game_over()}
end)
step('diagnostics', function()
    assert(G.shop and G.shop_jokers and #G.shop_jokers.cards > 0, 'shop did not load')
    write('diagnostics.txt', portrait_diagnostics_report())
    record('PASS: all scenarios rendered; desktop iOS API simulation only')
end)

if QA.layout then
    local filtered, in_run = {}, false
    for _, item in ipairs(steps) do
        if item.name == 'blind_selection' then in_run = true end
        if in_run or item.name == 'main_menu' or item.name:find('^skin_') then filtered[#filtered+1] = item end
    end
    steps = filtered
end

if QA.resume then
    steps = {}
    local checkpoint, negative_limit
    step('restored_run', function()
        local raw = assert(get_compressed('1/save.jkr'), 'checkpoint missing after process restart')
        local saved = assert(STR_UNPACK(raw))
        checkpoint = saved
        local expected = saved.GAME.pseudorandom.seed
        G:delete_run(); G:start_run({savetext = saved})
        assert(G.GAME.pseudorandom.seed == expected, 'restored seed changed')
        for _, key in ipairs({'jokers','consumeables','hand'}) do
            if saved.cardAreas[key] then
                assert(#G[key].cards==#saved.cardAreas[key].cards, 'restored card count changed: '..key)
                assert(G[key].config.card_limit==saved.cardAreas[key].config.card_limit, 'restored capacity changed: '..key)
            end
        end
        record('PASS: restored previous process checkpoint with seed ' .. expected)
    end, 4)
    if QA.modded then
        step('dismiss_unlock',function() close() end,4)
        step('legacy_shop_and_negative_slots',function()
            for _,key in ipairs({'jokers','consumeables','hand'}) do
                assert(G[key].config.card_limit==checkpoint.cardAreas[key].config.card_limit,'Migrated capacity changed: '..key)
            end
            assert(#G.shop_jokers.cards==#checkpoint.cardAreas.shop_jokers.cards)
            for i,c in ipairs(G.shop_jokers.cards) do
                assert(c.config.center.key==checkpoint.cardAreas.shop_jokers.cards[i].save_fields.center)
            end
            for _,c in ipairs(G.jokers.cards) do
                if c.edition and c.edition.negative then
                    negative_limit=G.jokers.config.card_limit
                    G.FUNCS.sell_card({config={ref_table=c}}); break
                end
            end
            record('PASS: legacy shop identities, negatives and capacities preserved')
        end,3)
        step('legacy_reroll',function()
            if negative_limit then assert(G.jokers.config.card_limit==negative_limit-1) end
            G.GAME.dollars=100; G.FUNCS.reroll_shop()
        end,3)
        step('legacy_next_blind',function() G.FUNCS.toggle_shop() end,4)
        step('legacy_select',function()
            local id=G.GAME.round_resets.blind_choices[G.GAME.blind_on_deck]
            G.FUNCS.select_blind({config={ref_table=G.P_BLINDS[id]},UIBox=G.blind_select})
        end,4)
        step('legacy_play',function()
            G.GAME.blind.chips=1; G.SETTINGS.GAMESPEED=4
            G.hand:unhighlight_all(); G.hand:add_to_highlighted(G.hand.cards[1])
            G.FUNCS.play_cards_from_highlighted()
        end,12)
        step('legacy_win',function()
            assert(G.round_eval,'Migrated run did not play to a victory')
            save_run(); love.visible(false); love.visible(true)
            local saved=STR_UNPACK(assert(get_compressed('1/save.jkr')))
            assert(saved.SCORING_CALC and saved.cardAreas.jokers.config.card_limits)
            assert(love.filesystem.getInfo('1/save.pre-steamodded.jkr'))
            record('PASS: legacy migration plays, wins, sells negative, rerolls and saves; original checkpoint backed up')
        end)
    end
end

if QA.compound then
    steps = {}
    require('compound_interest_qa')(step, record, write)
end
if QA.run_jokers then
    steps = {}
    require('run_jokers_qa')(step,record,write)
end

if QA.discovery and QA.discovery~='' then
    steps = {}
    require('compound_discovery_qa')(step, record, write)
end

if QA.background and QA.background~='' then
    steps = {}
    require('background_qa')(step, record, write)
end


-- Directed final review, confined to the isolated desktop archive.
if QA.final_review then
    steps={}
    local B
    step('release_init',function() B=PortraitEvents.black_market end)
    local owned={}
    local function add(key)
        local c=SMODS.add_card{key=key,area=G.jokers};owned[key]=c;return c
    end
    local function panel(def) close();G.SETTINGS.paused=true;G.FUNCS.overlay_menu{definition=create_UIBox_generic_options{contents={def}}} end
    local function verify_saved()
        assert(G.GAME.run_is_modded and #G.GAME.active_mods_snapshot==7,'Run snapshot missing modules')
        assert(G.GAME.evolution_history[1] and G.GAME.fusion_history[1],'History lost')
        local found={};for _,c in ipairs(G.jokers.cards) do found[c.config.center.key]=c end
        assert(found.j_upg_metamorphosis.ability.extra.stage==2)
        assert(found.j_upg_bottomless.ability.extra.accumulated_mult==UPGJokers.registry.config().hungry_mult_per_destroyed)
        assert(found.j_risk_burning_fuse.ability.extra.xmult==5.5)
        assert(found.j_incj_compound_interest.ability.extra.won_rounds==1)
        assert(PortraitGameplay.modules.contracts.active()[1].progress==1 and G.GAME.deck_mutations.levels.heavy_hearts==1)
        assert(B.state().heat>=2 and B.current().inventory and B.current().rerolls==1)
        assert(IncJoker.enabled(),'Mid-run toggle changed saved generation')
        assert(G.P_CENTERS.j_incj_compound_interest.discovered,'Discovery lost')
        assert(G.P_CENTERS.j_fuse_midas.discovered,'Fusion discovery lost')
    end
    if QA.resume then
        step('release_reopened',function()
            local saved=STR_UNPACK(assert(get_compressed('1/save.jkr')))
            G:delete_run();G:start_run{savetext=saved};verify_saved()
        end,4)
        step('resume_dismiss',function() close() end,3)
        step('restored_market',function() close();B.current().available=true;B.enter() end,3)
        step('restored_inventory',function()
            assert(B.active and #G.shop_jokers.cards==#B.current().inventory.shop_jokers.cards)
            for i,c in ipairs(G.shop_jokers.cards) do assert(c.config.center.key==B.current().inventory.shop_jokers.cards[i].save_fields.center) end
            B.back()
            record('PASS: saved custom state, discoveries, snapshots and Black Market stock survive process restart')
        end,3)
        step('release_settings',function() close();G.FUNCS.settings() end)
        step('release_controls',function() panel(G.UIDEF.settings_tab('Controls')) end)
        step('release_mod_manager',function() close();G.FUNCS.mods_button() end)
    else
        step('release_language',function()
            G.SETTINGS.tutorial_complete=true;G.SETTINGS.tutorial_progress=nil
            G.SETTINGS.language='es_ES';G:set_language();G:init_item_prototypes();G:main_menu()
        end,2)
        step('release_settings',function() close();G.FUNCS.settings() end)
        step('release_controls',function() panel(G.UIDEF.settings_tab('Controls')) end)
        step('release_mod_manager',function() close();G.FUNCS.mods_button() end)
        for _,id in ipairs({'incremental_joker','upgraded_jokers','risk_jokers','portrait_events','deck_mutations','contracts','joker_fusion'}) do
            local key=id;step('config_'..key,function() panel(SMODS.Mods[key].config_tab()) end)
        end
        step('release_run',function()
            close();G:delete_run();G:start_run{};CardSkins.select(2)
            G.SETTINGS.animation_speed='FAST';G.GAME.dollars=200
            G.jokers.config.card_limit=20
            for _,key in ipairs({'j_incj_compound_interest','j_upg_metamorphosis','j_upg_bottomless',
                'j_risk_burning_fuse','j_risk_greed','j_golden','j_risk_russian_joker','j_risk_glass_cannon'}) do add(key) end
            G.GAME.incj_config.enabled=true
            SMODS.Mods.incremental_joker.config.enabled=false
            assert(IncJoker.enabled(),'Config leaked into current run')
            local E=UPGJokers.evolution
            local meta=owned.j_upg_metamorphosis
            G.GAME.facing_blind=true;G.GAME.blind.chips=1;G.GAME.chips=1
            G.GAME.blind.config.blind=G.P_BLINDS.bl_small
            meta.ability.extra.progress=3
            local context={end_of_round=true,main_eval=true}
            E.advance(UPGJokers.registry.entries.metamorphosis,meta,context)
            E.advance(UPGJokers.registry.entries.metamorphosis,meta,context)
            assert(meta.ability.extra.stage==2 and meta.ability.extra.progress==0)
            for _,key in ipairs({'j_incj_compound_interest','j_risk_burning_fuse'}) do
                local c=owned[key];c.config.center:calculate(c,context);c.config.center:calculate(c,context)
                c.config.center:calculate(c,{end_of_round=true,main_eval=true,blueprint=true})
            end
            local bottom=owned.j_upg_bottomless
            E.advance(UPGJokers.registry.entries.bottomless,bottom,{remove_playing_cards=true,removed={G.playing_cards[1]}})
            E.advance(UPGJokers.registry.entries.bottomless,bottom,{remove_playing_cards=true,removed={G.playing_cards[1]}})
            assert(bottom.ability.extra.accumulated_mult==UPGJokers.registry.config().hungry_mult_per_destroyed,'Duplicate destruction progress')
            G.GAME.facing_blind=false
            G.GAME.contracts.active={id='clean_hands',progress=1,target=3,seen_destroyed={}}
            G.GAME.deck_mutations.levels={heavy_hearts=1}
            G.STATE=G.STATES.SHOP;G.STATE_COMPLETE=false
        end,4)
        step('release_fusion',function()
            close();local F=PortraitGameplay.modules.joker_fusion;local a,b=F.components(F.entries.midas)
            assert(F.fuse{id='midas',a=a,b=b});assert(#G.GAME.fusion_history==1)
        end,2)
        step('release_run_info',function() close();G.FUNCS.run_info() end)
        step('release_active_mods',function() panel(PortraitQOL.active_mods()) end)
        step('release_history',function() panel(PortraitQOL.history_panel('evolution')) end)
        step('release_full_deck',function() close();G.FUNCS.deck_info() end)
        step('release_black_market',function() close();B.current().available=true;B.enter() end,3)
        step('release_contraband_cancel',function()
            assert(B.active and #B.contraband.order==8)
            local card=B.create('cb_evt_marked_card',G.shop_booster);G.shop_booster:emplace(card)
            local money,heat=G.GAME.dollars,B.state().heat
            B.contraband.buy(card);G.FUNCS.evt_bm_cancel_pick()
            assert(G.GAME.dollars==money and B.state().heat==heat and card.area==G.shop_booster)
            B.contraband.buy(card,G.playing_cards[2])
        end,2)
        step('release_reroll',function() B.reroll() end,3)
        step('release_save',function()
            assert(B.current().rerolls==1);B.back()
        end,3)
        step('release_checkpoint',function()
            verify_saved();save_run();G:save_progress();love.visible(false);love.visible(true)
            record('PASS: real loaders, custom effects, duplicate guards, fusion, contraband cancel/commit and save')
        end,3)
    end
end

local previous_load, previous_update, previous_draw = love.load, love.update, love.draw
local index, elapsed, pending, start_next = 0, 0, nil, false
function love.load(...)
    previous_load(...)
    if QA.modded then
        assert(SMODS and SMODS.Joker, 'Steamodded did not initialize')
        assert(IncJoker and G.P_CENTERS[IncJoker.key], 'Compound Interest did not register')
        assert(not IncJoker.config.debug and not IncJoker.debug_spawn, 'Release debug shortcut is enabled')
        record('PASS: actual Steamodded '..tostring(SMODS.version)..'; Lovely '..require('lovely').version)
    end
    if QA.skin and QA.resume then
        assert(CardSkins.active()=='deck1', 'skin selection did not persist after restart')
        record('PASS: Deck 1 setting restored from disk')
    end
    G.SETTINGS.SOUND.volume = 0 -- QA only; production audio is unchanged.
    record('Save directory: ' .. love.filesystem.getSaveDirectory())
end
function love.update(dt)
    if start_next then start_next=false; steps[index].fn() end
    previous_update(dt)
    elapsed = elapsed + dt
    if elapsed < (index == 0 and 2 or steps[index].delay) then return end
    if pending then return end
    if index > 0 then
        pending = steps[index].name
    else
        index = 1; elapsed = 0; steps[index].fn()
    end
end
function love.draw()
    previous_draw()
    if not pending then return end
    local name = pending
    pending = nil
    if G.STAGE == G.STAGES.RUN then
        local geometry = {portrait_diagnostics_report()}
        for _, key in ipairs({'HUD', 'HUD_blind', 'blind_select', 'shop', 'booster_pack', 'round_eval', 'buttons'}) do
            local box = G[key]
            if box then geometry[#geometry+1] = key..' VT '..box.VT.x..','..box.VT.y..' '..box.T.w..'x'..box.T.h..' offset '..box.alignment.offset.y..' role '..box.role.role_type end
        end
        write(name..'-geometry.txt', table.concat(geometry, '\n'))
        if name == 'consumables' or name == 'negative_consumables' then
            local pw, ph = G.CANVAS:getPixelDimensions()
            assert(pw == QA.w*QA.dpi and ph == QA.h*QA.dpi, 'canvas pixel density mismatch')
            write(name..'-native.png', G.CANVAS:newImageData():encode('png'):getString())
        end
    end
    love.graphics.captureScreenshot(function(data)
        write(name .. '.png', data:encode('png'):getString())
        record('PASS: ' .. name)
        index = index + 1; elapsed = 0
        if index > #steps then love.event.quit(); return end
        start_next = true
    end)
end
