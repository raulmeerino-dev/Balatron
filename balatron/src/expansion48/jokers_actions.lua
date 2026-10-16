return function(J)
    local X,P=J.X,PortraitGameplay
    local function text(es,en) return X.text(es,en) end
    local function close() J.ui=nil;G.FUNCS.exit_overlay_menu();X.checkpoint() end
    local function label(card)
        if card.playing_card then
            return localize(card.base.value,'ranks')..' '..localize(card.base.suit,'suits_plural')
        end
        return localize{type='name_text',set=card.config.center.set,key=card.config.center.key}
    end
    local function preview(card)
        local area=CardArea(0,0,0.9*G.CARD_W,0.9*G.CARD_H,{card_limit=1,type='title',highlight_limit=0})
        local c=Card(0,0,0.8*G.CARD_W,0.8*G.CARD_H,G.P_CARDS.empty,G.P_CENTERS.c_base,{bypass_discovery_center=true})
        local saved=copy_table(card:save());saved.added_to_deck=false
        c:load(saved);c.added_to_deck=false;c.fake_card=true;c.playing_card=nil
        c.ability.exp48_id=nil;c.ability.queue_negative_removal=nil
        c.facing='front';c.sprite_facing='front';c.states.drag.can=false;area:emplace(c)
        return {n=G.UIT.O,config={object=area}}
    end
    function J.pick(owner,kind,ids,max,selected)
        local a=owner.ability.x48_action
        if not a or a.kind~=kind then a={kind=kind,ids=ids,selected=selected or {},max=max,page=1};owner.ability.x48_action=a end
        J.ui={owner=owner,action=a};J.render_picker();X.checkpoint()
    end
    function J.render_picker()
        local ui=J.ui;if not ui then return end
        local a,owner=ui.action,ui.owner
        local rows={P.text(label(owner),0.43),P.text(text('Seleccionadas: ','Selected: ')..#a.selected..' / '..a.max,0.3)}
        local columns={};local first=((a.page or 1)-1)*3+1
        for i=first,math.min(first+2,#a.ids) do
            local id=a.ids[i];local card=J.find(id)
            if card then
                local chosen
                for index,v in ipairs(a.selected) do if v==id then chosen=index end end
                local b=UIBox_button{label={chosen and tostring(chosen)..' · '..text('Quitar','Remove') or text('Elegir','Choose')},
                    button='exp48_j_pick',minw=1.5,minh=portrait_touch_height(0.8),scale=0.28,colour=chosen and G.C.GREEN or G.C.RED}
                b.nodes[1].config.ref_table=id
                columns[#columns+1]={n=G.UIT.C,config={align='cm',padding=0.04},nodes={preview(card),b}}
            end
        end
        rows[#rows+1]={n=G.UIT.R,config={align='cm'},nodes=columns}
        if #a.ids>3 then
            local pages={};for i=1,math.ceil(#a.ids/3) do pages[i]=tostring(i) end
            rows[#rows+1]=create_option_cycle{w=4,scale=0.7,options=pages,current_option=a.page or 1,opt_callback='exp48_j_page'}
        end
        if a.kind=='spyglass' then rows[#rows+1]=P.text(text('Orden elegido: primero en robarse → último','Chosen order: next draw → last'),0.26) end
        if a.kind=='barterer' then rows[#rows+1]=P.text(text('Elige un Joker propio y uno de la tienda','Choose one owned and one shop Joker'),0.27) end
        rows[#rows+1]=P.button(text('Confirmar','Confirm'),'exp48_j_confirm')
        rows[#rows+1]=P.button(text('Cancelar','Cancel'),'exp48_j_cancel')
        P.open(rows,'exp48_j_cancel')
    end
    G.FUNCS.exp48_j_page=function(args) if J.ui then J.ui.action.page=args.to_key;J.render_picker() end end
    G.FUNCS.exp48_j_pick=function(e)
        local a=J.ui and J.ui.action;if not a then return end
        local id=e.config.ref_table
        for index,value in ipairs(a.selected) do if value==id then table.remove(a.selected,index);J.render_picker();X.checkpoint();return end end
        if #a.selected<a.max then a.selected[#a.selected+1]=id end
        J.render_picker();X.checkpoint()
    end
    G.FUNCS.exp48_j_cancel=function()
        if J.ui then
            local owner,a=J.ui.owner,J.ui.action
            owner.ability.x48_action=nil
            if a.kind=='pin' then J.state().pin_done[X.id(owner)]=true end
        end
        close()
    end
    local function rental(card)
        local a=card.ability
        return a.x48_lease or a.exp48_lease or a.x48_last_performance or a.portrait_rental or a.mutation_rental
    end
    function J.barter_valid(own,shop)
        if not own or not shop or own.area~=G.jokers or shop.area~=G.shop_jokers then return false end
        if own.ability.eternal or rental(own) or rental(shop) then return false end
        local ranks={[1]=1,[2]=2,[3]=3,[4]=4,upg_upgraded=3,risk_risk=3}
        local ra,rb=ranks[own.config.center.rarity],ranks[shop.config.center.rarity]
        if own.config.center.rarity~=shop.config.center.rarity and (not ra or not rb or rb>ra) then return false end
        local incoming=shop.edition and (shop.edition.card_limit or (shop.edition.negative and 1)) or 0
        local outgoing=own.edition and (own.edition.card_limit or (own.edition.negative and 1)) or 0
        local delta=incoming-outgoing
        return #G.jokers.cards<=G.jokers.config.card_limit+delta
    end
    G.FUNCS.exp48_j_confirm=function()
        local ui=J.ui;if not ui or not J.active(ui.owner) then return end
        local owner,a=ui.owner,ui.action;local e=owner.ability.extra
        local selected={};for _,id in ipairs(a.selected) do local c=J.find(id);if not c then return end;selected[#selected+1]=c end
        if a.kind=='spyglass' then
            if #selected~=#a.ids or a.blind~=X.blind() then return end
            local n=#a.ids
            for _,c in ipairs(selected) do
                local valid=false;for index=#G.deck.cards-n+1,#G.deck.cards do if G.deck.cards[index]==c then valid=true end end
                if not valid then return end
            end
            for index,c in ipairs(selected) do G.deck.cards[#G.deck.cards-index+1]=c end
            G.deck:set_ranks();G.deck:align_cards();G.deck:hard_set_cards()
        elseif a.kind=='backstage' then
            if not P.normal_shop() or #selected>math.min(5,#G.playing_cards-math.max(1,G.hand.config.card_limit)) then return end
            e.reserve=copy_table(a.selected)
        elseif a.kind=='castling' then
            if #selected~=2 or e.used_blind==X.blind() then return end
            for _,c in ipairs(selected) do if c.area~=G.hand or SMODS.has_no_rank(c) then return end end
            if X.swap_ranks then
                if X.swap_ranks(selected[1],selected[2])==false then
                    attention_text{text=text('Elige cartas de linajes distintos','Choose cards from different lineages'),scale=0.35,hold=2}
                    return
                end
            else
                local r1,r2=selected[1].base.value,selected[2].base.value
                SMODS.change_base(selected[1],nil,r2);SMODS.change_base(selected[2],nil,r1)
            end
            e.used_blind=X.blind();G.hand:parse_highlighted()
        elseif a.kind=='barterer' then
            if #selected~=2 or e.shop==J.state().shop or not P.normal_shop() then return end
            local own,shop=selected[1],selected[2];if shop.area==G.jokers then own,shop=shop,own end
            if not J.barter_valid(own,shop) then return end
            local price=math.max(own.config.center.cost or 0,2*(own.sell_cost or 0))
            own:remove_from_deck();G.jokers:remove_card(own);G.shop_jokers:remove_card(shop)
            shop:add_to_deck();G.jokers:emplace(shop);G.shop_jokers:emplace(own)
            own.ability.x48_barter_min=price;own:set_cost();own.cost=math.max(own.cost,price)
            if own.children.price then own.children.price:remove();own.children.price=nil end
            if own.children.buy_button then own.children.buy_button:remove();own.children.buy_button=nil end
            if shop.children.price then shop.children.price:remove();shop.children.price=nil end
            if shop.children.buy_button then shop.children.buy_button:remove();shop.children.buy_button=nil end
            create_shop_card_ui(own,'Joker',G.shop_jokers);e.shop=J.state().shop
        elseif a.kind=='pin' then
            if #selected>1 then return end
            if selected[1] then
                local card=selected[1]
                if card.removed or card.shattered or card.destroyed or card.ability.x48_pin or
                    (card.area~=G.discard and card.area~=G.play) or #G.hand.cards>=G.hand.config.card_limit then return end
                card.ability.x48_pin=X.id(owner);J.move(card,G.hand)
            end
            J.state().pin_done[X.id(owner)]=true
        end
        owner.ability.x48_action=nil;close()
    end
    J.actions.j_upg_spyglass=function(card)
        if not J.between_hands() or #G.deck.cards==0 then return end
        local e=card.ability.extra
        local pending=card.ability.x48_action
        if e.used_blind==X.blind() then
            if pending and pending.kind=='spyglass' and pending.blind==X.blind() then J.ui={owner=card,action=pending};J.render_picker() end
            return
        end
        local n=({3,5,7})[e.stage or 1];local ids={}
        for i=#G.deck.cards,math.max(1,#G.deck.cards-n+1),-1 do ids[#ids+1]=X.id(G.deck.cards[i]) end
        J.pick(card,'spyglass',ids,#ids)
        -- Inspection itself spends the action: cancelling cannot repeatedly
        -- reveal later draws for free. Reordering remains optional.
        card.ability.x48_action.blind=X.blind()
        e.used_blind=X.blind();e.seen=e.seen or {};e.seen[e.used_blind]=true;e.progress=X.count(e.seen)
        if (e.stage==1 and e.progress>=3) or (e.stage==2 and e.progress>=7) then UPGJokers.evolution.upgrade(J.spyglass_def,card) end
        X.checkpoint()
    end
    J.actions.j_incj_backstage=function(card)
        if not J.safe() or not P.normal_shop() then return end
        local ids={};for _,c in ipairs(G.playing_cards) do ids[#ids+1]=X.id(c) end
        table.sort(ids)
        J.pick(card,'backstage',ids,math.max(0,math.min(5,#ids-math.max(1,G.hand.config.card_limit))),copy_table(card.ability.extra.reserve or {}))
    end
    J.actions.j_incj_castling=function(card)
        if not J.between_hands() or card.ability.extra.used_blind==X.blind() then return end
        local ids={};for _,c in ipairs(G.hand.cards) do if not SMODS.has_no_rank(c) then ids[#ids+1]=X.id(c) end end
        if #ids>=2 then J.pick(card,'castling',ids,2) end
    end
    J.actions.j_incj_barterer=function(card)
        if not J.safe() or not P.normal_shop() or card.ability.extra.shop==J.state().shop then return end
        local ids={};for _,area in ipairs({G.jokers,G.shop_jokers}) do for _,c in ipairs(area.cards) do
            if c.ability.set=='Joker' then ids[#ids+1]=X.id(c) end
        end end
        J.pick(card,'barterer',ids,2)
    end
    J.actions.j_incj_thumbtack=function(card)
        if not J.between_hands() then return end
        for _,c in ipairs(G.hand.cards) do if c.ability.x48_pin==X.id(card) then
            c.ability.x48_pin=nil;G.hand:remove_from_highlighted(c,true)
        end end
        X.checkpoint()
    end
    J.actions.j_incj_extra_time=function()
        if J.between_hands() and G.GAME.chips>=G.GAME.blind.chips then
            G.STATE=G.STATES.NEW_ROUND;G.STATE_COMPLETE=false;X.checkpoint()
        end
    end
    G.FUNCS.exp48_j_action=function(e)
        local c=e.config.ref_table;if J.active(c) and J.actions[J.key(c)] then J.actions[J.key(c)](c) end
    end
    local controls=G.UIDEF.use_and_sell_buttons
    G.UIDEF.use_and_sell_buttons=function(card,...)
        local node=controls(card,...)
        if J.active(card) and J.actions[J.key(card)] and node and node.nodes then
            local button=UIBox_button{label={J.key(card)=='j_incj_extra_time' and text('Cobrar','Cash out') or
                J.key(card)=='j_incj_thumbtack' and text('Liberar','Release') or text('Acción','Action')},
                button='exp48_j_action',minw=1.3,maxw=1.6,minh=portrait_touch_height(0.8),scale=0.3,colour=G.C.BLUE}
            button.nodes[1].config.ref_table=card
            local rows=node.nodes[1] and node.nodes[1].nodes or node.nodes
            rows[#rows+1]=button
        end
        return node
    end
    local set_cost=Card.set_cost
    function Card:set_cost(...)
        local result=set_cost(self,...)
        if self.ability.x48_barter_min and self.area==G.shop_jokers then self.cost=math.max(self.cost,self.ability.x48_barter_min) end
        return result
    end
    function J.refresh_pins()
        local pinned={};for _,c in ipairs(G.hand and G.hand.cards or {}) do
            if c.ability.x48_pin then
                local owner=X.find(c.ability.x48_pin,G.jokers.cards)
                if owner and J.active(owner) then pinned[#pinned+1]=c else c.ability.x48_pin=nil end
            end
        end
        for _,c in ipairs(pinned) do
            if not c.highlighted then
                while #G.hand.highlighted>=G.hand.config.highlighted_limit do
                    local removed=false;for _,other in ipairs(G.hand.highlighted) do
                        if not other.ability.x48_pin then G.hand:remove_from_highlighted(other,true);removed=true;break end
                    end
                    if not removed then break end
                end
                G.hand:add_to_highlighted(c,true)
            end
        end
    end
    local unhighlight=CardArea.remove_from_highlighted
    function CardArea:remove_from_highlighted(card,force,...)
        if self==G.hand and card.ability.x48_pin and G.STATE==G.STATES.SELECTING_HAND and not force then return end
        return unhighlight(self,card,force,...)
    end
    local discard=G.FUNCS.discard_cards_from_highlighted
    G.FUNCS.discard_cards_from_highlighted=function(e,hook,...)
        if not hook then
            local free={};for _,c in ipairs(G.hand.highlighted) do
                if c.ability.x48_pin then c.highlighted=false else free[#free+1]=c end
            end
            G.hand.highlighted=free
            if #free==0 then J.refresh_pins();return end
        end
        local result=discard(e,hook,...)
        if not hook then J.refresh_pins() end
        return result
    end
    local play=G.FUNCS.play_cards_from_highlighted
    G.FUNCS.play_cards_from_highlighted=function(...)
        J.refresh_pins()
        for _,c in ipairs(G.hand.cards) do if c.ability.x48_pin and not c.highlighted then return end end
        for _,c in ipairs(G.hand.highlighted) do c.ability.x48_pin=nil end
        return play(...)
    end
    local hand_played=Game.update_hand_played
    function Game:update_hand_played(dt)
        local s=J.state()
        if not s or G.STATE_COMPLETE then return hand_played(self,dt) end
        -- Native discard draws are queued events. Let them finish before a
        -- picker can relocate a surviving card out of the discard area.
        if G.play and #G.play.cards>0 then return end
        local token=J.hand_token()
        if s.transition~=token then s.transition=token;s.extra_decision=nil;s.pin_done={} end
        if G.GAME.chips>=G.GAME.blind.chips and G.GAME.current_round.hands_left>0 and X.has('j_incj_extra_time') and not s.extra_decision then
            if not G.OVERLAY_MENU then
                P.open({P.text(text('Objetivo alcanzado','Target reached'),0.45),
                    P.button(text('Seguir jugando','Keep playing'),'exp48_j_extend'),
                    P.button(text('Cobrar','Cash out'),'exp48_j_cashout')},'exp48_j_cashout')
            end
            return
        end
        local ongoing=G.GAME.current_round.hands_left>0 and (G.GAME.chips<G.GAME.blind.chips or s.extra_decision=='continue')
        if ongoing then
            for _,owner in ipairs(J.cards('j_incj_thumbtack')) do
                if not s.pin_done[X.id(owner)] then
                    local ids={};for _,id in ipairs(s.last_scoring or {}) do
                        local c=X.find(id)
                        if c and not c.removed and not c.destroyed and not c.shattered and not c.ability.x48_pin and
                            (c.area==G.discard or c.area==G.play) then ids[#ids+1]=id end
                    end
                    if #ids>0 and #G.hand.cards<G.hand.config.card_limit and X.count(s.pin_done)<G.hand.config.highlighted_limit then
                        if not G.OVERLAY_MENU then J.pick(owner,'pin',ids,1) end
                        return
                    end
                    s.pin_done[X.id(owner)]=true
                end
            end
        end
        if ongoing and s.extra_decision=='continue' then G.STATE=G.STATES.DRAW_TO_HAND;G.STATE_COMPLETE=false;return end
        return hand_played(self,dt)
    end
    G.FUNCS.exp48_j_extend=function() J.state().extra_decision='continue';close() end
    G.FUNCS.exp48_j_cashout=function() J.state().extra_decision='cashout';close() end
end
