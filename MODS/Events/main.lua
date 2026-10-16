local mod=SMODS.current_mod
local function module(path) return assert(SMODS.load_file(path..'.lua'))() end
local R=module('core/registry')(mod)
PortraitEvents=R
R.register('black_market','k_evt_black_market')
local B=module('black_market/state')(R)
R.black_market=B
G.C.SET.Contraband=HEX('65233d')
G.C.SECONDARY_SET.Contraband=G.C.SET.Contraband
local function crisp(self)
    SMODS.Atlas.inject(self)
    self.image:setFilter('nearest','nearest')
end
SMODS.Atlas{key='contraband',path='contraband.png',px=71,py=95,disable_mipmap=true,inject=crisp}
SMODS.Atlas{key='dealer',path='dealer.png',px=80,py=72,disable_mipmap=true,inject=crisp}
module('black_market/stock')(B)
module('black_market/contraband')(B)
for _,id in ipairs({'loaded_dice','counterfeit_voucher','marked_card','inside_information',
    'stolen_negative','forgery','dealers_choice','hot_merchandise','bribe','stolen_tag'}) do
    module('black_market/contraband/'..id)(B,B.contraband)
end
module('black_market/expansion48')(B,B.contraband)
module('black_market/consumable_ui')(B,B.contraband)
module('black_market/shop_preview')(B,B.contraband)
module('black_market/dealer')(B)
module('black_market/ui')(B)
module('black_market/integration')(B)
R.install_menu()

mod.affects_gameplay=true
mod.qol_snapshot=function()
    local config=G.GAME.portrait_events and G.GAME.portrait_events.config
    if config and config.events.black_market then return {name='Black Market'} end
end
