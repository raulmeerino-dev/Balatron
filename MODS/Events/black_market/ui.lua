return function(B)
    local colours={main=HEX('25121f'),dark=HEX('110d17'),accent=HEX('702640')}
    -- Visual settings are independent of the saved gameplay configuration.
    local window={fill=adjust_alpha(HEX('25232E'),0.40),well=adjust_alpha(HEX('192B32'),0.12),
        rim=HEX('A18170'),well_rim=adjust_alpha(HEX('9C8790'),0.5),
        padding=0.18,well_padding=0.22,radius=0.18,goods_width=2.2,goods_height=1.2}
    local function text(label,scale,colour)
        return {n=G.UIT.R,config={align='cm',padding=0.025},nodes={
            {n=G.UIT.T,config={text=label,scale=scale or 0.35,colour=colour or G.C.WHITE,shadow=true}}}}
    end
    local function walk(node,fn)
        fn(node)
        for _,child in ipairs(node.nodes or {}) do walk(child,fn) end
    end
    function B.refresh_sign()
        if not B.active then return end
        local sign=G.SHOP_SIGN
        local config=sign and sign.config or {align='cm',major=G.HUD:get_UIE_by_ID('row_blind'),bond='Weak'}
        if sign then sign:remove() end
        local dealer=Sprite(0,0,0.75,0.675,G.ASSET_ATLAS.evt_dealer,{x=B.dealer.expression,y=0})
        dealer:juice_up(0.08,0.1)
        local state,current=B.state(),B.current()
        local nodes={{n=G.UIT.R,config={align='cm'},nodes={{n=G.UIT.O,config={object=dealer}},
            {n=G.UIT.C,config={align='cm',padding=0.04},nodes={text(localize('k_evt_black_market'),0.32,G.C.GOLD),
                text(localize('k_evt_heat')..' '..state.heat,0.28,G.C.RED)}}}},
            text(B.dealer.phrase and localize('k_evt_phrase_'..B.dealer.phrase) or ' ',0.22,B.dealer.colour)}
        G.SHOP_SIGN=UIBox{definition={n=G.UIT.ROOT,config={align='cm',colour=colours.main,r=0.1,padding=0.08},nodes=nodes},config=config}
        B.anchor_dealer()
    end
    function B.anchor_dealer()
        local header=G.shop and (G.shop:get_UIE_by_ID('portrait_shop_sign') or G.shop:get_UIE_by_ID('evt_bm_header'))
        if header and G.SHOP_SIGN then
            G.SHOP_SIGN:set_alignment{major=header,type='cm',offset={x=0,y=0},bond='Weak'}
            G.SHOP_SIGN.config.major=header; G.SHOP_SIGN.config.offset={x=0,y=0}
        end
    end
    local shop_def=G.UIDEF.shop
    function G.UIDEF.shop()
        local current=B.enabled() and B.shop_created()
        local definition=shop_def()
        if not current then return definition end
        if B.active then
            if G.F_PORTRAIT then
                -- Reserve space in this shop only, above products and thumb buttons.
                local body=definition.nodes[1].nodes[1].nodes[1]
                -- Reuse the reserved shop header; keep the Dealer out of the HUD.
                walk(body,function(node)
                    if node.config and node.config.id=='portrait_shop_sign' then node.config.minw=3.2 end
                end)
            end
            current.reroll_price=B.reroll_cost()
            walk(definition,function(node)
                local c=node.config or {}
                if c.id=='next_round_button' then
                    c.button='evt_bm_back'
                    node.nodes={text(localize('b_evt_back'),0.38)}
                elseif c.button=='reroll_shop' then
                    c.button='evt_bm_reroll'; c.func='evt_bm_can_reroll'
                end
                if c.ref_table==G.GAME.current_round and c.ref_value=='reroll_cost' then
                    c.ref_table=current; c.ref_value='reroll_price'
                end
                if c.colour==G.C.DYN_UI.MAIN or c.colour==G.C.DYN_UI.BOSS_MAIN then c.colour=colours.main end
                if c.colour==G.C.L_BLACK then
                    c.colour=G.F_PORTRAIT and window.well or colours.dark
                    if G.F_PORTRAIT and node.n~=G.UIT.T then
                        c.emboss=nil;c.outline=1;c.outline_colour=window.well_rim
                    end
                end
                if c.text and c.vert then c.text=localize('k_evt_goods') end
            end)
            for i,name in ipairs(B.areas) do
                local area=G[name]
                area.config.card_limit=i==1 and 2 or 1
                if area.config.card_limits then area.config.card_limits.base=area.config.card_limit end
            end
            G.shop_jokers.T.w=2.04*G.CARD_W
            if G.F_PORTRAIT then
                local outer=definition.nodes[1]
                local frame=outer.nodes[1]
                local body=frame.nodes[1]
                -- The native shop nests three opaque backgrounds. Keep only
                -- one translucent surface so the animated table remains visible.
                outer.config.colour=G.C.CLEAR;outer.config.padding=0.06
                frame.config.colour=G.C.CLEAR;frame.config.padding=0.06
                body.config.colour=window.fill;body.config.emboss=nil
                body.config.r=window.radius;body.config.padding=window.padding
                body.config.outline=1;body.config.outline_colour=window.rim
                body.config.id='evt_bm_window'
                for _,area in ipairs({G.shop_vouchers,G.shop_booster}) do
                    area.T.w=window.goods_width*G.CARD_W
                    area.T.h=window.goods_height*G.CARD_H
                    local align=area.align_cards
                    function area:align_cards()
                        align(self)
                        -- These are single-product wells even when the native
                        -- booster area retains its two-slot spacing metadata.
                        local card=#self.cards==1 and self.cards[1]
                        if card and not card.states.drag.is then
                            card.T.x=self.T.x+(self.T.w-card.T.w)/2
                        end
                    end
                end
                G.shop_booster.config.card_w=G.CARD_W;G.shop_booster.card_w=G.CARD_W
                -- Symmetric native CardArea wells; no nested black voucher box
                -- or height clamp cutting into the product's lower margin.
                local goods=body.nodes[#body.nodes]
                goods.config.padding=0.10
                goods.nodes={}
                for _,area in ipairs({G.shop_vouchers,G.shop_booster}) do
                    goods.nodes[#goods.nodes+1]={n=G.UIT.C,config={align='cm',padding=window.well_padding,
                        colour=window.well,r=window.radius,outline=1,outline_colour=window.well_rim},nodes={
                        {n=G.UIT.O,config={object=area}},
                    }}
                end
            end
            B.refresh_sign()
        else
            if not current.available then return definition end
            local inserted=false
            walk(definition,function(node)
                if not inserted and node.n==G.UIT.R and node.nodes and #node.nodes==0 then
                    node.nodes={}
                    if current.available then
                        node.nodes[#node.nodes+1]=UIBox_button{label={localize('k_evt_black_market')},button='evt_bm_enter',
                            col=true,colour=colours.accent,minw=3.0,minh=0.65,scale=0.32}
                    end
                    inserted=true
                end
            end)
        end
        return definition
    end
    local function rebuild()
        if G.shop then G.shop:remove(); G.shop=nil end
        if G.SHOP_SIGN then G.SHOP_SIGN:remove(); G.SHOP_SIGN=nil end
        for _,key in ipairs(B.areas) do G[key]=nil end
        G.shop=UIBox{definition=G.UIDEF.shop(),config={align='tmi',offset={x=0,y=-5.3},major=G.hand,bond='Weak'}}
        if G.F_PORTRAIT then portrait_anchor_run_panel(G.shop) end
        if B.active then B.anchor_dealer() end
        G.STATE_COMPLETE=true
    end
    function B.enter()
        if B.active or B.busy or G.STATE~=G.STATES.SHOP or not B.enabled() or not B.current().available then return end
        B.busy=true
        attention_text{text=localize('k_evt_black_market'),scale=0.7,hold=B.config().transition_seconds,align='cm',major=G.play,backdrop_colour=colours.main}
        play_sound('whoosh1')
        G.E_MANAGER:add_event(Event({trigger='after',delay=B.config().transition_seconds,func=function()
            local current=B.current()
            current.normal=B.snapshot(); current.normal_limit=G.GAME.shop.joker_max
            B.active=true
            current.heat_factor=current.heat_factor or B.heat_factor()
            B.dealer_react('enter')
            rebuild()
            if current.inventory then B.restore(current.inventory)
            else B.fill_stock(); B.contraband.generate() end
            B.busy=false; B.checkpoint(); return true
        end}))
    end
    function B.back()
        if not B.active or B.busy then return end
        B.busy=true
        local state,current=B.state(),B.current()
        current.inventory=B.snapshot()
        if state.heat>=B.config().heat_high and not current.exit_rolled then
            current.exit_rolled=true
            if B.roll('heat_'..current.id)<B.config().heat_lock_chance then state.cooldown=B.config().heat_lock_shops end
        end
        B.active=false; rebuild(); B.restore(current.normal)
        -- Overstock acquired here expands the original shop only when returning.
        local added=G.GAME.shop.joker_max-current.normal_limit
        if added>0 then
            G.shop_jokers.config.card_limit=G.GAME.shop.joker_max
            if G.shop_jokers.config.card_limits then G.shop_jokers.config.card_limits.base=G.GAME.shop.joker_max end
            for i=1,added do G.shop_jokers:emplace(create_card_for_shop(G.shop_jokers)) end
        end
        current.normal=nil
        B.busy=false; play_sound('cardSlide1'); B.checkpoint()
    end
    function B.reroll()
        if not B.active or B.busy or not B.afford(B.reroll_cost()) then return end
        B.busy=true
        local cost=B.reroll_cost()
        if cost==0 and (G.GAME.current_round.free_rerolls or 0)>0 then SMODS.change_free_rerolls(-1) end
        ease_dollars(-cost,true); inc_career_stat('c_shop_dollars_spent',cost); inc_career_stat('c_shop_rerolls',1)
        G.GAME.round_scores.times_rerolled.amt=G.GAME.round_scores.times_rerolled.amt+1
        PortraitQOL.haptic('reroll')
        B.current().rerolls=B.current().rerolls+1
        for _,area in ipairs({G.shop_jokers,G.shop_vouchers}) do
            for i=#area.cards,1,-1 do local card=area:remove_card(area.cards[i]); card:remove() end
        end
        B.fill_stock() -- Slot 4 is never touched.
        SMODS.calculate_context({reroll_shop=true,black_market=true})
        play_sound('coin2'); play_sound('other1')
        G.E_MANAGER:add_event(Event({trigger='after',delay=0.2,func=function()
            B.busy=false; B.checkpoint(); return true
        end}))
    end
    G.FUNCS.evt_bm_enter=B.enter
    G.FUNCS.evt_bm_back=B.back
    G.FUNCS.evt_bm_reroll=B.reroll
    G.FUNCS.evt_bm_can_reroll=function(e)
        B.current().reroll_price=B.reroll_cost()
        local can=not B.busy and B.afford(B.reroll_cost())
        e.config.button=can and 'evt_bm_reroll' or nil
        e.config.colour=can and G.C.GREEN or G.C.UI.BACKGROUND_INACTIVE
    end
end
