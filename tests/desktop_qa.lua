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
    G.FUNCS.select_blind({config = {ref_table = G.P_BLINDS.bl_small}})
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
step('eight_jokers', function()
    for i = 1, 3 do
        local c = create_card('Joker', G.jokers, nil, nil, nil, nil, 'j_joker')
        c:set_edition({negative = true}, true); c:add_to_deck(); G.jokers:emplace(c)
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
step('play_hand', function() G.FUNCS.play_cards_from_highlighted() end, 18)
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
step('shop_pack', function()
    G.FUNCS.use_card({config = {ref_table = G.shop_booster.cards[1]}})
end, 5)
step('pack_close', function() G.FUNCS.skip_booster() end, 4)
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

if QA.resume then
    steps = {}
    step('restored_run', function()
        local raw = assert(get_compressed('1/save.jkr'), 'checkpoint missing after process restart')
        local saved = assert(STR_UNPACK(raw))
        local expected = saved.GAME.pseudorandom.seed
        G:delete_run(); G:start_run({savetext = saved})
        assert(G.GAME.pseudorandom.seed == expected, 'restored seed changed')
        record('PASS: restored previous process checkpoint with seed ' .. expected)
    end, 4)
end

local previous_load, previous_update, previous_draw = love.load, love.update, love.draw
local index, elapsed, pending = 0, 0, nil
function love.load(...)
    previous_load(...)
    G.SETTINGS.SOUND.volume = 0 -- QA only; production audio is unchanged.
    record('Save directory: ' .. love.filesystem.getSaveDirectory())
end
function love.update(dt)
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
    love.graphics.captureScreenshot(function(data)
        write(name .. '.png', data:encode('png'):getString())
        record('PASS: ' .. name)
    end)
    index = index + 1; elapsed = 0
    if index > #steps then love.event.quit(); return end
    steps[index].fn()
end
