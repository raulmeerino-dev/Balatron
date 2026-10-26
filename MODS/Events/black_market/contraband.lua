return function(B)
    local C={entries={},order={}}
    B.contraband=C
    SMODS.ConsumableType{key='Contraband',primary_colour=HEX('65233d'),secondary_colour=HEX('a52d45'),
        collection_rows={5,5},shop_rate=0,no_collection=true}
    function C.register(id,cost,def)
        def.id=id;def.key='cb_evt_'..id
        C.entries[id]=def;C.order[#C.order+1]=id
        SMODS.Atlas{key='cb_'..id,path='contraband/'..id..'.png',px=71,py=95,disable_mipmap=true,inject=function(self) SMODS.Atlas.inject(self);self.image:setFilter('nearest','nearest') end}
        -- Preserve the old center keys so saved shop stock remains loadable.
        SMODS.Consumable{key=def.key,prefix_config={key=false},set='Contraband',cost=cost,
            atlas='cb_'..id,pos={x=0,y=0},
            unlocked=not def.mission,discovered=not def.mission,no_collection=true,bm_contraband=id,expansion48=def.mission,
            config={},in_pool=function() return false end,
            can_use=function(_,card) return C.can_use(card) end,
            use=function(_,card) C.apply(card) end,
            set_badges=function(_,card,badges)
                badges[1]=create_badge(localize('k_evt_contraband'),HEX('65233d'),G.C.WHITE,0.9)
            end,
            loc_vars=function(_,q,card) return {vars={2,card and card.cost or cost}} end}
    end
    function C.id(card) return card and card.config.center.bm_contraband end
    function C.owned(card)
        if not card or card.removed or card.getting_sliced then return false end
        for _,area in pairs({G.consumeables,G.shop_jokers,G.shop_vouchers,G.shop_booster,G.pack_cards}) do
            if area and card.area==area then return true end
        end
        return false
    end
    function C.space(card,area)
        local extra=card and card.edition and (card.edition.card_limit or (card.edition.negative and 1)) or 0
        return (area.config.card_count or #area.cards)<area.config.card_limit+extra
    end
    function C.editions(card)
        local options={}
        for _,item in ipairs({{'foil','e_foil'},{'holographic','e_holo'},{'polychrome','e_polychrome'},{'negative','e_negative'}}) do
            local center=G.P_CENTERS[item[2]]
            local weight=B.config().hot_merchandise_editions[item[1]] or 0
            if center and weight>0 and not G.GAME.banned_keys[center.key] and B.registry.mod_enabled(center)
                and card.config.center.black_market_editions~=false
                and SMODS.add_to_pool(center,{card=card,source='black_market'}) then
                options[#options+1]={name=center.key,weight=weight}
            end
        end
        return options
    end
    function C.choice_pool(id)
        local result={}
        if id=='dealers_choice' then
            result=B.pool('Joker','Rare')
            local included={}; for _,key in ipairs(result) do included[key]=true end
            for _,item in ipairs(B.opted_jokers()) do
                local center=G.P_CENTERS[item.key]
                if not included[item.key] and (center.rarity==3 or center.rarity=='Rare') then result[#result+1]=item.key end
            end
        else
            for _,group in ipairs(B.normal_joker_groups()) do
                for _,key in ipairs(group.keys) do result[#result+1]=key end
            end
        end
        if id=='hot_merchandise' then
            local filtered={}
            for _,key in ipairs(result) do
                if #C.editions({config={center=G.P_CENTERS[key]}})>0 then filtered[#filtered+1]=key end
            end
            return filtered
        end
        return result
    end
    function C.choice_key(id,available)
        if id=='dealers_choice' then
            local weights,total={},0
            for _,item in ipairs(B.opted_jokers()) do weights[item.key]=item.weight end
            for _,key in ipairs(available) do total=total+(weights[key] or 1) end
            local draw=B.roll(id)*total
            for _,key in ipairs(available) do
                draw=draw-(weights[key] or 1)
                if draw<0 then return key end
            end
            return
        end
        local groups,total={},0
        local allowed={}; for _,key in ipairs(available) do allowed[key]=true end
        for _,group in ipairs(B.normal_joker_groups()) do
            local keys={}
            for _,key in ipairs(group.keys) do if allowed[key] then keys[#keys+1]=key end end
            if #keys>0 then groups[#groups+1]={keys=keys,weight=group.weight}; total=total+group.weight end
        end
        local draw=B.roll('hot_rarity')*total
        for _,group in ipairs(groups) do
            draw=draw-group.weight
            if draw<0 then return B.choose(group.keys,id) end
        end
    end
    function C.vouchers()
        return B.pool('Voucher')
    end
    function C.boss()
        return G.GAME.round_resets.blind_choices.Boss
    end
    function C.copy_space(source,target)
        local limit=G.consumeables.config.card_limit
        if source.added_to_deck and source.edition then limit=limit-(source.edition.card_limit or (source.edition.negative and 1) or 0) end
        local count=#G.consumeables.cards-(source.area==G.consumeables and 1 or 0)
        local extra=target.edition and (target.edition.card_limit or (target.edition.negative and 1)) or 0
        return count<limit+extra
    end
    function C.targets(id,source)
        if type(C.entries[id].targets)=='function' then return C.entries[id].targets(source) end
        local out={}
        local area=id=='marked_card' and G.playing_cards or id=='stolen_negative' and G.jokers.cards or G.consumeables.cards
        for _,card in ipairs(area or {}) do
            local valid=not card.removed and not card.getting_sliced and card~=source
            if id=='marked_card' then valid=valid and card.config.center.black_market_enhance~=false and #B.pool('Enhanced')>0
            elseif id=='stolen_negative' then valid=valid and not card.edition and not G.GAME.banned_keys.e_negative and card.config.center.black_market_negative~=false
                and SMODS.add_to_pool(G.P_CENTERS.e_negative,{card=card,source='black_market'})
            elseif id=='forgery' then valid=valid and card.ability.consumeable and not C.id(card) and card.ability.set~='Contraband'
                and card.config.center.black_market_copy~=false and C.copy_space(source,card)
            end
            if valid then out[#out+1]=card end
        end
        return out
    end
    function C.can_use(card)
        local id=C.id(card);local def=id and C.entries[id]
        return not not (def and C.owned(card) and not card.ability.cb_applied and
            G.GAME.portrait_events and not B.busy and def.can(card))
    end
    function C.generate()
        local candidates,total={},0
        for _,id in ipairs(C.order) do
            local weight=B.config().contraband_weights[id] or 0
            if weight>0 and (not C.entries[id].mission or require('portrait_expansion48').unlocked(C.entries[id].mission)) then
                candidates[#candidates+1]={id=id,weight=weight};total=total+weight
            end
        end
        local draw=B.roll('contraband')*total
        for _,entry in ipairs(candidates) do
            draw=draw-entry.weight
            if draw<0 then
                local card=B.create(C.entries[entry.id].key,G.shop_booster)
                G.shop_booster:emplace(card);card:start_materialize()
                B.current().contraband_id=entry.id;break
            end
        end
        B.current().contraband_generated=true
    end
    function C.preview(saved,area)
        local key=saved.save_fields.center
        local used=G.GAME.used_jokers[key]
        local card=Card(0,0,G.CARD_W,G.CARD_H,G.P_CARDS.empty,G.P_CENTERS[key],{bypass_discovery_center=true})
        local data=copy_table(saved);data.added_to_deck=false
        card:load(data);card.added_to_deck=false;card.cb_preview=true;card.ability.queue_negative_removal=nil
        G.GAME.used_jokers[key]=used
        if area then area:emplace(card) end
        return card
    end
    function C.save_choice(card)
        local saved=copy_table(card:save());saved.added_to_deck=false
        card:remove();return {saved=saved}
    end
    function C.prepare(card)
        local def=C.entries[C.id(card)]
        if def.targets then
            if def.id=='marked_card' then
                if not card.ability.cb_choices then
                    local choices={}
                    for _,target in ipairs(C.targets(def.id,card)) do
                        choices[#choices+1]={sort_id=target.sort_id,playing_card=target.playing_card,
                            enhancement=SMODS.poll_enhancement{key='evt_cb_marked',guaranteed=true,options=B.pool('Enhanced')},
                            seal=SMODS.poll_seal{key='evt_cb_marked',guaranteed=true}}
                    end
                    card.ability.cb_choices=choices
                    card.ability.cb_choices_ante=G.GAME.round_resets.ante
                    B.checkpoint()
                end
                return card.ability.cb_choices
            end
            local out={}
            for _,target in ipairs(C.targets(def.id,card)) do out[#out+1]={sort_id=target.sort_id,playing_card=target.playing_card} end
            return out
        end
        if def.id=='bribe' and card.ability.cb_choices_ante~=G.GAME.round_resets.ante then card.ability.cb_choices=nil end
        if def.id=='inside_information' and card.ability.cb_choices and not C.shop.valid(card.ability.cb_choices[1]) then card.ability.cb_choices=nil end
        if not card.ability.cb_choices then
            card.ability.cb_choices=def.choices(card)
            card.ability.cb_choices_ante=G.GAME.round_resets.ante
            B.checkpoint()
        end
        return card.ability.cb_choices
    end
    function C.resolve(card,choice)
        if not choice then return end
        local def=C.entries[C.id(card)]
        if def.targets then
            for _,target in ipairs(C.targets(def.id,card)) do
                if target.sort_id==choice.sort_id and target.playing_card==choice.playing_card then return target end
            end
        else
            for _,v in ipairs(card.ability.cb_choices or {}) do
                if v==choice then return def.valid(card,choice) and choice or nil end
            end
        end
    end
    function C.apply(card)
        local def=C.entries[C.id(card)]
        if card.ability.cb_applied then return end
        local choice=card.ability.cb_selected
        local target=def.targets and C.resolve(card,choice) or choice
        assert(not (def.targets or def.choices) or target,'Contraband use requires confirmed choice')
        if def.apply(card,target,choice)==false then return false end
        card.ability.cb_applied=true;
        if PortraitModifierUnlocks then PortraitModifierUnlocks.record('contraband',1,'card:'..tostring(card.sort_id)) end
        if PortraitRunRules then PortraitRunRules.contraband_used() end
        card.ability.cb_selected=nil;card.ability.cb_pending=nil
        card:juice_up();play_sound('tarot1',1,0.6)
        G.E_MANAGER:add_event(Event{trigger='after',delay=0.6,func=function() B.checkpoint();return true end})
    end
    function C.take_joker(source,choice)
        local card=C.preview(choice.saved)
        card.cb_preview=nil;card.ability.evt_bm_price=nil;card:set_cost()
        card:add_to_deck();G.jokers:emplace(card);card:start_materialize()
    end
    function C.joker_choices(id)
        local out,pool={},C.choice_pool(id)
        for i=1,3 do
            local key=C.choice_key(id,pool)
            if not key then break end
            local card=SMODS.create_card{set='Joker',key=key,area=G.jokers,no_edition=id=='hot_merchandise',key_append='evt_cb_'..id,skip_materialize=true}
            if id=='hot_merchandise' then card:set_edition(SMODS.poll_edition{key='evt_cb_hot',guaranteed=true,options=C.editions(card)},true,true) end
            out[#out+1]=C.save_choice(card)
            if not SMODS.showman(key) then for n=#pool,1,-1 do if pool[n]==key then table.remove(pool,n) end end end
        end
        return out
    end
    function C.joker_valid(source,choice)
        return choice.saved and C.space({edition=choice.saved.edition},G.jokers) and B.eligible(G.P_CENTERS[choice.saved.save_fields.center])
    end
end
