return function(J)
    local X=J.X
    function X.can_copy(card) return card and not card.ability.x48_last_performance end
    function J.copy_candidates(cards)
        local out={};for _,card in ipairs(cards or {}) do if X.can_copy(card) then out[#out+1]=card end end;return out
    end
    local can_use=Card.can_use_consumeable
    function Card:can_use_consumeable(...)
        if self.ability.name=='Ankh' and #J.copy_candidates(G.jokers and G.jokers.cards)==0 then return false end
        return can_use(self,...)
    end
    local function restore(card,extension)
        local current=card.ability
        card.ability=copy_table(extension.snapshot)
        for _,key in ipairs({'eternal','rental','perishable','perish_tally','exp48_id','extra_value'}) do card.ability[key]=current[key] end
        card.ability.x48_last_performance=extension
    end
    local function clear_visual(card)
        card.getting_sliced=nil;card.removed=nil;card.destroyed=nil;card.dissolve=nil;card.T.r=0
        if card.states and card.states.drag then card.states.drag.is=false end
        if card.children and card.children.center then card.children.center.pinch.x=false end
    end
    function J.defer(card)
        if J.expiring or not card or card~=J.self_source or card.area~=G.jokers or card.removed or card.ability.eternal then return false end
        local existing=card.ability.x48_last_performance
        if existing then clear_visual(card);return true end
        if not X.has('j_incj_last_performance') or not J.useful or J.useful.card~=card then return false end
        local snapshot=copy_table(J.useful.ability)
        snapshot.x48_action=nil;snapshot.x48_last_performance=nil
        card.ability=copy_table(snapshot)
        card.ability.x48_last_performance={used=true,snapshot=snapshot,born=X.blind(),gros_michel=card.ability.name=='Gros Michel'}
        if card.ability.name=='Gros Michel' then G.GAME.pool_flags.gros_michel_extinct=false end
        clear_visual(card)
        X.track{exp48_self_destroy_deferred=true,card=card}
        return true
    end
    -- Deferred native death animations retain their originating Joker. External
    -- removal (Dagger, Madness, sales) therefore never qualifies as self-removal.
    local add_event=EventManager.add_event
    function EventManager:add_event(event,...)
        local source,useful=J.self_source,J.useful
        if source and event.func then
            local func=event.func
            event.func=function(...)
                local old_source,old_useful=J.self_source,J.useful
                J.self_source=source;J.useful=useful
                local result=func(...)
                J.self_source=old_source;J.useful=old_useful
                return result
            end
        end
        return add_event(self,event,...)
    end
    local calculate=Card.calculate_joker
    function Card:calculate_joker(context,...)
        local extension=self.ability and self.ability.x48_last_performance
        if extension and not context.blueprint then
            -- Freeze only this Joker's ability, not edition/sticker state. Its
            -- normal scoring engine still emits the original useful output.
            if not (context.joker_main or context.individual or context.repetition or context.other_joker or context.edition) then return end
            restore(self,extension)
        end
        local source,useful=J.self_source,J.useful
        if J.owned(self) and not context.blueprint then
            J.self_source=self
            J.useful=X.has('j_incj_last_performance') and {card=self,ability=copy_table(self.ability)} or nil
        end
        local a,b=calculate(self,context,...)
        if extension then restore(self,extension) end
        J.self_source=source;J.useful=useful
        return a,b
    end
    local dissolve=Card.start_dissolve
    function Card:start_dissolve(...) if J.defer(self) then return end;return dissolve(self,...) end
    local remove_card=CardArea.remove_card
    function CardArea:remove_card(card,...)
        if self==G.jokers and J.defer(card) then return card end
        return remove_card(self,card,...)
    end
    local remove=Card.remove
    function Card:remove(...)
        if J.defer(self) then return end
        if self.ability.x48_last_performance and self.ability.x48_last_performance.gros_michel then
            G.GAME.pool_flags.gros_michel_extinct=true
        end
        if self==J.self_source and self.ability and self.ability.set=='Joker' and not self.ability.x48_death_recorded then
            self.ability.x48_death_recorded=true;X.track{exp48_self_destruct=true,card=self}
        end
        return remove(self,...)
    end
    local destroy=SMODS.destroy_cards
    SMODS.destroy_cards=function(cards,...)
        if cards and cards.config then if J.defer(cards) then return end;return destroy(cards,...) end
        local list={};for _,card in ipairs(cards or {}) do if not J.defer(card) then list[#list+1]=card end end
        if #list>0 then return destroy(list,...) end
    end
    local can_sell=Card.can_sell_card or Card.can_sell
    if Card.can_sell_card then
        function Card:can_sell_card(...) if self.ability.x48_last_performance then return false end;return can_sell(self,...) end
    else
        function Card:can_sell(...) if self.ability.x48_last_performance then return false end;return can_sell(self,...) end
    end
    X.listen(function(c)
        if c.setting_blind and not c.blueprint then
            for _,card in ipairs(G.jokers.cards) do
                local e=card.ability.x48_last_performance
                if e and not e.selected then e.selected=X.blind() end
            end
        end
        if c.end_of_round and c.main_eval and not c.blueprint and not c.retrigger_joker then
            local expired={}
            for _,card in ipairs(G.jokers.cards) do
                local e=card.ability.x48_last_performance
                if e and e.selected==X.blind() then expired[#expired+1]=card end
            end
            for _,card in ipairs(expired) do
                G.E_MANAGER:add_event(Event{func=function()
                    J.expiring=true;card:start_dissolve();J.expiring=false;return true
                end})
            end
        end
    end)
end
