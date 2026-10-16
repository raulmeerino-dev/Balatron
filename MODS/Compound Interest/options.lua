return function(I)
    local L=assert(SMODS.load_file('options_logic.lua'))()
    local O={logic=L,key='j_incj_options',hold_time=0.35}
    I.options=O
    local function is_options(card)
        return card and card.config and card.config.center and card.config.center.key==O.key
    end
    local function is_double(card)
        return card and card.config and card.config.center and card.config.center.portrait_family=='doubles'
    end
    local function owned(card) return is_double(card) and G.jokers and card.area==G.jokers end
    function O.sync(card)
        if not is_double(card) or not (card.ability and type(card.ability.extra)=='table') or not card.children.center then return end
        -- Collection, shops, packs and detached previews always use the neutral frame.
        local active=G.STAGE==G.STAGES.RUN and owned(card)
        local pos=active and (card.ability.extra.selected=='B' and 1 or 0) or 2
        local sprite=card.children.center
        if sprite.atlas==G.ASSET_ATLAS[card.config.center.atlas] and sprite.sprite_pos.x~=pos then
            sprite:set_sprite_pos{x=pos,y=0}
        end
    end
    function O.prepare(card)
        if not is_options(card) or not owned(card) or not G.GAME.facing_blind then return false end
        -- Native hands_played advances AFTER scoring, when play is discarded.
        -- The same key therefore covers selection, before and joker_main.
        local played=G.GAME.current_round.hands_played or 0
        local key=tostring(G.GAME.round)..':'..tostring(math.max(0,played))
        return L.prepare(card.ability.extra,key,function() return pseudorandom('incj_options') end,L.interest_base(G.GAME))
    end
    function O.can_switch(card)
        return owned(card) and card.facing=='front' and not G.SETTINGS.paused and not G.OVERLAY_MENU
            and not G.CONTROLLER.locked and not G.CONTROLLER.locks.frame
            and not (G.GAME.STOP_USE and G.GAME.STOP_USE>0)
            and (G.STATE==G.STATES.SELECTING_HAND or G.STATE==G.STATES.SHOP or G.STATE==G.STATES.BLIND_SELECT)
            and not (G.play and #G.play.cards>0)
    end
    function O.toggle(card)
        if not O.can_switch(card) then return false end
        local e=card.ability.extra
        e.selected=e.selected=='B' and 'A' or 'B'
        O.sync(card)
        play_sound('button',1.1,0.35)
        if not G.SETTINGS.reduced_motion then card:juice_up(0.22,0.08) end
        card:stop_hover()
        save_run()
        return true
    end
    function O.describe(effect)
        if not effect then return localize('k_incj_options_pending') end
        local es=(G.SETTINGS.language or ''):sub(1,2)=='es'
        local function number(value)
            local text=string.format('%.2f',value):gsub('0+$',''):gsub('%.$','')
            return es and text:gsub('%.',',') or text
        end
        local n=number(effect.value)
        if effect.kind=='chips' then return '+'..n..' '..localize('k_incj_options_chips') end
        if effect.kind=='mult' then return '+'..n..' Mult' end
        if effect.kind=='xmult' then return 'X'..n..' Mult' end
        if effect.kind=='dollars' then return '+$'..n end
        if effect.kind=='interest' then return localize('k_incj_options_interest')..' X'..n..': +$'..number(effect.dollars) end
        return '+'..effect.chips..' '..localize('k_incj_options_chips')..' / +'..n..' Mult'
    end
    SMODS.Atlas{key='options',path='options.png',px=71,py=95,disable_mipmap=true,
        inject=function(self)
            SMODS.Atlas.inject(self)
            self.image:setFilter('nearest','nearest')
        end,
    }
    SMODS.Joker{
        key='options',portrait_family='doubles',atlas='options',pos={x=2,y=0},rarity=3,cost=8,
        no_main_mod_badge=true,
        unlocked=true,discovered=false,blueprint_compat=true,eternal_compat=true,perishable_compat=true,
        config={extra={selected='A',hand_key=''}},
        in_pool=function() return I.enabled('options') end,
        loc_vars=function(self,queue,card)
            local e=card.ability.extra
            queue[#queue+1]={key='incj_double_controls',set='Other'}
            return {key='j_incj_options_tooltip',vars={O.describe(e.a),O.describe(e.b),e.selected or 'A'},
                main_end=require('portrait_tooltips').modes(card,{
                    {title=localize('k_incj_mode_a'),colour=G.C.RED,text={O.describe(e.a)}},
                    {title=localize('k_incj_mode_b'),colour=G.C.BLUE,text={O.describe(e.b)}},
                })}
        end,
        calculate=function(self,card,context)
            if context.hand_drawn and not context.blueprint and not context.retrigger_joker then O.prepare(card) end
            if context.before and not context.blueprint and not context.retrigger_joker then O.prepare(card) end
            if context.joker_main and not card.debuff then
                -- Copies/retriggers read the original's stored choice. They never
                -- roll, switch, or create a second A/B state on the copying Joker.
                if not context.blueprint and not context.retrigger_joker then O.prepare(card) end
                return L.effect(L.active(card.ability.extra))
            end
        end,
    }
    -- Sprite state follows native Card.ability serialization/copying; editions,
    -- stickers and the shared center definition remain untouched.
    local load=Card.load
    function Card:load(...) local result=load(self,...);O.sync(self);return result end
    local sprites=Card.set_sprites
    function Card:set_sprites(...) local result=sprites(self,...);O.sync(self);return result end

    -- Resolve ownership changes immediately, including buying, selling and load.
    local set_area,remove_area=Card.set_card_area,Card.remove_from_area
    function Card:set_card_area(...)
        local result=set_area(self,...);O.sync(self);return result
    end
    function Card:remove_from_area(...)
        local result=remove_area(self,...);O.sync(self);return result
    end

    local function track(controller,x,y)
        local card=controller.cursor_down and controller.cursor_down.target
        local g=card and card._options_gesture
        if not g then return end
        x=x or controller.cursor_position.x;y=y or controller.cursor_position.y
        if (x-g.x)^2+(y-g.y)^2>=(PORTRAIT_CONFIG.touch_drag_threshold or 9)^2 then g.moved=true end
        return g
    end
    local press=Controller.L_cursor_press
    function Controller:L_cursor_press(...)
        local result=press(self,...)
        local card=self.cursor_down.target
        if self.is_cursor_down and owned(card) then
            local unit=G.TILESCALE*G.TILESIZE
            card._options_gesture={time=love.timer.getTime(),x=self.cursor_down.T.x*unit,y=self.cursor_down.T.y*unit}
        end
        return result
    end
    local release=Controller.L_cursor_release
    function Controller:L_cursor_release(x,y,...)
        local g=track(self,x,y)
        if g then g.elapsed=love.timer.getTime()-g.time end
        return release(self,x,y,...)
    end
    local controller_update=Controller.update
    function Controller:update(dt,...)
        if self.is_cursor_down then track(self) end
        return controller_update(self,dt,...)
    end
    local mousemoved=love.mousemoved
    function love.mousemoved(x,y,...)
        if G.CONTROLLER and G.CONTROLLER.is_cursor_down then track(G.CONTROLLER,x,y) end
        return mousemoved(x,y,...)
    end
    local click,hover=Card.click,Card.hover
    function Card:click(...)
        if not owned(self) then return click(self,...) end
        local g=self._options_gesture;self._options_gesture=nil
        if g and (g.moved or g.held or (g.elapsed or love.timer.getTime()-g.time)>=O.hold_time) then return end
        return O.toggle(self)
    end
    function Card:hover(...)
        if owned(self) and G.CONTROLLER.HID.touch then
            local g=self._options_gesture
            if not g or g.moved or not g.held then return end
        end
        return hover(self,...)
    end
    local update=Card.update
    function Card:update(dt,...)
        local result=update(self,dt,...)
        if not is_double(self) then return result end
        if G.STATE==G.STATES.SELECTING_HAND and not G.SETTINGS.paused and O.prepare(self) then save_run() end
        O.sync(self)
        local g=self._options_gesture
        if g and not g.held and not g.moved and owned(self) and G.CONTROLLER.is_cursor_down
            and G.CONTROLLER.cursor_down.target==self and love.timer.getTime()-g.time>=O.hold_time then
            g.held=true
            -- Keep the native Sell button available via selection on hold.
            if not self.highlighted and O.can_switch(self) then click(self) end
            hover(self)
        end
        return result
    end
end
