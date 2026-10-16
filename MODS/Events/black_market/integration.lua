return function(B)
    local music_pitch=1
    local begin=B.registry.begin_run
    function B.registry.begin_run(loading)
        B.active=false; B.busy=false; music_pitch=1
        begin(loading)
    end
    local delete=Game.delete_run
    function Game:delete_run(...)
        B.active=false; B.busy=false; music_pitch=1
        return delete(self,...)
    end
    local load=Card.load
    function Card:load(...)
        local result=load(self,...)
        if self.config.center.bm_contraband then if type(self.ability.consumeable)~='table' then self.ability.consumeable=copy_table(self.config.center.config) end;self.ability.set='Contraband' end
        return result
    end
    local remove=Card.remove
    function Card:remove(...)
        if not self.cb_preview then return remove(self,...) end
        local used=copy_table(G.GAME.used_jokers)
        local result=remove(self,...)
        G.GAME.used_jokers=used
        return result
    end
    local add=Card.add_to_deck
    function Card:add_to_deck(...)
        local result=add(self,...)
        if self.config.center.bm_contraband and PortraitCollection then PortraitCollection.mark('contraband',self.config.center.bm_contraband) end
        return result
    end
    local set_cost=Card.set_cost
    function Card:set_cost(...)
        set_cost(self,...)
        if self.ability and self.ability.evt_bm_price then
            self.cost=math.floor(self.cost*self.ability.evt_bm_price+0.5)
        end
    end
    local save=save_run
    function save_run(...)
        if B.busy then return end
        if B.active then B.current().inventory=B.snapshot() end
        local result=save(...)
        -- Resume in the original shop, with the side shop stored in GAME.
        if B.active and G.culled_table and B.current().normal then
            for _,name in ipairs(B.areas) do
                G.culled_table.cardAreas[name]=copy_table(B.current().normal[name])
            end
        end
        return result
    end
    local buy=G.FUNCS.buy_from_shop
    G.FUNCS.buy_from_shop=function(e)
        local card=e.config.ref_table
        local contraband=card and card.config.center.bm_contraband
        local buy_use=contraband and e.config.id=='buy_and_use'
        if buy_use then
            if not card:can_use_consumeable() or not G.FUNCS.check_for_buy_space(card) then return false end
            -- Buy into a real slot first; cancelling a later choice keeps the purchase.
            e={config={id='buy',ref_table=card}}
        end
        local function after_purchase()
              if buy_use then G.E_MANAGER:add_event(Event{blocking=false,blockable=false,func=function()
                  if B.busy then return false end
                  if card.removed then return true end
                  if card.area~=G.consumeables then return false end
                  if G.TAROT_INTERRUPT or G.CONTROLLER.locks.use then return false end
                  G.FUNCS.use_card({config={ref_table=card}},true)
                  return true
            end}) end
        end
        if not B.active then local result=buy(e);after_purchase();return result end
        if B.busy or not card or not B.afford(card.cost) then return end
        local offered=false
        for _,name in ipairs(B.areas) do if card.area==G[name] then offered=true end end
        if not offered then return end -- A stale button cannot repurchase an owned card.
        if e.config.id~='buy_and_use' and not G.FUNCS.check_for_buy_space(card) then e.disable_button=nil; return false end
        B.busy=true
        local result=buy(e)
        G.E_MANAGER:add_event(Event({trigger='after',delay=0.2,func=function()
            -- Queue behind the native purchase's money/context events.
            G.E_MANAGER:add_event(Event({func=function()
                card.ability.evt_bm_price=nil
                if not card.removed then card:set_cost() end
                B.state().heat=B.state().heat+(contraband and B.config().heat_contraband or B.config().heat_normal)
                if contraband then B.current().contraband_bought=true end
                B.busy=false; B.dealer_react(contraband and 'contraband' or 'purchase'); B.refresh_sign(); B.checkpoint()
                return true
            end}))
            return true
        end}))
        after_purchase()
        return result
    end
    local can_buy=G.FUNCS.can_buy
    G.FUNCS.can_buy=function(e)
        local card=e.config.ref_table
        can_buy(e)
        if B.active and B.busy then e.config.button=nil; e.config.colour=G.C.UI.BACKGROUND_INACTIVE end
    end
    local can_use=G.FUNCS.can_buy_and_use
    G.FUNCS.can_buy_and_use=function(e)
        can_use(e)
        if e.config.ref_table.config.center.bm_contraband and not B.contraband.space(e.config.ref_table,G.consumeables) then
            e.config.button=nil;e.UIBox.states.visible=false
        end
        if B.active and B.busy then e.config.button=nil; e.config.colour=G.C.UI.BACKGROUND_INACTIVE end
    end
    local toggle=G.FUNCS.toggle_shop
    G.FUNCS.toggle_shop=function(e)
        if B.busy then return end
        if B.active then return B.back() end
        if B.enabled() and G.shop then B.state().current=nil end
        return toggle(e)
    end
    local change_size=change_shop_size
    function change_shop_size(...)
        if not B.active then return change_size(...) end
        local area=G.shop_jokers
        G.shop_jokers=nil
        local result=change_size(...)
        G.shop_jokers=area
        return result
    end
    local probability=SMODS.get_probability_vars
    function SMODS.get_probability_vars(obj,n,d,identifier,from_roll,no_mod)
        local numerator,denominator=probability(obj,n,d,identifier,from_roll,no_mod)
        if not no_mod and G.GAME.portrait_events and B.state().dice_ante==G.GAME.round_resets.ante and
            B.config().loaded_dice_identifiers[identifier] then
            -- One native probability result/context, with the exact probability
            -- of two independent attempts (at least one success). No retrigger.
            local p=math.max(0,math.min(1,numerator/denominator))
            numerator=denominator*(1-(1-p)^2)
        end
        return numerator,denominator
    end
    local background=require('portrait_background')
    local uniform=background.for_uniform
    local dimmed={colour_1={},colour_2={},colour_3={}}
    function background.for_uniform(sprite,shader,name,source)
        local colour=uniform(sprite,shader,name,source)
        if B.active and sprite==G.SPLASH_BACK and (shader=='background' or shader=='splash') and dimmed[name] then
            -- Presentation uses current settings, including when resuming older saves.
            -- Preserve the palette, wave contrast and alpha; never mutate shared colours.
            local brightness=B.registry.mod.config.background_brightness
            local out=dimmed[name]
            for i=1,3 do out[i]=colour[i]*brightness end
            out[4]=colour[4]
            return out
        end
        return colour
    end
    function B.music_pitch(dt)
        local config=B.registry.mod.config
        local target=B.active and config.music_pitch or 1
        local blend=1-math.exp(-math.max(0,dt)/config.music_transition_seconds)
        music_pitch=music_pitch+(target-music_pitch)*blend
        if math.abs(music_pitch-target)<0.0001 then music_pitch=target end
        return music_pitch
    end
end
