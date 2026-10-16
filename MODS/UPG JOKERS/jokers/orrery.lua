local J=require('portrait_joker_missions')
local def={key='orrery',atlas='orrery',name='Orrery',mission='orrery',cost_key='orrery_cost',blueprint_compat=false,
    initial_state={stage=1,progress=0},
    stages={
        {loc_key='j_upg_orrery_1',sprite={x=0,y=0}},
        {loc_key='j_upg_orrery_2',sprite={x=1,y=0}},
        {loc_key='j_upg_orrery_3',sprite={x=2,y=0},final=true},
    },
    loc_vars=function(s) return {s.stage or 1,s.progress or 0,5,12} end,
}
function def.calculate(card,c,R,E)
    if not (c.using_consumeable and c.consumeable and c.consumeable.ability.set=='Planet') or
        not J.real(c) or card.area~=G.jokers then return end
    local s=card.ability.extra
    local ability=c.consumeable.ability
    local primary=ability.consumeable and ability.consumeable.hand_type or ability.hand_type
    local hands={}
    for index,key in ipairs(G.handlist) do
        local hand=G.GAME.hands[key]
        if hand and hand.visible and key~=primary then hands[#hands+1]={key=key,level=hand.level,index=index} end
    end
    table.sort(hands,function(a,b) return a.level==b.level and a.index<b.index or a.level<b.level end)
    -- Snapshot the distinct recipients once, then use the native level helper.
    -- The source is this Joker, never a replay of the consumed Planet.
    for i=1,math.min(s.stage,#hands) do level_up_hand(card,hands[i].key,true,1) end
    s.progress=s.progress+1
    if (s.stage==1 and s.progress>=5) or (s.stage==2 and s.progress>=12) then return E.upgrade(def,card) end
    return {message=localize('k_upg_orbits'),colour=G.C.PURPLE}
end
return def
