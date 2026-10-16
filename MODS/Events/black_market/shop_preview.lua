return function(B,C)
    local S={};C.shop=S
    local function state() return B.state() end
    function S.can_preview()
        return not state().reservation and not G.SETTINGS.tutorial_progress and
            (G.STATE==G.STATES.SHOP or G.STATE==G.STATES.BLIND_SELECT or G.STATE==G.STATES.SELECTING_HAND)
    end
    local stock=Game.populate_shop_stock
    function S.preview()
        local s=state()
        if s.next_stock then return s.next_stock.choices end
        -- Generate once through the exact native/SMODS stocking function. A
        -- temporary shop receives the cards; existing inventory is never moved.
        local saved={game=G.GAME,shop=G.shop,manager=G.E_MANAGER,locks=G.CONTROLLER.locks}
        local game={};for k,v in pairs(G.GAME) do game[k]=v end
        game.current_round=copy_table(game.current_round)
        game.round_resets=copy_table(game.round_resets)
        game.used_jokers=copy_table(game.used_jokers)
        game.current_round.used_packs={};game.shop_free=nil
        -- Forecasted generation must not award profile progress or alter run receipts.
        game.portrait_modifier_progress=copy_table(game.portrait_modifier_progress or {})
        game.portrait_stock_preview=true
        game.tags={}
        for _,tag in ipairs(saved.game.tags) do
            local clone={};for k,v in pairs(tag) do
                if type(v)~='table' then clone[k]=v end
            end
            clone.config=copy_table(tag.config);clone.ability=copy_table(tag.ability)
            setmetatable(clone,getmetatable(tag));game.tags[#game.tags+1]=clone
        end
        local events={}
        local noop=function() end
        local ui,materialize,sound,yep,nope,checkpoint=create_shop_card_ui,Card.start_materialize,play_sound,Tag.yep,Tag.nope,save_run
        G.GAME=game;G.shop=G.shop or {};G.CONTROLLER.locks=copy_table(saved.locks)
        G.E_MANAGER={add_event=function(_,event) events[#events+1]=event end}
        create_shop_card_ui=noop;Card.start_materialize=noop;play_sound=noop;save_run=noop
        Tag.yep=function(_,message,colour,func) if func then func() end end
        Tag.nope=noop
        local result={areas={},choices={},tags={}}
        for _,name in ipairs(B.areas) do
            saved[name]=G[name];saved['load_'..name]=G['load_'..name];G['load_'..name]=nil
            G[name]=CardArea(0,0,5,3,{type='shop',card_limit=name=='shop_jokers' and game.shop.joker_max or 10})
        end
        local ok,err=xpcall(function()
            stock(G)
            local index=1
            while events[index] do
                assert(index<1000,'Shop preview event overflow')
                local event=events[index];index=index+1
                if event.func then assert(event.func()~=false,'Unsupported pending shop event') end
            end
            for _,name in ipairs(B.areas) do
                result.areas[name]=copy_table(G[name]:save())
                for i,card in ipairs(result.areas[name].cards) do
                    result.choices[#result.choices+1]={saved=card,area=name,index=i,token=(s.preview_serial or 0)+1}
                end
            end
            for _,tag in ipairs(game.tags) do if tag.triggered then result.tags[tag.ID]=true end end
            result.voucher=copy_table(game.current_round.voucher)
            result.used_packs=copy_table(game.current_round.used_packs)
            result.shop_free=game.shop_free
        end,debug.traceback)
        for _,name in ipairs(B.areas) do
            G[name]:remove();G[name]=saved[name];G['load_'..name]=saved['load_'..name]
        end
        G.GAME=saved.game;G.shop=saved.shop;G.E_MANAGER=saved.manager;G.CONTROLLER.locks=saved.locks
        create_shop_card_ui=ui;Card.start_materialize=materialize;play_sound=sound;Tag.yep=yep;Tag.nope=nope;save_run=checkpoint
        assert(ok,err)
        s.preview_serial=(s.preview_serial or 0)+1
        result.token=s.preview_serial;s.next_stock=result
        return result.choices
    end
    function S.valid(choice)
        local next_stock=state().next_stock
        local center=choice.saved and G.P_CENTERS[choice.saved.save_fields.center]
        return next_stock and choice.token==next_stock.token and not state().reservation and center and
            not G.GAME.banned_keys[center.key] and B.registry.mod_enabled(center) and
            (center.set~='Voucher' or not G.GAME.used_vouchers[center.key])
    end
    function S.reserve(choice)
        assert(S.valid(choice),'Invalid shop reservation')
        state().reservation={area=choice.area,index=choice.index,token=choice.token}
    end
    function Game:populate_shop_stock()
        local s=G.GAME.portrait_events and state()
        local forecast=s and s.next_stock
        -- A resumed current shop already has native load_shop_* data. It must
        -- not consume the next shop's forecast, even after cancelling a choice.
        if forecast and not G.load_shop_jokers and not B.active then
            for _,name in ipairs(B.areas) do G['load_'..name]=copy_table(forecast.areas[name]) end
            G.GAME.current_round.voucher=copy_table(forecast.voucher)
            G.GAME.current_round.used_packs=copy_table(forecast.used_packs)
            G.GAME.shop_free=forecast.shop_free
            for i=#G.GAME.tags,1,-1 do local tag=G.GAME.tags[i]
                if forecast.tags[tag.ID] then tag.triggered=true;tag:remove() end
            end
            s.next_stock=nil;s.reservation=nil
            stock(self)
            -- Native load suppresses saving; this stock is newly delivered.
            G.E_MANAGER:add_event(Event{func=function() save_run();return true end})
            return false
        end
        return stock(self)
    end
end
