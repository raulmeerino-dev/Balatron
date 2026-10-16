dofile('src/portrait_config.lua')
local checks = 0
local function check(ok, message)
    assert(ok, message); checks = checks + 1
end
local states = {SELECTING_HAND=1, DRAW_TO_HAND=2, HAND_PLAYED=3, SHOP=4}
for _, screen in ipairs({{375,667,20,0,0.70,6.60,3.01}, {390,844,47,34,0.63,6.34,2.79}, {393,852,59,34,0.63,6.34,2.79}}) do
    local w,h,top,bottom,zoom,hud,buttons = unpack(screen)
    local unit = w/(20*zoom)
    love = {window={getSafeArea=function() return 0,top,w,h-top-bottom end}}
    G = {ROOM={T={w=20*zoom,h=h/unit}}, CARD_W=2.4*35/41, CARD_H=2.4*47/41,
        TILESCALE=unit/20,TILESIZE=20,STATES=states,STATE=1,F_PORTRAIT=true,
        HUD={T={h=hud}},buttons={T={h=buttons}}}
    for _, swipe in ipairs({false,true}) do
        G.F_SWIPE_ONLY=swipe; G.buttons.T.h=swipe and 1.85 or buttons
        local l=portrait_run_layout()
        check(l.scale>1.2, 'hand must be larger on '..w)
        check(l.play_y>=l.table_top, 'played cards below inventory')
        check(l.play_y+l.hand_h+PORTRAIT_CONFIG.layout.selection_clearance<=l.hand_y+0.001, 'selected hand clears play area')
        check(l.hand_y+l.hand_h<l.hud_y, 'hand clears HUD')
        check(l.hud_y+hud<l.action_y, 'HUD clears buttons')
        check(l.action_y+G.buttons.T.h<(h-top-bottom)/unit, 'buttons clear bottom inset')
    end
    G.hand={cards={{T={w=G.CARD_W,h=G.CARD_H}}},config={}}
    local card=G.hand.cards[1]
    local scale=portrait_run_layout().scale
    for i=1,200 do portrait_scale_area_cards(G.hand) end
    check(math.abs(card.T.w-G.CARD_W*scale)<0.00001, 'card scaling must not accumulate')
    G.deck={cards={card},config={}}
    portrait_scale_area_cards(G.deck)
    check(math.abs(card.T.h-G.CARD_H*portrait_footer_deck_metrics().scale)<0.00001, 'transfer uses touch-sized footer deck')
    check(card.T.w>=portrait_touch_height(0)-0.00001, 'footer deck remains a usable touch target')
    G.F_PORTRAIT=false; portrait_scale_area_cards(G.deck)
    check(math.abs(card.T.h-G.CARD_H)<0.00001, 'landscape restores natural size')
    G.F_PORTRAIT=true; G.F_SWIPE_ONLY=false; G.buttons.T.h=buttons
    G.jokers={cards={},config={card_limit=12},T={x=0.28,y=0.65,w=8.31}}
    G.consumeables={cards={},config={card_limit=6},T={x=8.97,y=0.65,w=3.35}}
    for i=1,12 do G.jokers.cards[i]={T={w=G.CARD_W,h=G.CARD_H}} end
    for i=1,6 do G.consumeables.cards[i]={T={w=G.CARD_W,h=G.CARD_H}} end
    local l=portrait_run_layout()
    check(l.scale>0.85, 'crowded inventory keeps hand usable')
    check(l.play_y+l.hand_h<=l.hand_y, 'negative inventory leaves a distinct play area')
    for _, area in ipairs({G.jokers,G.consumeables}) do
        portrait_scale_area_cards(area)
        check(portrait_inventory_metrics(area)==2, 'negative inventory wraps')
        for i=1,#area.cards do
            local x,y=portrait_inventory_slot(area,i,#area.cards)
            check(x-area.card_w/2>=area.T.x-0.001 and x+area.card_w/2<=area.T.x+area.T.w+0.001, 'negative slot stays within horizontal bounds')
            check(y+area.cards[i].T.h/2<=l.table_top, 'negative slot clears played cards')
        end
    end
    love.graphics={getDPIScale=function() return 3 end}
    check(portrait_canvas_settings().dpiscale==3, 'canvas retains native density')
    -- Keep six consumables and spare negative capacity while crossing the
    -- Joker threshold in both directions; neither may force a Joker wrap.
    G.jokers.config.card_limit=20
    for _, count in ipairs({0,5,8,9,12,8,5}) do
        G.jokers.cards={}
        for i=1,count do G.jokers.cards[i]={T={w=G.CARD_W,h=G.CARD_H}} end
        local rows, size=portrait_inventory_metrics(G.jokers)
        local expected=count>PORTRAIT_CONFIG.layout.joker_wrap_after and 2 or 1
        check(rows==expected, 'Joker rows depend only on held count: '..count)
        if expected==1 then
            check(size==PORTRAIT_CONFIG.layout.inventory_scale, 'consumables cannot shrink the normal Joker row')
            check(math.abs(portrait_inventory_height(G.jokers)-G.CARD_H*size)<0.00001, 'no empty second Joker row')
        end
    end
end
print('PASS: '..checks..' portrait layout and card-size checks')
