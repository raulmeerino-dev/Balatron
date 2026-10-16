-- Event adapters contain no thresholds: all requirements live in progression.lua.
return function(U,P)
    function U.deck()
        if not U.run() then return end
        local enhanced,seals=0,0
        for _,card in ipairs(G.playing_cards or {}) do if not card.removed then
            if card.config.center~=G.P_CENTERS.c_base then enhanced=enhanced+1 end
            if card.seal then seals=seals+1 end
        end end
        U.record('enhanced',enhanced,nil,true);U.record('seals',seals,nil,true)
        U.record('wealth',math.max(0,G.GAME.dollars or 0),nil,true)
    end
    for _,method in ipairs({'set_ability','set_seal'}) do
        local original=Card[method]
        Card[method]=function(self,...)
            local result=original(self,...)
            if self.playing_card and G.playing_cards then
                for _,card in ipairs(G.playing_cards) do if card==self then U.deck();break end end
            end
            return result
        end
    end
    local context=U.context
    function U.context(c)
        context(c)
        if not P.real(c) or not U.run() then return end
        if c.using_consumeable and c.consumeable then
            U.record('consumables',1)
            local key=({Planet='planets',Spectral='spectral',Tarot='tarots'})[c.consumeable.ability.set]
            if key then U.record(key,1) end
        end
        if c.pre_discard and not c.hook then
            local count=0;for _,card in ipairs(c.full_hand or {}) do if card.seal then count=count+1 end end
            if count>0 then U.record('seal_discards',count) end
        end
        if c.remove_playing_cards then for _,card in ipairs(c.removed or {}) do
            -- playing_card is renumbered when any card leaves the deck; sort_id survives saves.
            if card.playing_card then U.record('destroyed',1,'card:'..tostring(card.sort_id)) end
        end end
        if P.won(c) then U.record('spare_discards',math.max(0,G.GAME.current_round.discards_left or 0),P.token()) end
        if c.setting_blind or c.using_consumeable or c.playing_card_added or c.remove_playing_cards then U.deck() end
        if c.money_altered then U.record('wealth',math.max(0,G.GAME.dollars or 0),nil,true) end
    end
end
