package.path='src/?.lua;'..package.path
dofile('src/portrait_config.lua')
local f = assert(io.open('src/main.lua', 'rb'))
local source = f:read('*a'); f:close()
local first = assert(source:find('local function _check_swipe_gesture', 1, true))
local last = assert(source:find('function love.mousereleased', first, true))
local swipe = assert(loadstring(source:sub(first, last-1) .. '\nreturn _check_swipe_gesture'))()
local now, played, discarded = 1, 0, 0
love = {timer = {getTime = function() return now end},
    graphics = {getHeight = function() return 844 end,getWidth=function() return 393 end},
    system = {getOS = function() return 'iOS' end}, window = {}}
local function reset()
    now, played, discarded = 1, 0, 0
    G = {F_PORTRAIT = true, STATE = 1, STATES = {SELECTING_HAND = 1},
        TILESCALE = 1.5, TILESIZE = 20, SETTINGS = {},
        GAME = {blind = {}, current_round = {discards_left = 3}},
        play = {cards = {}}, hand = {highlighted = {}},
        FUNCS = {play_cards_from_highlighted = function() played = played+1 end,
            discard_cards_from_highlighted = function() discarded = discarded+1 end},
        CONTROLLER = {locks = {}, cursor_down = {}, gesture_start = {x=150,y=650,t=0.8,selected_card=true}}}
    local card = {area = G.hand, highlighted = true}
    G.hand.highlighted[1] = card; G.CONTROLLER.cursor_down.target = card
end
local function test(name, setup, x, y, p, d)
    reset(); if setup then setup() end
    swipe(x, y)
    assert(played == p and discarded == d, name)
    assert(G.CONTROLLER.gesture_start == nil, name .. ': gesture consumed once')
    print('ok - ' .. name)
end
test('selected swipe up plays once', nil, 150, 580, 1, 0)
test('selected swipe down discards once', nil, 150, 720, 0, 1)
test('jitter does not play', nil, 152, 648, 0, 0)
test('horizontal reorder does not play', nil, 250, 600, 0, 0)
test('unselected press does not play', function() G.CONTROLLER.gesture_start.selected_card=false end, 150,580,0,0)
test('background swipe does not play', function() G.CONTROLLER.cursor_down.target={} end,150,580,0,0)
test('long hold does not play', function() now=3 end,150,580,0,0)
test('overlay blocks play', function() G.OVERLAY_MENU={} end,150,580,0,0)
test('locked controller blocks play', function() G.CONTROLLER.locked=true end,150,580,0,0)
test('blind block respected', function() G.GAME.blind.block_play=true end,150,580,0,0)
test('no discards respected', function() G.GAME.current_round.discards_left=0 end,150,720,0,0)
test('active played cards block play', function() G.play.cards[1]={} end,150,580,0,0)
test('pause blocks play', function() G.SETTINGS.paused=true end,150,580,0,0)

-- High DPI must not change tile-space safe boundaries.
for _, scale in ipairs({1,2,3}) do
    reset()
    G.TILESCALE = 1.5*scale
    G.ROOM = {T={x=0,y=59/30,w=13.1,h=26}}
    love.window.getSafeArea = function() return 0,59*scale,393*scale,759*scale end
    local box = {T={x=11,y=25,w=2,h=3}}
    local dx,dy = get_portrait_room_fit_delta(box)
    local safe_bottom = (59+759)/30-G.ROOM.T.y-PORTRAIT_CONFIG.tooltip_screen_padding
    assert(box.T.y+dy+box.T.h <= safe_bottom+1e-9, 'tooltip crosses home indicator')
    assert(box.T.x+dx+box.T.w <= 13.1, 'tooltip crosses right edge')
    print('ok - tooltip safe bounds at scale ' .. scale)
end
print('ALL PASSED')
