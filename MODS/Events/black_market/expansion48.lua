return function(B,C)
    local X=require('portrait_expansion48')
    local function safe() return G.STATE==G.STATES.SELECTING_HAND or G.STATE==G.STATES.SHOP or G.STATE==G.STATES.BLIND_SELECT end
    local function register(id,cost,def)
        local d=X.catalog[id];def.mission=id
        C.register(d.key,cost,def)
        B.registry.mod.config.contraband_weights[d.key]=B.registry.mod.config.contraband_weights[d.key] or 1
    end
    local function jokers(test)
        local out={};for _,c in ipairs(G.jokers and G.jokers.cards or {}) do
            if not c.removed and not c.getting_sliced and test(c) then out[#out+1]=c end
        end;return out
    end
    local function recipe(c)
        local F=PortraitFusion
        if not F or not F.enabled() then return end
        for _,id in ipairs(F.order) do if c.config.center.key=='j_fuse_'..id then return F.entries[id] end end
    end
    local function disassembly(c)
        local d=recipe(c)
        if not d or SMODS.is_eternal(c,{fusion=true}) or c.ability.x48_last_performance or c.ability.exp48_lease then return end
        for _,key in ipairs(d.components) do if not X.eligible(key) then return end end
        -- Exactly one output receives the original Edition, so its capacity bonus
        -- cancels the removed Fusion's bonus rather than generating an extra slot.
        if #G.jokers.cards+1+(G.GAME.joker_buffer or 0)>G.jokers.config.card_limit then return end
        return d
    end
    register('B01',14,{
        can=function() return safe() and #jokers(disassembly)>0 end,
        choices=function()
            local choices={}
            for _,c in ipairs(jokers(disassembly)) do
                local d=disassembly(c)
                for edition_to=1,c.edition and 2 or 1 do
                    choices[#choices+1]={id=X.id(c),key=d.components[edition_to],components=copy_table(d.components),edition_to=edition_to,
                        edition=c.edition and copy_table(c.edition),label=X.text('Edition para: ','Edition to: ')..localize{type='name_text',set='Joker',key=d.components[edition_to]}}
                end
            end
            return choices
        end,
        valid=function(_,choice) local c=X.find(choice.id,G.jokers.cards);return c and disassembly(c) end,
        apply=function(_,choice)
            local c=X.find(choice.id,G.jokers.cards);local d=c and disassembly(c);if not d then return false end
            local outputs={}
            for i,key in ipairs(d.components) do
                local n=SMODS.create_card{key=key,set='Joker',area=G.jokers,no_edition=true,skip_materialize=true,key_append='exp48_disassembly'}
                n:set_edition(i==choice.edition_to and c.edition or nil,true,true)
                n:set_eternal(false);n:set_rental(c.ability.rental or false)
                n.ability.perishable=nil;n.ability.perish_tally=nil
                if c.ability.perishable then n:set_perishable(true);n.ability.perish_tally=c.ability.perish_tally end
                outputs[#outputs+1]=n
            end
            c:remove_from_deck();G.jokers:remove_card(c);c:remove()
            for _,n in ipairs(outputs) do n:add_to_deck();G.jokers:emplace(n);n:start_materialize() end
            if G.jokers.handle_card_limit then G.jokers:handle_card_limit() end
        end,
    })
    local function stained(c) return c.ability.eternal or c.ability.rental or c.ability.perishable end
    register('B02',12,{targets=function() return jokers(stained) end,
        can=function() return safe() and #jokers(stained)>0 end,
        apply=function(_,c)
            if not stained(c) then return false end
            c:set_eternal(false);c:set_rental(false);c.ability.perishable=nil;c.ability.perish_tally=nil
            -- Recompute all native debuff sources. A Boss/Contract source survives.
            if SMODS.recalc_debuff then SMODS.recalc_debuff(c) else G.GAME.blind:debuff_card(c) end
            c:set_cost()
        end})
    local function recoverable()
        local out={}
        for _,entry in ipairs(X.state().graveyard) do
            if not X.find(entry.id) then out[#out+1]=entry end
        end
        return out
    end
    register('B03',14,{
        can=function() return safe() and #recoverable()>0 end,
        choices=function() return copy_table(recoverable()) end,
        valid=function(_,choice)
            if X.find(choice.id) then return false end
            for _,v in ipairs(X.state().graveyard) do if v.id==choice.id then return true end end
        end,
        apply=function(_,choice)
            if X.find(choice.id) then return false end
            local s=X.state();local index
            for i,v in ipairs(s.graveyard) do if v.id==choice.id then index=i;break end end
            if not index then return false end
            local card=C.preview(choice.saved);card.cb_preview=nil;card.removed=nil;card.destroyed=nil;card.shattered=nil
            card.getting_sliced=nil;card.ability.exp48_id=choice.id;card.ability.ct_destroyed_id=nil;card.ability.upg_destruction_token=nil
            card.ability.forced_selection=nil;card.ability.wheel_flipped=nil;card.ability.played_this_ante=nil
            G.playing_card=(G.playing_card or 0)+1;card.playing_card=G.playing_card
            table.remove(s.graveyard,index)
            card:add_to_deck();G.playing_cards[#G.playing_cards+1]=card;G.deck.config.card_limit=G.deck.config.card_limit+1
            G.deck:emplace(card)
            -- Balatro draws from the end of this array; index 1 is the bottom.
            for i=#G.deck.cards,1,-1 do if G.deck.cards[i]==card then table.remove(G.deck.cards,i);break end end
            table.insert(G.deck.cards,1,card);card:start_materialize()
            if G.GAME.facing_blind then G.GAME.blind:debuff_card(card) end
            playing_card_joker_effects({card})
        end,
    })
    local function evolving(c)
        local id=c.config.center.upg_id;local U=UPGJokers
        local d=U and id and U.registry.entries[id]
        return d and d.stages[(c.ability.extra.stage or 1)+1] and not c.ability.x48_last_performance
    end
    register('B04',16,{targets=function() return jokers(evolving) end,
        can=function() return safe() and #jokers(evolving)>0 end,
        apply=function(_,c)
            if not evolving(c) then return false end
            UPGJokers.evolution.upgrade(UPGJokers.registry.entries[c.config.center.upg_id],c)
        end})
    register('B05',10,{
        can=function() return G.GAME.facing_blind and G.STATE==G.STATES.SELECTING_HAND and #G.discard.cards>0 end,
        choices=function() return {{draw=#G.deck.cards,discard=#G.discard.cards,label=X.text('Mazo / descarte: ','Draw / discard: ')..#G.deck.cards..' / '..#G.discard.cards}} end,
        valid=function(_,c) return G.STATE==G.STATES.SELECTING_HAND and c.draw==#G.deck.cards and c.discard==#G.discard.cards and c.discard>0 end,
        apply=function(_,choice)
            if choice.draw~=#G.deck.cards or choice.discard~=#G.discard.cards then return false end
            local draw,discard={},{}
            for i,c in ipairs(G.deck.cards) do draw[i]=c end
            for i,c in ipairs(G.discard.cards) do discard[i]=c end
            for _,c in ipairs(draw) do G.deck:remove_card(c) end
            for _,c in ipairs(discard) do G.discard:remove_card(c) end
            for _,c in ipairs(discard) do G.deck:emplace(c);if c.facing=='front' then c:flip() end end
            for _,c in ipairs(draw) do G.discard:emplace(c) end
        end,
    })
    register('B06',12,{
        can=function()
            if not safe() then return false end
            for _,h in pairs(G.GAME.hands) do if h.played>0 then return true end end
            return false
        end,
        choices=function()
            local out={};for _,key in ipairs(G.handlist) do local h=G.GAME.hands[key]
                if h and h.played>0 then out[#out+1]={hand=key,played=h.played,label=localize(key,'poker_hands')..' · '..h.played..' → 0'} end
            end;return out
        end,
        valid=function(_,c) return G.GAME.hands[c.hand] and G.GAME.hands[c.hand].played>0 end,
        apply=function(_,c)
            local s=X.state();s.alibi=s.alibi or {}
            -- Reapplication replaces the baseline; it never subtracts twice.
            s.alibi[c.hand]={ante=G.GAME.round_resets.ante,played=G.GAME.hands[c.hand].played,
                round=G.GAME.round,played_this_round=G.GAME.hands[c.hand].played_this_round}
        end,
    })
end
