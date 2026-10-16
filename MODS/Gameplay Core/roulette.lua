-- Ordinary Booster pool entry; the purchase, exact prizes and paid result are
-- one durable transaction. Animation state never determines or awards a prize.
return function(P)
    local R={key='p_pg_roulette',cards={}}
    P.roulette=R
    function R.tr(es,en) return (G.SETTINGS.language or ''):sub(1,2)=='es' and es or en end
    function R.state() return G.GAME and G.GAME.pg_roulette end
    function R.active() local s=R.state();return s and s.phase~='claimed' end
    local function valid(key,set)
        local c=G.P_CENTERS[key]
        return c and c.set==set and not G.GAME.banned_keys[key] and SMODS.add_to_pool(c,{source='pg_roulette'})
    end
    local function curated(keys,set)
        local out={};for _,key in ipairs(keys) do if valid(key,set) then out[#out+1]=key end end;return out
    end
    function R.pools()
        local rare={}
        -- Native empty pools may fall back to the Common Joker. Do not let
        -- that fallback masquerade as a premium Rare prize.
        for _,key in ipairs(P.pool('Joker','Rare')) do
            local rarity=G.P_CENTERS[key].rarity
            if rarity==3 or rarity=='Rare' then rare[#rare+1]=key end
        end
        local legendary={}
        local pool=get_current_pool('Joker',nil,true,'pg_roulette')
        for _,key in ipairs(pool) do
            if valid(key,'Joker') and (G.P_CENTERS[key].rarity==4 or G.P_CENTERS[key].rarity=='Legendary') then legendary[#legendary+1]=key end
        end
        return rare,legendary,
            curated({'c_death','c_hanged_man','c_emperor','c_hermit','c_devil','c_justice','c_chariot'},'Tarot'),
            curated({'c_cryptid','c_deja_vu','c_trance','c_medium','c_talisman','c_aura','c_immolate','c_ankh'},'Spectral')
    end
    function R.generate()
        local rare,legendary,tarot,spectral=R.pools()
        local fallback=#rare>0 and rare or #spectral>0 and spectral or tarot
        if #fallback==0 then return end
        -- Equal sectors: 4 Rare, 2 Spectral, 1 useful Tarot, 1 premium Joker.
        -- An 8% Legendary replacement of that last sector means 1% per spin
        -- when eligible. Every displayed card has exactly 1/8 of the wheel.
        local last=(#legendary>0 and P.roll('roulette_legendary')<0.08) and legendary or rare
        local pools={rare,rare,rare,rare,spectral,spectral,tarot,last}
        local saved,seen={},{}
        for i,entries in ipairs(pools) do
            if #entries==0 then entries=fallback end
            local fresh={};for _,key in ipairs(entries) do if not seen[key] then fresh[#fresh+1]=key end end
            if #fresh>0 then entries=fresh end
            local key=P.choose(entries,function() return 1 end,'roulette_prize');seen[key]=true
            local c=SMODS.create_card{key=key,set=G.P_CENTERS[key].set,area=G.pack_cards,
                skip_materialize=true,key_append='pg_roulette',no_edition=true}
            if c.ability.set=='Joker' and c.config.center.rarity~=4 and c.config.center.rarity~='Legendary' then
                c:set_edition(i==8 and {polychrome=true} or (i%2==0 and {holo=true} or {foil=true}),true,true)
            end
            saved[i]=copy_table(c:save());c:remove()
        end
        return saved
    end
    local save=save_run
    function save_run(...)
        if not R.active() then return save(...) end
        local st,interrupt,action=G.STATE,G.GAME.PACK_INTERRUPT,G.action
        G.STATE=G.STATES.SHOP;G.GAME.PACK_INTERRUPT=nil;G.action=nil
        save(...)
        G.STATE=st;G.GAME.PACK_INTERRUPT=interrupt;G.action=action
        local snapshot=G.ARGS.save_run
        if snapshot then
            snapshot.ACTION=nil
            snapshot.cardAreas.pg_roulette_area=nil;snapshot.cardAreas.pack_cards=nil
        end
    end
    function R.save() save_run();G.FILE_HANDLER.force=true end
    function R.room()
        local s=R.state();local c=s and s.winner and R.cards[s.winner]
        if not c then return false end
        local area=c.ability.set=='Joker' and G.jokers or G.consumeables
        local buffer=c.ability.set=='Joker' and (G.GAME.joker_buffer or 0) or (G.GAME.consumeable_buffer or 0)
        return (area.config.card_count or #area.cards)+buffer<area.config.card_limit+(c.edition and c.edition.card_limit or 0)
    end
    assert(SMODS.load_file('roulette_ui.lua'))()(R,P)
    function R.open()
        if not R.active() then return end
        R.animation=nil;R.reveal_time=nil
        local s=R.state();R.angle=s.winner and -(s.winner-1)*math.pi/4 or 0
        G.GAME.PACK_INTERRUPT=G.STATES.SHOP
        G.STATE=G.STATES.SMODS_BOOSTER_OPENED;G.STATE_COMPLETE=true
        SMODS.OPENED_BOOSTER={config={center=G.P_CENTERS[R.key]}}
        G.GAME.pack_choices=1
        if G.buttons then G.buttons:remove();G.buttons=nil end
        if G.shop then
            G.shop.alignment.offset.py=G.shop.alignment.offset.py or G.shop.alignment.offset.y
            G.shop.alignment.offset.y=G.ROOM.T.y+29
        end
        R.restore_cards();R.show()
    end
    function R.spin(reroll)
        local s=R.state()
        if not R.active() or R.animation or (reroll and s.phase~='result') or (not reroll and s.phase~='ready') then return false end
        if reroll then
            if G.GAME.dollars-G.GAME.bankrupt_at<10 then return false end
            local prizes=R.generate();if not prizes then return false end
            ease_dollars(-10,true);inc_career_stat('c_shop_dollars_spent',10)
            s.rerolls=s.rerolls+1;s.prizes=prizes;R.restore_cards()
        end
        s.winner=math.min(8,math.floor(P.roll('roulette_winner')*8)+1)
        s.phase='result';R.save() -- Debit, RNG and exact winner committed together.
        local start=R.angle or 0
        local finish=start+(G.SETTINGS.reduced_motion and 0 or math.pi*6)+((-(s.winner-1)*math.pi/4-start)%(math.pi*2))
        R.animation={start=G.TIMERS.REAL,from=start,to=finish,last_tick=0}
        R.reveal_time=nil;R.show();play_sound('whoosh1',0.8,0.35)
        return true
    end
    function R.update(dt)
        local a=R.animation
        if a then
            local t=math.min(1,(G.TIMERS.REAL-a.start)/(G.SETTINGS.reduced_motion and 0.45 or 1.8))
            R.angle=a.from+(a.to-a.from)*(1-(1-t)^3)
            local tick=math.floor(R.angle/(math.pi/4))
            if tick~=a.last_tick then a.last_tick=tick;play_sound('paper1',1.05+0.2*(1-t),0.2) end
            if t>=1 then
                R.angle=-(R.state().winner-1)*math.pi/4
                R.animation=nil;R.reveal_time=G.TIMERS.REAL;R.show()
                R.cards[R.state().winner]:juice_up(0.25,0.15)
                play_sound('timpani',1.1,0.45);play_sound('gold_seal',1.1,0.35)
                if PortraitQOL then PortraitQOL.haptic('buy') end
            end
        end
        if G.pg_roulette_area then G.pg_roulette_area:align_cards() end
    end
    function R.finish(claim,fused)
        local s=R.state()
        if not R.active() or s.phase~='result' or R.animation or (claim and not R.room()) then return false end
        s.phase='claimed';s.accepted=claim or fused or false;s.fused=fused or nil
        local c=R.cards[s.winner]
        if claim then
            G.pg_roulette_area:remove_card(c);c.pg_roulette_preview=nil
            c.T.w=G.CARD_W;c.T.h=G.CARD_H;c.T.r=0;c.portrait_dimensions=nil
            c:add_to_deck();(c.ability.set=='Joker' and G.jokers or G.consumeables):emplace(c)
            c:start_materialize();discover_card(c.config.center)
            play_sound('coin1',1.05,0.5)
        end
        R.clear();R.animation=nil;R.angle=0
        G.STATE=G.STATES.SHOP;G.STATE_COMPLETE=true;G.GAME.PACK_INTERRUPT=nil
        G.GAME.pack_choices=0;SMODS.OPENED_BOOSTER=nil
        if G.shop and G.shop.alignment.offset.py then
            G.shop.alignment.offset.y=G.shop.alignment.offset.py;G.shop.alignment.offset.py=nil
        end
        ease_background_colour_blind(G.STATES.SHOP)
        SMODS.calculate_context{ending_booster=true,booster=G.P_CENTERS[R.key]}
        R.save();P.schedule_offers();return true
    end
    function R.accept() return R.finish(true) end
    G.FUNCS.pg_roulette_spin=function() R.spin(false) end
    G.FUNCS.pg_roulette_reroll=function() R.spin(true) end
    G.FUNCS.pg_roulette_accept=function() R.accept() end
    G.FUNCS.pg_roulette_can_spin=function(e)
        e.config.button=not R.animation and R.state().phase=='ready' and 'pg_roulette_spin' or nil
        e.config.colour=e.config.button and G.C.GOLD or G.C.UI.BACKGROUND_INACTIVE
    end
    G.FUNCS.pg_roulette_can_accept=function(e)
        e.config.button=R.room() and not R.animation and 'pg_roulette_accept' or nil
        e.config.colour=e.config.button and G.C.GREEN or G.C.UI.BACKGROUND_INACTIVE
    end
    G.FUNCS.pg_roulette_can_reroll=function(e)
        e.config.button=G.GAME.dollars-G.GAME.bankrupt_at>=10 and not R.animation and 'pg_roulette_reroll' or nil
        e.config.colour=e.config.button and G.C.RED or G.C.UI.BACKGROUND_INACTIVE
    end
    G.FUNCS.pg_roulette_discard=function()
        if not R.active() or R.animation or R.state().phase~='result' then return end
        P.open({P.text(R.tr('¿Renunciar a este premio?','Give up this prize?'),0.4),
            P.button(R.tr('Conservar premio','Keep prize'),'pg_roulette_keep'),
            P.button(R.tr('Renunciar y salir','Give up and leave'),'pg_roulette_leave')},'pg_roulette_keep')
    end
    G.FUNCS.pg_roulette_keep=function() G.FUNCS.exit_overlay_menu() end
    G.FUNCS.pg_roulette_leave=function() G.FUNCS.exit_overlay_menu();R.finish(false) end
    local use=G.FUNCS.use_card
    G.FUNCS.use_card=function(e,...)
        local c=e and e.config and e.config.ref_table
        if c and c.pg_roulette_preview then return end
        if c and c.config.center.key==R.key then
            if c.area~=G.shop_booster or G.STATE~=G.STATES.SHOP or G.CONTROLLER.locks.use then return end
            return c:open()
        end
        return use(e,...)
    end
    local sell=Card.can_sell_card
    function Card:can_sell_card(...) if self.pg_roulette_preview then return false end;return sell(self,...) end
    local skip=G.FUNCS.skip_booster
    G.FUNCS.skip_booster=function(...) if R.active() then return G.FUNCS.pg_roulette_discard() end;return skip(...) end
    local open=Card.open
    function Card:open(...)
        if self.config.center.key~=R.key then return open(self,...) end
        if self.ability.pg_roulette_opened or R.active() or G.STATE~=G.STATES.SHOP or
            G.GAME.dollars-G.GAME.bankrupt_at<self.cost then return false end
        local prizes=R.generate();if not prizes then return false end
        self.ability.pg_roulette_opened=true
        if self.ability.booster_pos then G.GAME.current_round.used_packs[self.ability.booster_pos]='USED' end
        G.GAME.pg_roulette={phase='ready',prizes=prizes,rerolls=0}
        ease_dollars(-self.cost,true);inc_career_stat('c_shop_dollars_spent',self.cost)
        G.GAME.round_scores.cards_purchased.amt=G.GAME.round_scores.cards_purchased.amt+1
        discover_card(self.config.center)
        if self.area then self.area:remove_card(self) end
        SMODS.calculate_context{open_booster=true,card=self,booster=self.config.center}
        if G.GAME.modifiers.inflation then
            G.GAME.inflation=G.GAME.inflation+1
            for _,c in pairs(G.I.CARD) do if c.set_cost then c:set_cost() end end
        end
        self:remove();R.open();R.save()
        play_sound('whoosh1',1,0.4);if PortraitQOL then PortraitQOL.haptic('buy') end
        return true
    end
    local shop_ready=P.shop_ready
    function P.shop_ready()
        if R.active() then R.open();R.save();return end
        return shop_ready()
    end
    local begin=P.begin_run
    function P.begin_run(...) R.clear();R.animation=nil;R.angle=0;return begin(...) end
    local function crisp(self) SMODS.Atlas.inject(self);self.image:setFilter('nearest','nearest') end
    SMODS.Atlas{key='roulette',path='roulette.png',px=71,py=95,disable_mipmap=true,inject=crisp}
    SMODS.Atlas{key='roulette_wheel',path='roulette_wheel.png',px=160,py=160,disable_mipmap=true,inject=crisp}
    SMODS.Booster{key='roulette',atlas='roulette',pos={x=0,y=0},kind='Roulette',
        cost=20,weight=1,config={extra=8,choose=1},unlocked=true,discovered=false,
        in_pool=function()
            if R.active() then return false end
            local r,l,t,s=R.pools();return #r+#t+#s>0
        end,
        update_pack=function(self,dt) R.update(dt) end}
end
