-- Evidence is collected from native events. Legacy saves start with no invented history.
return function(X)
    local function state()
        local s=X.state();if not s then return end
        local r=s.metrics
        r.tarot=r.tarot or {};r.aces=r.aces or {};r.skip67=r.skip67 or {};r.winners=r.winners or {}
        r.contracts=r.contracts or {};r.reward_types=r.reward_types or {}
        if type(r.boss_buys)~='table' then r.boss_buys={} end
        if type(r.boss_sales)~='table' then r.boss_sales={} end
        local ante=G.GAME.round_resets.ante
        if r.ante~=ante then
            r.ante=ante;r.a={packs=0,jokers=0,spend=0,wins=0,skips=0,playing_money=0,mega={},self_destruct=0}
        end
        r.b=r.b or {hands={},played={},initial={},touched={},activations={},sources={},consumables=0,money=0,playing_money=0}
        return r,r.b,r.a
    end
    local function rankset(cards)
        local ranks={};for _,c in ipairs(cards or {}) do if not SMODS.has_no_rank(c) then ranks[tostring(c.base.id)]=true end end;return ranks
    end
    local function intersection(a,b) for k in pairs(a or {}) do if b and b[k] then return true end end;return false end
    local function enhanced(cards,key)
        local n=0;for _,c in ipairs(cards or {}) do if SMODS.has_enhancement(c,key) then n=n+1 end end;return n
    end
    local function common_only()
        for _,c in ipairs(G.jokers.cards) do if c.config.center.rarity~=1 and c.config.center.rarity~='Common' then return false end end
        return true
    end
    local function won(r,b,a)
        if G.GAME.chips<G.GAME.blind.chips then return end
        if not X.once('mission_win:'..X.blind()) then return end
        local ante=G.GAME.round_resets.ante;local boss=G.GAME.blind.boss
        local high=boss and ante>=6;local last=b.last or {}
        a.wins=a.wins+1;r.win_serial=(r.win_serial or 0)+1
        r.only_common=r.only_common~=false and common_only()
        r.winners[#r.winners+1]=last.name
        if #r.winners>4 then table.remove(r.winners,1) end
        local names={};for _,name in ipairs(r.winners) do names[name]=true end
        if ante>=6 and #r.winners==4 and X.count(names)==4 then X.unlock('M05') end
        if b.money>=25 then X.unlock('M16') end
        if X.count(b.played)>=30 and G.GAME.current_round.discards_left==0 then X.unlock('C06') end
        if r.last_winning_ranks and last.count==5 and r.last_winning_count==5 and not intersection(r.last_winning_ranks,last.ranks) then X.unlock('C03') end
        r.last_winning_ranks=last.ranks;r.last_winning_count=last.count
        r.rent_candidate={};for _,c in ipairs(G.jokers.cards) do
            if c.ability.exp48_bought_win==(r.win_serial-1) then r.rent_candidate[X.id(c)]=true end
        end
        r.rent_sold=false
        if not boss then return end
        if a.packs>=4 and a.jokers==0 and a.wins==3 and a.skips==0 then X.unlock('M03') end
        if X.count(a.mega)>=2 and a.jokers==0 then X.unlock('M09') end
        if a.shop_tags then X.unlock('M18') end
        if ante==6 and a.wins==3 and a.skips==0 and a.spend==0 then X.unlock('C02') end
        for key,n in pairs(r.rare_sales or {}) do r.rare_sales[key]=n+1;if n+1>=2 then X.unlock('C01') end end
        if last.name=='Straight Flush' then r.straight_flush=(r.straight_flush or 0)+1 else r.straight_flush=0 end
        if r.straight_flush>=2 then X.unlock('J01') end
        local kings={};for id,rank in pairs(last.ids or {}) do if rank==13 then kings[id]=(r.kings and r.kings[id] or 0)+1 end end
        r.kings=kings;for _,n in pairs(kings) do if n>=3 then X.unlock('J05') end end
        if ante==5 and not b.ever_joker then r.no_joker5=true end
        if ante==6 and not b.ever_joker and r.no_joker5 then X.unlock('C08') end
        if ante==8 and X.count(r.skip67)==4 then X.unlock('M06') end
        local upg={};local fusions={};local expired=0
        for _,c in ipairs(G.jokers.cards) do
            local center=c.config.center
            if center.upg_id and UPGJokers then
                local d=UPGJokers.registry.entries[center.upg_id]
                if d and (c.ability.extra.stage or 1)==#d.stages then upg[center.upg_id]=true end
            end
            if center.rarity=='fuse_fusion' then fusions[center.key]=true end
            if c.ability.perishable and (c.ability.perish_tally or 0)<=0 then expired=expired+1 end
        end
        if X.count(upg)>=2 then X.unlock('B04') end
        if a.egg then X.unlock('C10') end
        if (b.lucky_activations or 0)>=8 and (b.lucky_money or 0)>=40 then X.unlock('J12') end
        if ante>=7 and ante<=8 and r.obelisk and not r.obelisk.failed and X.has('j_obelisk') then
            r.obelisk.wins=r.obelisk.wins or {};r.obelisk.wins[tostring(ante)]=true
            if r.obelisk.wins['7'] and r.obelisk.wins['8'] then X.unlock('B06') end
        end
        local renewed=r.prior_boss and X.count(r.boss_buys)>=3 and X.count(r.boss_sales)>=3 and
            (r.boss_spent or 0)-(r.boss_earned or 0)<=6
        r.prior_boss=true;r.boss_buys={};r.boss_sales={};r.boss_spent=0;r.boss_earned=0
        if not high then return end
        local enhancements,lineages={},{}
        for _,c in ipairs(G.playing_cards) do
            for _,key in ipairs({'m_bonus','m_mult','m_wild','m_glass','m_steel','m_stone','m_gold','m_lucky'}) do
                if SMODS.has_enhancement(c,key) then enhancements[key]=true end
            end
            if c.config.center.set=='Enhanced' and c.seal then
                local keys={};for key in pairs(SMODS.get_enhancements(c)) do keys[#keys+1]=key end;table.sort(keys)
                local key=tostring(c.base.id)..':'..c.base.suit..':'..table.concat(keys,',')..':'..c.seal
                lineages[key]=(lineages[key] or 0)+1
                if lineages[key]>=5 then X.unlock('M08') end
            end
        end
        if X.count(enhancements)==8 then X.unlock('M01') end
        if X.count(r.tarot)>=12 then X.unlock('M02') end
        if b.score_dollars and b.score_dollars<=-10 and b.score_dollars>=G.GAME.bankrupt_at then X.unlock('M04') end
        local levels=0;local ten=false
        for _,h in pairs(G.GAME.hands) do if h.level>=12 then levels=levels+1 end;if h.level>=10 then ten=true end end
        if levels>=2 then X.unlock('M07') end
        if enhanced(G.hand.cards,'m_steel')>=5 then X.unlock('M10') end
        if r.failed_contract and (r.contract_streak or 0)>=2 then X.unlock('M13') end
        if (r.contract_streak or 0)>=3 and G.GAME.dollars>=40 then X.unlock('M14') end
        if #b.hands==4 and b.hands[1]==b.hands[3] and b.hands[2]==b.hands[4] and b.hands[1]~=b.hands[2] then X.unlock('M17') end
        if b.consumables>=4 and not b.prior_shop_consume then X.unlock('M20') end
        if a.playing_money>=30 then X.unlock('C04') end
        if last.level==1 and ten then X.unlock('C05') end
        local held_gold=0
        for _,c in ipairs(G.hand.cards) do if (b.initial_gold or {})[X.id(c)] and not b.touched[X.id(c)] and SMODS.has_enhancement(c,'m_gold') then held_gold=held_gold+1 end end
        if held_gold>=4 then X.unlock('C09') end
        if X.count(fusions)>=2 then X.unlock('B01') end
        if expired>=2 then X.unlock('B02') end
        if a.special_destroy then X.unlock('B03') end
        if b.exhausted then X.unlock('B05') end
        if b.small_then_large then X.unlock('J03') end
        if last.name=='High Card' and last.full_count==5 and enhanced(G.hand.cards,'m_steel')>=3 then X.unlock('J04') end
        if G.GAME.current_round.hands_left==0 and G.GAME.chips/G.GAME.blind.chips>=10 then X.unlock('J06') end
        if renewed then X.unlock('J07') end
        if last.name=='Three of a Kind' then
            local n=0;for id,rank in pairs(last.ids or {}) do if rank==2 and r.aces[id] then n=n+1 end end
            if n>=3 then X.unlock('J08') end
        end
        for id,n in pairs(b.activations or {}) do
            if n>=6 then X.unlock('J09') end
            if n>=5 and X.count(b.sources[id])>=3 then X.unlock('C07') end
        end
        if a.self_destruct>=2 then X.unlock('J10') end
        if X.count(r.contracts)>=3 and X.count(r.reward_types)>=3 then X.unlock('J11') end
        if (b.lucky_activations or 0)>=8 and (b.lucky_money or 0)>=40 then X.unlock('J12') end
    end
    X.listen(function(c)
        local r,b,a=state();if not r then return end
        if c.exp48_money then
            if c.card and (c.native_playing or c.card.ability.set=='Joker') then b.money=b.money+c.amount end
            if c.native_playing and not c.converted then
                b.playing_money=b.playing_money+c.amount;a.playing_money=a.playing_money+c.amount
            end
            return
        end
        if c.pseudorandom_result and c.exp48_lucky_dollars and not X.mutation('M16') then
            b.lucky_money=(b.lucky_money or 0)+c.exp48_lucky_dollars;return
        end
        if c.exp48_score_card then
            local id=X.id(c.card);b.activations[id]=(b.activations[id] or 0)+1
            return
        end
        if c.exp48_lucky_activation then b.lucky_activations=(b.lucky_activations or 0)+1;return end
        if c.exp48_repetitions then b.sources[X.id(c.card)]=c.sources;return end
        if c.exp48_redirected_repetitions then
            local id=X.id(c.card);b.sources[id]=b.sources[id] or {}
            for source in pairs(c.sources or {}) do b.sources[id][source]=true end
            return
        end
        if c.exp48_blind_paid then won(r,b,a);return end
        if c.exp48_selling then
            local card=c.card;local key=card.config.center.key
            if card.ability.set=='Joker' then
                if (card.config.center.rarity==3 or card.config.center.rarity=='Rare') and card.edition then
                    r.rare_sales=r.rare_sales or {};r.rare_sales[key]=r.rare_sales[key] or 0
                end
                if key=='j_egg' and c.price>=30 then a.egg=true end
                if r.rent_candidate and r.rent_candidate[X.id(card)] then r.rent_sold=true end
                r.boss_sales=r.boss_sales or {};r.boss_sales[X.id(card)]=true;r.boss_earned=(r.boss_earned or 0)+c.price
            end;return
        end
        if c.exp48_tarot_resolved then
            for _,card in ipairs(G.playing_cards) do
                local id=X.id(card);local old=c.before[id]
                if old and (old.rank~=card.base.id or old.suit~=card.base.suit or old.center~=card.config.center.key or old.seal~=card.seal or old.edition~=(card.edition and card.edition.key)) then r.tarot[id]=true end
                if old and old.rank==14 and card.base.id==2 and c.key=='c_strength' then r.aces[id]=true end
            end;return
        end
        if c.exp48_contract_result then
            if c.success then
                r.contract_streak=(r.contract_streak or 0)+1;r.contracts[c.contract.id]=true
                local t=c.original_template or c.contract.original_template or {};r.reward_types[t.reward_type or t.kind or t.type or c.contract.id]=true
            else r.failed_contract=true;r.contract_streak=0;r.contracts={};r.reward_types={} end;return
        end
        if c.exp48_self_destruct then a.self_destruct=a.self_destruct+1;return end
        if c.discard and c.other_card and c.other_card.playing_card then b.touched[X.id(c.other_card)]=true end
        if not PortraitGameplay.real(c) then return end
        if c.ante_change and c.ante_change>0 then
            local entering=G.GAME.round_resets.ante+c.ante_change
            if entering==4 and not r.ante4 then r.ante4=X.set(G.jokers.cards) end
            if entering==7 and not r.obelisk then
                local name,max=nil,9;for key,h in pairs(G.GAME.hands) do if h.played>max then name=key;max=h.played end end
                if name then r.obelisk={name=name} end
            end
        elseif c.setting_blind then
            r.b={hands={},played={},initial={},touched={},activations={},sources={},consumables=0,money=0,playing_money=0,
                prior_shop_consume=r.shop_consume,ever_joker=#G.jokers.cards>0}
        elseif c.exp48_initial_hand then
            b.initial=X.set(G.hand.cards);b.touched=b.touched or {};b.initial_gold={}
            for _,card in ipairs(G.hand.cards) do if SMODS.has_enhancement(card,'m_gold') then b.initial_gold[X.id(card)]=true end end
        elseif c.before and X.once('mission_hand:'..X.blind()..':'..G.GAME.hands_played) then
            b.hands[#b.hands+1]=c.scoring_name;b.activations={};b.sources={};b.lucky_activations=0;b.lucky_money=0
            local ids={};for _,card in ipairs(c.scoring_hand or {}) do ids[X.id(card)]=card.base.id end
            b.last={name=c.scoring_name,level=G.GAME.hands[c.scoring_name].level,count=#(c.scoring_hand or {}),
                full_count=#(c.full_hand or {}),ranks=rankset(c.scoring_hand),ids=ids}
            for _,card in ipairs(c.full_hand or {}) do b.played[X.id(card)]=true;b.touched[X.id(card)]=true end
            if r.obelisk and r.ante>=7 and r.ante<=8 and c.scoring_name==r.obelisk.name then r.obelisk.failed=true end
        elseif c.pre_discard then
            for _,card in ipairs(c.full_hand or {}) do b.touched[X.id(card)]=true end
        elseif c.card_added or c.buying_card then
            local card=c.card
            if c.buying_card and card and card.ability.set=='Booster' and X.once('pack_purchase:'..X.id(card)) then
                a.packs=a.packs+1;r.shop_consume=true
            end
            if card and card.ability.set=='Joker' then
                if G.GAME.facing_blind then b.ever_joker=true end
                if r.rare_sales then r.rare_sales[card.config.center.key]=nil end
                if c.card_added and (card.area==G.pack_cards or card.from_area==G.pack_cards) then card.ability.exp48_origin='pack' end
                if c.buying_card then
                    a.jokers=a.jokers+1;card.ability.exp48_bought_win=r.win_serial or 0
                    card.ability.exp48_origin=(card.area==G.pack_cards or card.from_area==G.pack_cards) and 'pack' or 'shop'
                    r.boss_buys=r.boss_buys or {};r.boss_buys[X.id(card)]=true;r.boss_spent=(r.boss_spent or 0)+(card.cost or 0)
                end
            end
            if c.buying_card and card and card.ability.consumeable then r.shop_consume=true end
        elseif c.playing_card_added then
            if r.history_complete then r.added_playing=true end
        elseif c.using_consumeable and G.GAME.facing_blind then b.consumables=b.consumables+1
        elseif c.starting_shop then r.shop_consume=false;r.shop_tags={}
        elseif c.ending_shop then
            if r.rent_candidate then
                r.rent_streak=r.rent_sold and (r.rent_streak or 0)+1 or 0
                if r.rent_streak>=3 then X.unlock('M12') end
                r.rent_candidate=nil
            end
        elseif c.open_booster then
            local card=c.card
            if card and (card.cost or 0)>0 and (card.from_area==G.shop_booster or card.area==G.shop_booster) and X.once('pack_purchase:'..X.id(card)) then a.packs=a.packs+1;r.shop_consume=true end
            local center=card and card.config.center
            r.pack={taken=0,choices=G.GAME.pack_choices or 1,base_choices=center and center.config.choose or 1,
                key=center and center.key or '',family=center and center.kind or ''}
        elseif c.skipping_booster then
            if r.pack and r.pack.base_choices>=2 and (G.GAME.pack_choices or 0)==r.pack.choices then a.mega[r.pack.family]=true end
        elseif c.money_altered and c.from_shop and c.amount<0 then a.spend=a.spend-c.amount
        elseif c.skip_blind then
            a.skips=a.skips+1;r.winners={}
            r.last_winning_ranks=nil;r.last_winning_count=nil;r.rent_streak=0
            if r.ante==6 or r.ante==7 then
                local kind=G.GAME.blind_on_deck=='Big' and 'Small' or G.GAME.blind_on_deck=='Boss' and 'Big'
                if kind=='Small' or kind=='Big' then r.skip67[tostring(r.ante)..kind]=true end
            end
        elseif c.tag_triggered then
            local tag=c.tag_triggered;local key=tag.key
            if G.STATE==G.STATES.SHOP then r.shop_tags=r.shop_tags or {};r.shop_tags[key]=true;if X.count(r.shop_tags)>=3 then a.shop_tags=true end end
        elseif c.remove_playing_cards then
            for _,card in ipairs(c.removed or {}) do
                local id=X.id(card)
                if id and X.once('grave:'..id..':'..tostring(G.GAME.hands_played)) then
                    local saved=copy_table(card:save());saved.added_to_deck=false
                    X.state().graveyard[#X.state().graveyard+1]={id=id,saved=saved}
                    if #X.state().graveyard>3 then table.remove(X.state().graveyard,1) end
                    if card.config.center.set=='Enhanced' and card.seal and card.edition then a.special_destroy=true end
                    b.touched[id]=true
                end
            end
        end
        if G.GAME.facing_blind and G.deck and #G.deck.cards==0 then b.exhausted=true end
    end)
    local check=check_for_unlock
    function check_for_unlock(args,...)
        local r,b=state()
        if r and args.type=='chip_score' then
            b.last_score=args.chips;b.score_dollars=G.GAME.dollars
            if args.chips<=G.GAME.blind.chips*0.01 then b.small_hand=true
            elseif b.small_hand and args.chips>=G.GAME.blind.chips*2 then b.small_then_large=true end
        elseif r and args.type=='win' then
            if r.history_complete and r.only_common~=false then X.unlock('M11') end
            if r.ante4 and X.count(r.ante4)>=3 and not intersection(r.ante4,X.set(G.jokers.cards)) then X.unlock('M19') end
            if r.history_complete and not r.added_playing and #G.playing_cards<=35 then X.unlock('J02') end
        end
        return check(args,...)
    end
    local start=Game.start_run
    function Game:start_run(args,...)
        local result=start(self,args,...)
        local r=state();if r and not (args and args.savetext) then r.history_complete=true end
        X.sync_centers()
        local F=PortraitFusion
        if F and not F.exp48_tracking then
            F.exp48_tracking=true
            local fuse=F.fuse
            function F.fuse(selection)
                local origins={}
                for _,c in ipairs(selection and {selection.a,selection.b} or {}) do
                    if c and c.ability.exp48_origin then origins[c.ability.exp48_origin]=true end
                end
                local ok=fuse(selection)
                if ok then
                    local run=state();run.fusion_origins=run.fusion_origins or {};run.fusion_serial=(run.fusion_serial or 0)+1
                    if (origins.pack and run.fusion_origins.shop) or (origins.shop and run.fusion_origins.pack) then X.unlock('M15') end
                    for origin in pairs(origins) do run.fusion_origins[origin]=run.fusion_serial end
                end
                return ok
            end
        end
        return result
    end
end
