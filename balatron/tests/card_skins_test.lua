dofile('src/card_skins.lua')
local checks = 0
local function check(value, message)
    assert(value, message); checks = checks + 1
end
G = {SETTINGS = {CUSTOM_DECK = {Collabs = {Hearts = 'collab_TW'}}}, ASSET_ATLAS = {},
     STAGE = 1, STAGES = {RUN = 1},
     I = {CARD = {}}, GAME = {selected_back = {pos = {x=3,y=2}}},
     P_CENTERS = {b_red = {pos={x=0,y=0}}}, save_settings = function() G.saved = true end}
for _, kind in ipairs({'fronts','enhanced','back'}) do
    G.ASSET_ATLAS['skin_deck1_'..kind] = {name='skin_deck1_'..kind, px=71, py=95}
end
G.ASSET_ATLAS.centers = {name='centers'}
check(CardSkins.active() == 'default', 'legacy settings must retain Default')
CardSkins.select(2)
check(G.saved and CardSkins.active() == 'deck1', 'selection saves existing settings')
check(G.SETTINGS.CUSTOM_DECK.Collabs.Hearts == 'collab_TW', 'original collaborations preserved')
for y, suit in ipairs({'Hearts','Clubs','Diamonds','Spades'}) do
    for x=0,12 do
        local front = {suit=suit, pos={x=x,y=y-1}}
        local atlas, pos = CardSkins.front(front, {config={center={set='Default'}}})
        check(atlas.name=='skin_deck1_fronts' and pos==front.pos, 'all 52 ranks use the original UV mapping')
        check(CardSkins.front(front, {config={center={set='Enhanced'}}}).name=='skin_deck1_enhanced', 'enhancements retain their substrate')
    end
end
check(CardSkins.front({}) == nil, 'Jokers/consumables are excluded')
local back = {atlas=G.ASSET_ATLAS.centers,set_sprite_pos=function(self,p) self.pos=p end}
local card = {config={card={suit='Hearts'}}, children={back=back},params={},playing_card=1,back='selected_back'}
CardSkins.refresh_back(card)
check(back.atlas.name=='skin_deck1_back' and back.pos.x==0, 'playing-card back applied')
CardSkins.select(1); CardSkins.refresh_back(card)
check(back.atlas.name=='centers' and back.pos==G.GAME.selected_back.pos, 'Default restores mutable mechanical back position')
check(CardSkins.front({suit='Hearts',pos={x=0,y=0}})==nil, 'Default delegates to native face selection')
G.SETTINGS.CUSTOM_DECK.skin = 'unknown'
check(CardSkins.active()=='default', 'unavailable skin safely falls back')
print('PASS: '..checks..' card skin checks')
