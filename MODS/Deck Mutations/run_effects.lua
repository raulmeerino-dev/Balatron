return function(P,M,level,rules)
    local R={};PortraitRunRules=R
    function R.has(id) return M.state() and level(id)>0 end
    function R.factor(id,amount) return R.has(id) and amount or 1 end
    function R.planet_level_amount(card,amount,source)
        -- Transform the actual delta once at the native level-up boundary. No
        -- consumable replay, mutable card bonus, RNG, or multiplier stored in saves.
        if source=='mutation' or not R.has('double_planets') or amount<=0 then return amount end
        local ability=card and card.ability
        local consumable=ability and (ability.consumeable or
            SMODS.ConsumableTypes and SMODS.ConsumableTypes[ability.set])
        return consumable and not card.debuff and amount*2 or amount
    end
    function R.price_factor()
        return R.factor('discounts',0.8)*R.factor('inflation',1.25)*R.factor('less_shop',0.8)
    end
    function R.blind_values(blind)
        if not blind or not blind.key then return blind end
        local t={};for k,v in pairs(blind) do t[k]=v end
        if blind.boss then t.mult=(t.mult or 1)*R.factor('weak_boss',0.8)*R.factor('strong_boss',1.5) end
        t.mult=(t.mult or 1)*R.factor('high_stakes',1.25)
        t.dollars=math.floor((t.dollars or 0)*R.factor('inflation',1.5)+0.5)+
            (R.has('no_interest') and 3 or 0)+(blind.boss and R.has('strong_boss') and 5 or 0)+(R.has('high_stakes') and 2 or 0)+(not blind.boss and R.has('extra_reward') and 1 or 0)
        if not blind.boss and R.has('field_reserves') then t.dollars=math.max(0,t.dollars-1) end
        return t
    end
    function R.apply(d)
        if d.id=='consumable_exchange' then G.consumeables:change_size(2);G.jokers:change_size(-1) end
        if d.hand_size then G.hand:change_size(d.hand_size) end
        if d.discards then G.GAME.round_resets.discards=math.max(0,G.GAME.round_resets.discards+d.discards) end
        if d.shop then change_shop_size(d.shop) end
        if d.reroll then G.GAME.round_resets.reroll_cost=math.max(0,G.GAME.round_resets.reroll_cost+d.reroll);calculate_reroll_cost(true) end
        if d.rate then G.GAME[d.rate]=math.max(d.rate=='spectral_rate' and 1 or 0,(G.GAME[d.rate] or 0)*2) end
        if d.no_interest then G.GAME.modifiers.no_interest=true end
        if d.pack_options then G.GAME.modifiers.booster_size_mod=(G.GAME.modifiers.booster_size_mod or 0)+d.pack_options end
        if d.id=='rare_market' then G.GAME.rare_mod=(G.GAME.rare_mod or 1)*2 end
        if d.id=='fewer_commons' then G.GAME.common_mod=(G.GAME.common_mod or 1)*0.2 end
        if d.id=='frequent_packs' then G.GAME.modifiers.extra_boosters=(G.GAME.modifiers.extra_boosters or 0)+1 end
        if d.id=='second_pick' then G.GAME.modifiers.booster_choice_mod=(G.GAME.modifiers.booster_choice_mod or 0)+1 end
        if d.id=='free_reroll' then SMODS.change_free_rerolls(1) end
        if d.id=='chaos' then R.ante() end
        for _,area in pairs({G.jokers,G.consumeables,G.shop_jokers,G.shop_booster,G.shop_vouchers}) do
            for _,card in ipairs(area.cards or {}) do card:set_cost() end
        end
    end
    function R.ante()
        local s=M.state();if not s then return end
        local ante=G.GAME.round_resets.ante
        if R.has('ante_money') and s.money_ante~=ante then s.money_ante=ante;ease_dollars(10,true) end
        if R.has('chaos') and s.chaos_ante~=ante then
            local function change(which,delta)
                if which=='hand_size' then G.hand:change_size(delta)
                elseif which then G.GAME.round_resets[which]=G.GAME.round_resets[which]+delta end
            end
            change(s.chaos_bonus,-1)
            s.chaos_bonus=({'hands','discards','hand_size'})[math.floor(P.roll('chaos')*3)+1]
            s.chaos_ante=ante;change(s.chaos_bonus,1)
            if M.feedback then card_eval_status_text(G.deck,'extra',nil,nil,nil,M.feedback({'chaos'},'+1',G.C.GREEN)) end
        end
    end
    -- Change returned scoring numbers only. Never mutate Joker abilities,
    -- probabilities, counters, object creation, or a copied Joker's state.
    local flat={chips=true,chip_mod=true,mult=true,mult_mod=true,h_mult=true}
    local times={x_mult=true,Xmult_mod=true,x_mult_mod=true,x_chips=true,Xchip_mod=true}
    function R.scale_effect(effect,marker)
        if type(effect)~='table' or effect[marker] then return effect end
        local result={};for k,v in pairs(effect) do result[k]=v end
        for key,value in pairs(result) do if type(value)=='number' and value>0 then
            if flat[key] then result[key]=value*1.1
            elseif times[key] and value>1 then result[key]=1+(value-1)*1.1 end
        end end
        result[marker]=true
        return result
    end
    local joker=Card.calculate_joker
    function Card:calculate_joker(context,...)
        local effect,post=joker(self,context,...)
        if self.ability.set=='Joker' and R.has('empowered_jokers') then effect=R.scale_effect(effect,'dm_joker_scaled') end
        return effect,post
    end
    local edition=Card.calculate_edition
    function Card:calculate_edition(...)
        local effect=edition(self,...)
        if R.has('strong_editions') and self.edition and (self.edition.foil or self.edition.holo or self.edition.polychrome) then
            effect=R.scale_effect(effect,'dm_edition_scaled')
        end
        return effect
    end
    local enhancement=Card.calculate_enhancement
    function Card:calculate_enhancement(...)
        local effect=enhancement(self,...)
        if R.has('strong_enhancements') then effect=R.scale_effect(effect,'dm_enhanced_scaled') end
        return effect
    end
    -- Vanilla enhancements expose their numeric bonuses through getters, while
    -- modded enhancements can return them from calculate_enhancement above.
    local bonus=Card.get_chip_bonus
    function Card:get_chip_bonus(...)
        local value=bonus(self,...)
        if R.has('strong_enhancements') and not self.debuff and self.ability.set=='Enhanced' then
            value=value+math.max(0,self.ability.bonus or 0)*0.1
        end
        return value
    end
    for method,field in pairs({get_chip_mult='mult',get_chip_h_mult='h_mult',get_chip_x_mult='x_mult',get_chip_h_x_mult='h_x_mult'}) do
        local original=Card[method];local key=field;local times=key:find('x_mult')~=nil
        Card[method]=function(self,...)
            local value=original(self,...)
            if not R.has('strong_enhancements') or self.debuff or self.ability.set~='Enhanced' then return value end
            local amount=self.ability[key] or 0
            if times and amount>1 then return value*(1+(amount-1)*1.1)/amount end
            local permanent=not self.ability.extra_enhancement and (self.ability['perma_'..key] or 0) or 0
            if not times and value>permanent and amount>0 then return value+amount*0.1 end
            return value
        end
    end
    local cost=Card.set_cost
    function Card:set_cost(...)
        cost(self,...)
        if not M.state() or not self.ability then return end
        local reduction=(self.ability.set=='Joker' and R.has('cheap_jokers') or self.ability.consumeable and R.has('cheap_consumables')) and 1 or 0
        self.cost=math.max(self.cost==0 and 0 or 1,math.floor((self.cost-reduction-(self.ability.set=='Booster' and R.has('cheap_packs') and 1 or 0))*R.price_factor()+0.5))
        if R.has('easy_sale') and not self.ability.eternal then self.sell_cost=self.sell_cost*2 end
        if R.has('profitable_sale') and not self.ability.eternal then self.sell_cost=self.sell_cost+1 end
        self.sell_cost_label=self.facing=='back' and '?' or self.sell_cost
    end
    local set_blind=Blind.set_blind
    function Blind:set_blind(blind,reset,...)
        return set_blind(self,not reset and R.blind_values(blind) or blind,reset,...)
    end
    -- Duplicate eligible entries rather than constructing a separate pool.
    -- New Doubles and future recipe components inherit the rule automatically.
    local pool=get_current_pool
    function get_current_pool(set,...)
        local values,key=pool(set,...)
        if set~='Joker' or not M.state() then return values,key end
        local out={};local components={}
        if R.has('frequent_fusion') and PortraitFusion and PortraitFusion.enabled() then
            for id,d in pairs(PortraitFusion.entries) do if PortraitFusion.config().recipes[id] then
                for _,component in ipairs(d.components) do components[component]=true end
            end end
        end
        for _,id in ipairs(values) do
            out[#out+1]=id
            local c=G.P_CENTERS[id]
            if c then
                local n=(R.has('frequent_doubles') and c.portrait_family=='doubles' and 2 or 1)*(components[id] and 2 or 1)
                for i=2,n do out[#out+1]=id end
            end
        end
        return out,key
    end
    local rarity=SMODS.poll_rarity
    function SMODS.poll_rarity(set,...)
        local changed={}
        if set=='Joker' and R.has('frequent_risk') then
            for _,c in ipairs(G.P_CENTER_POOLS.Joker) do if c.risk_id then
                local key=tostring(c.rarity):lower()..'_mod'
                if not changed[key] then changed[key]={G.GAME[key]};G.GAME[key]=(G.GAME[key] or 1)*2 end
            end end
        end
        local result=rarity(set,...)
        for key,value in pairs(changed) do G.GAME[key]=value[1] end
        return result
    end
    local poll=poll_edition
    function poll_edition(...)
        local changed={}
        for _,key in ipairs({'e_foil','e_holo','e_polychrome','e_negative'}) do
            local center=G.P_CENTERS[key]
            if center then
                local factor=key=='e_negative' and R.factor('frequent_negative',1.5) or R.factor('shiny_market',2)
                if factor~=1 then local old=center.get_weight;changed[center]=old
                    center.get_weight=function(self,...) return (old and old(self,...) or self.weight)*factor end
                end
            end
        end
        local result=poll(...)
        for center,old in pairs(changed) do center.get_weight=old end
        return result
    end
    function R.calculate(context)
        if not M.state() then return end
        if P.won(context) and R.has('quick_blind') and (G.GAME.current_round.hands_played or 0)==1 and P.once(M.state(),'quick_paid',P.token()) then ease_dollars(2,true) end
        if context.ante_change and context.ante_change>0 then
            G.E_MANAGER:add_event(Event{func=function() R.ante();return true end})
        end
        if context.initial_scoring_step and P.real(context) then
            return {chips=R.has('boosted_chips') and 30 or nil,mult=(R.has('boosted_mult') and 3 or 0)+(R.has('first_hand') and (G.GAME.current_round.hands_played or 0)==0 and 20 or 0)}
        end
    end
    function R.favorable(obj,id)
        local adverse={glass=true,glass_break=true,gros_michel=true,cavendish=true,wheel=true}
        local name=obj and obj.ability and obj.ability.name
        return not adverse[id] and name~='Glass Card' and name~='Gros Michel' and name~='Cavendish'
            and not (obj and obj.boss) and not tostring(id):find('destroy')
    end
    local probability=SMODS.get_probability_vars
    function SMODS.get_probability_vars(obj,n,d,id,from_roll,no_mod)
        local a,b=probability(obj,n,d,id,from_roll,no_mod)
        if not no_mod and R.has('fortune') and R.favorable(obj,id) then
            a=math.min(b,a*1.2)
        end
        return a,b
    end
    function R.interest()
        local base=G.GAME.interest_amount*math.min(math.floor(G.GAME.dollars/5),G.GAME.interest_cap/5)
        return math.min(base*R.factor('double_interest',2),G.GAME.interest_amount*G.GAME.interest_cap/5)
    end
    local loc=M.mod.process_loc_text
    M.mod.process_loc_text=function()
        if loc then loc() end
        local es=(G.SETTINGS.language or ''):sub(1,2)=='es'
        for _,d in ipairs(rules) do
            local name=es and d.es or d.en
            G.localization.misc.dictionary['k_dm_'..d.id]=name
            local text=es and d.text_es or d.text_en
            G.localization.descriptions.Other['dm_'..d.id]={name=name,text=type(text)=='table' and text or {text}}
        end
    end
    assert(SMODS.load_file('expansion_effects.lua'))()(P,M,R)
    return R
end
