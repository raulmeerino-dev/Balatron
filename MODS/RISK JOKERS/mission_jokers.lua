return function(R)
    local J=require('portrait_joker_missions')
    local function register(def)
        R.register{key=def.key,name=def.name,art_available=true}
        local key=def.key
        J.atlas(key)
        def.risk_id=key;def.atlas=key;def.pos={x=0,y=0}
        def.rarity='risk_risk';def.cost=10;def.blueprint_compat=true
        def.eternal_compat=true;def.perishable_compat=true
        def.in_pool=function(self) return self.unlocked and R.enabled(key) end
        SMODS.Joker(J.decorate(def,key))
    end
    register{key='scorched_earth',name='Scorched Earth',config={extra={xmult=5}},
        loc_vars=function(_,q,card) return {vars={card.ability.extra.xmult}} end,
        calculate=function(_,card,c)
            if card.debuff then return end
            if c.joker_main then return {x_mult=card.ability.extra.xmult} end
            if c.destroying_card and c.cardarea==G.play and J.real(c) and card.area==G.jokers then
                if not SMODS.is_eternal(c.destroying_card,{destroy_cards=true}) then return {remove=true} end
            end
        end}
    register{key='powder_keg',name='Powder Keg',config={extra={xmult=6,last_hand=''}},
        loc_vars=function(_,q,card) return {vars={card.ability.extra.xmult}} end,
        calculate=function(_,card,c)
            if card.debuff then return end
            if c.before and J.real(c) and card.area==G.jokers and G.GAME.facing_blind then
                local e,token=card.ability.extra,J.hand_token()
                if e.last_hand~=token then
                    e.last_hand=token
                    -- Commit the real target and receipt together, before scoring.
                    -- Copies/retriggers may copy X Mult, never double the penalty.
                    local blind=G.GAME.blind
                    blind.chips=blind.chips*2;blind.chip_text=number_format(blind.chips)
                    blind:juice_up()
                    return {message=localize('k_risk_target_doubled'),colour=G.C.RED}
                end
            end
            if c.joker_main then return {x_mult=card.ability.extra.xmult} end
        end}
end
