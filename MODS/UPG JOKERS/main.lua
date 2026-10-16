local mod=SMODS.current_mod
local R=assert(SMODS.load_file('core/registry.lua'))()(mod)
local E=assert(SMODS.load_file('core/evolution.lua'))()(R)
E.animation=assert(SMODS.load_file('core/evolution_animation.lua'))()(R,E)
UPGJokers={registry=R,evolution=E}
SMODS.Rarity{
    key='upgraded',badge_colour=HEX(PortraitQOL.rarity_colours.UPG),default_weight=0,disable_if_empty=true,
    pools={Joker=true},get_weight=function(_,_,object_type) return R.weight(object_type) end,
}
E.register(assert(SMODS.load_file('jokers/metamorphosis.lua'))())
E.register(assert(SMODS.load_file('jokers/bottomless.lua'))())
mod.config.wayfinder_cost=mod.config.wayfinder_cost or 9
mod.config.orrery_cost=mod.config.orrery_cost or 9
E.register(assert(SMODS.load_file('jokers/wayfinder.lua'))())
E.register(assert(SMODS.load_file('jokers/orrery.lua'))())
require('expansion48.jokers').register_upg(R,E)
assert(SMODS.load_file('core/menu.lua'))()(R)

mod.affects_gameplay=true
mod.qol_snapshot=function()
    local names={}
    for id,def in pairs(R.entries) do
        if R.enabled(id) then names[id]=def.name end
    end
    return PortraitQOL.config_snapshot(G.GAME.upg_jokers_config,names)
end
