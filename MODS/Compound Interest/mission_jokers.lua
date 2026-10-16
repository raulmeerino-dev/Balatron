return function(I)
    local J=require('portrait_joker_missions')
    local function register(def)
        local key=def.key
        J.atlas(key);def.atlas=key;def.pos={x=0,y=0}
        def.rarity=2;def.cost=7;def.blueprint_compat=false
        def.eternal_compat=true;def.perishable_compat=true
        def.in_pool=function(self) return self.unlocked and I.enabled(key) end
        SMODS.Joker(J.decorate(def,key))
    end
    register{key='graft',config={extra={last_blind='',imprint=false}},
        loc_vars=function(_,queue,card)
            local key=card.ability.extra.imprint
            if key and G.P_CENTERS[key] then queue[#queue+1]=G.P_CENTERS[key] end
            return {vars={key and G.P_CENTERS[key] and localize{type='name_text',set='Enhanced',key=key} or localize('k_incj_no_imprint')}}
        end,
        calculate=function(_,card,c)
            if card.debuff or not J.real(c) or card.area~=G.jokers then return end
            local e=card.ability.extra
            if c.setting_blind then e.imprint=false end
            if c.pre_discard and not c.hook and #(c.full_hand or {})==1 and e.last_blind~=J.blind_token() then
                local source=c.full_hand[1]
                if not source.debuff and source.config.center.set=='Enhanced' then
                    e.last_blind=J.blind_token();e.imprint=source.config.center.key
                    return {message=localize('k_incj_imprinted'),colour=G.C.GREEN}
                end
            end
            if c.after and e.imprint then
                for _,target in ipairs(c.scoring_hand or {}) do
                    if target.config.center==G.P_CENTERS.c_base and not target.destroyed and not target.shattered and not target.getting_sliced then
                        local center=G.P_CENTERS[e.imprint]
                        if center then target:set_ability(center,nil,true);e.imprint=false
                            return {message=localize('k_incj_grafted'),colour=G.C.GREEN} end
                    end
                end
            end
        end}
    register{key='intermission',config={extra={last_blind=''}},
        calculate=function(_,card,c)
            if card.debuff or not J.real(c) or card.area~=G.jokers then return end
            if c.using_consumeable and G.GAME.facing_blind then
                local e,token=card.ability.extra,J.blind_token()
                if e.last_blind~=token then
                    e.last_blind=token;ease_hands_played(1,true);ease_discard(1,true)
                    return {message=localize('k_incj_intermission'),colour=G.C.GREEN}
                end
            end
        end}
end
