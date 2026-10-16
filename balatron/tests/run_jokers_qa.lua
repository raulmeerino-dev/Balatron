-- Directed checks with actual cards, Steamodded, scoring hooks and disk saves.
-- Included only by the isolated desktop harness, never by Game.love / IPA.
return function(step,record,write)
    local ids={'tax_collector','hipster','world_record','excessive_force','collector'}
    local cards={}
    local S=require('portrait_score')
    local function spanish()
        G.SETTINGS.language='es_ES';G:set_language()
        SMODS.handle_loc_file(SMODS.path,'_')
        for _,mod in ipairs(SMODS.mod_list) do
            if mod.can_load and not mod.lovely_only then SMODS.handle_loc_file(mod.path,mod.id) end
        end
        init_localization()
    end
    local function close() if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end end
    local function find()
        for _,c in ipairs(G.jokers.cards) do
            for _,id in ipairs(ids) do if c.config.center.key=='j_incj_'..id then cards[id]=c end end
        end
        for _,id in ipairs(ids) do assert(cards[id],id..' missing') end
    end
    local function score(id,name)
        return cards[id]:calculate_joker{joker_main=true,cardarea=G.jokers,scoring_name=name or 'High Card'}
    end
    local function collection()
        local enabled=G.GAME.incj_config.enabled
        G.GAME.incj_config.enabled=false
        close();G.ACTIVE_MOD_UI=SMODS.Mods.incremental_joker
        G.FUNCS.your_collection_jokers()
        local found={}
        for _,area in ipairs(G.your_collection) do
            for _,card in ipairs(area.cards) do
                found[card.config.center.key]=true
                assert(card.config.center.unlocked)
                if card.config.center.key~=IncJoker.key then
                    assert(card.config.center.discovered,'Discovery missing')
                    assert(card.children.center.atlas.name==card.config.center.atlas,'Atlas missing')
                    card:hover();card:stop_hover()
                end
            end
        end
        for _,id in ipairs(ids) do assert(found['j_incj_'..id],id..' missing from collection') end
        G.GAME.incj_config.enabled=enabled
    end
    if QA.resume then
        local saved
        step('resume_from_disk',function()
            saved=STR_UNPACK(assert(get_compressed('1/save.jkr')))
            G:delete_run();G:start_run{savetext=saved}
        end,5)
        step('saved_progress_and_receipts',function()
            close();find()
            for _,sc in ipairs(saved.cardAreas.jokers.cards) do
                local id=sc.save_fields.center:match('^j_incj_(.*)$')
                if cards[id] then
                    assert(STR_PACK(cards[id].ability.extra)==STR_PACK(sc.ability.extra),'Extra changed on load: '..id)
                end
            end
            assert(cards.tax_collector.ability.extra.gains==1 and cards.excessive_force.ability.extra.gains==1)
            assert(cards.world_record.ability.extra.gains==1)
            for i,id in ipairs({'tax_collector','hipster','world_record','excessive_force'}) do
                assert(cards[id].edition.type==({'foil','holo','polychrome','negative'})[i],'Edition lost on load')
            end
            assert(cards.tax_collector.ability.eternal and cards.hipster.ability.perishable)
            assert(cards.hipster.ability.perish_tally==G.GAME.perishable_rounds-1)
            assert(cards.excessive_force.ability.rental and G.jokers.config.card_limit==6)
            assert(S.evaluate()==0,'Settled Overkill paid again')
            S.record(G.GAME.portrait_best_hand)
            SMODS.calculate_context{portrait_overkill=cards.tax_collector.ability.extra.last_event,overkill_log10=1,no_blueprint=true}
            SMODS.calculate_context{portrait_hand_record=cards.world_record.ability.extra.last_event,no_blueprint=true}
            assert(G.GAME.portrait_record_hand==saved.GAME.portrait_record_hand,'Record receipt lost on load')
            assert(cards.tax_collector.ability.extra.gains==1 and cards.excessive_force.ability.extra.gains==1)
            assert(cards.world_record.ability.extra.gains==1)
            assert(IncJoker.modification_count()==2,'Deck modifications lost')
            record('PASS: native disk restart preserves all five abilities, deck types, record and Overkill receipts')
        end,2)
        step('collection_after_restart',collection,2)
        step('spanish_dynamic_tooltips',function()
            close();G.ACTIVE_MOD_UI=nil
            spanish()
            local names={'Recaudador','Hipster','Récord Mundial','Exceso de Fuerza','Coleccionista'}
            for i,id in ipairs(ids) do
                assert(localize{type='name_text',key='j_incj_'..id,set='Joker'}==names[i])
                local vars=cards[id].config.center:loc_vars({},cards[id]).vars
                assert(vars and #vars>0)
                cards[id]:hover();assert(cards[id].children.h_popup);cards[id]:stop_hover()
            end
            cards.collector:hover()
        end,2)
        step('spanish_extra_config',function()
            cards.collector:stop_hover();close();SMODS.LAST_SELECTED_MOD_TAB='config';G.FUNCS.openModUI_incremental_joker()
        end,2)
        step('spanish_extra_config_page_two',function()
            G.FUNCS.pmi_config_page{to_key=2,cycle_config={mod_id='incremental_joker'}}
        end,2)
        local purchases,rates,limit={},{}
        step('native_shop_purchases',function()
            close();G.ACTIVE_MOD_UI=nil;G.GAME.dollars=1000
            limit=G.jokers.config.card_limit;G.jokers.config.card_limit=20
            for _,kind in ipairs({'joker','tarot','planet','spectral','playing_card'}) do
                local key=kind..'_rate';rates[key]=G.GAME[key];G.GAME[key]=kind=='joker' and 1 or 0
            end
            for _,id in ipairs(ids) do
                local calculate=SMODS.calculate_context
                SMODS.calculate_context=function(context,...)
                    if context.create_shop_card then return {shop_create_flags={key='j_incj_'..id}} end
                    return calculate(context,...)
                end
                local card=create_card_for_shop(G.shop_jokers)
                SMODS.calculate_context=calculate
                assert(card.config.center.key=='j_incj_'..id)
                assert(card.cost>=1 and card.sell_cost>=1)
                assert(not card.ability.extra.gains or card.ability.extra.gains==0,'New purchase inherited old progress')
                G.shop_jokers:emplace(card);purchases[id]=card
                G.FUNCS.buy_from_shop{config={ref_table=card,id='buy'}}
            end
        end,3)
        step('native_shop_sales',function()
            assert(G.GAME.dollars<1000,'Purchases did not charge money')
            S.evaluate();S.record(G.GAME.portrait_best_hand)
            for id,card in pairs(purchases) do
                assert(card.area==G.jokers and card.added_to_deck,'Purchase failed: '..id)
                assert(not card.ability.extra.gains or card.ability.extra.gains==0,'New card received a past event')
                card:set_eternal(false)
                assert(card:can_sell_card(),'Cannot sell: '..id)
            end
            -- A sale sets the native stop-use lock immediately. Validate all
            -- buttons before queuing the asynchronous sale callbacks.
            for _,card in pairs(purchases) do
                G.FUNCS.sell_card{config={ref_table=card}}
            end
        end,3)
        step('native_removal_and_unlock_all',function()
            for id,card in pairs(purchases) do assert(card.removed and not card.area,'Sold card retained: '..id) end
            for key,value in pairs(rates) do G.GAME[key]=value end
            G.jokers.config.card_limit=limit
            local clone=copy_card(cards.excessive_force);clone:add_to_deck();G.jokers:emplace(clone)
            G.jokers:handle_card_limit()
            assert(G.jokers.config.card_limit==limit+1,'Negative clone did not add a slot')
            clone:remove();G.jokers:handle_card_limit()
            assert(G.jokers.config.card_limit==limit and clone.removed and not clone.added_to_deck)
            local gains=clone.ability.extra.gains
            clone.config.center:calculate(clone,{portrait_overkill='removed-card',overkill_log10=1})
            assert(clone.ability.extra.gains==gains,'Removed Joker received growth')
            local deck_size=#G.playing_cards
            local modified=create_playing_card({front=G.P_CARDS.S_A,center=G.P_CENTERS.m_steel},G.deck,nil,true)
            assert(#G.playing_cards==deck_size+1 and IncJoker.modification_count()==3)
            modified:remove();assert(#G.playing_cards==deck_size and IncJoker.modification_count()==2)
            G.FUNCS.profile_select()
            for _,id in ipairs(ids) do
                local c=G.P_CENTERS['j_incj_'..id];c.discovered=false;c.unlocked=false
            end
            G.FUNCS.unlock_all{config={}}
            assert(G.PROFILES[G.SETTINGS.profile].all_unlocked)
            for _,id in ipairs(ids) do
                local c=G.P_CENTERS['j_incj_'..id];assert(c.unlocked and c.discovered and c.alerted)
            end
            record('PASS: native shop creation/purchase/sale for all five; fresh progress; removed cards stop effects; Negative slot cleanup; Unlock All')
        end,3)
        return
    end
    step('register_and_start',function()
        if QA.w<390 then
            spanish()
        end
        G.SETTINGS.tutorial_complete=true;G.SETTINGS.tutorial_progress=nil
        G:delete_run();G:start_run{}
        local rarities={2,3,2,3,2};local prices={5,8,6,8,6}
        for i,id in ipairs(ids) do
            local center=assert(G.P_CENTERS['j_incj_'..id])
            assert(center.rarity==rarities[i] and center.cost==prices[i])
            assert(center.unlocked and not center.no_collection and not center.discovered)
            assert(center:in_pool())
            cards[id]=SMODS.add_card{key=center.key,area=G.jokers}
        end
    end,3)
    step('individual_effects_and_guards',function()
        assert(score('tax_collector').mult==0 and score('world_record').mult==0)
        assert(score('excessive_force').x_mult==1)
        assert(score('collector').mult==0)
        S.record(100);S.record(100);S.record(99);S.record(101)
        assert(score('world_record').mult==6,'Same hand reported with a higher score grew twice')
        G.GAME.hands_played=G.GAME.hands_played+1
        S.record(102);S.record(0/0);S.record(math.huge)
        assert(score('world_record').mult==12,'Record threshold / duplicate failed')
        local event={portrait_overkill='qa:1',overkill_log10=1,no_blueprint=true}
        SMODS.calculate_context(event);SMODS.calculate_context(event)
        assert(score('tax_collector').mult==1 and score('excessive_force').x_mult==1.1)
        for _,id in ipairs({'tax_collector','world_record','excessive_force'}) do
            local card=cards[id];local gains=card.ability.extra.gains
            for _,flag in ipairs({'blueprint','retrigger_joker','repetition','individual'}) do
                local context={portrait_overkill='qa:2',overkill_log10=1,portrait_hand_record=102}
                context[flag]=true;card:calculate_joker(context)
                assert(card.ability.extra.gains==gains,'Duplicate growth: '..flag)
            end
            SMODS.debuff_card(card,true,'qa')
            card:calculate_joker{portrait_overkill='qa:3',overkill_log10=1,portrait_hand_record=103}
            assert(card.ability.extra.gains==gains and not score(id),'Debuff failed')
            SMODS.debuff_card(card,false,'qa')
        end
        record('PASS: all three scaling Jokers, exact record threshold, repeated events, Blueprint/retrigger/debuff guards')
    end,2)
    step('hipster_ties_and_collector_types',function()
        local hands=copy_table(G.GAME.hands)
        for _,h in pairs(G.GAME.hands) do h.played=0 end
        for name in pairs(G.GAME.hands) do assert(IncJoker.least_played(name),'Unused hand excluded: '..name) end
        G.GAME.hands['High Card'].played=1
        assert(not IncJoker.least_played('High Card') and IncJoker.least_played('Pair'))
        assert(score('hipster','High Card').x_mult==2,'First play must qualify against zero-use ties')
        for _,h in pairs(G.GAME.hands) do h.played=2 end
        G.GAME.hands['High Card'].played=1
        G.GAME.hands.Pair.played=1
        assert(IncJoker.least_played('High Card') and IncJoker.least_played('Pair'))
        assert(not IncJoker.least_played('Full House'))
        G.GAME.hands['High Card'].played=2 -- increment already done by evaluate_play
        assert(score('hipster','High Card').x_mult==2)
        G.GAME.hands['High Card'].played=3
        assert(not score('hipster','High Card'))
        G.GAME.hands=hands
        local a,b=G.playing_cards[1],G.playing_cards[2]
        a:set_ability(G.P_CENTERS.m_gold);b:set_ability(G.P_CENTERS.m_gold)
        a:set_seal('Red',true);b:set_seal('Red',true)
        a:set_edition({foil=true},true,true)
        assert(IncJoker.modification_count()==3 and score('collector').mult==9)
        b:set_ability(G.P_CENTERS.m_steel)
        assert(IncJoker.modification_count()==4 and score('collector').mult==12)
        local c=G.playing_cards[3]
        c:set_ability(G.P_CENTERS.m_glass);c:set_edition({polychrome=true},true,true);c:set_seal('Blue',true)
        assert(IncJoker.modification_count()==7 and score('collector').mult==21,'Concrete modifications merged by family')
        c:set_ability(G.P_CENTERS.c_base);c:set_edition(nil,true,true);c:set_seal(nil,true)
        b:set_ability(G.P_CENTERS.c_base);b:set_seal(nil,true)
        a:set_edition(nil,true,true)
        assert(IncJoker.modification_count()==2 and score('collector').mult==6)
        local original=SMODS.get_enhancements
        SMODS.get_enhancements=function(c,...) local t=original(c,...);if c==a then t.m_bonus=true end;return t end
        assert(IncJoker.modification_count()==3,'Multi-enhancement helper ignored')
        SMODS.get_enhancements=original
        local sticker=next(SMODS.Stickers)
        a.ability[sticker]=true;b.ability[sticker]=true
        assert(IncJoker.modification_count()==3,'Registered sticker type was not deduplicated')
        a.ability[sticker]=nil;b.ability[sticker]=nil
        record('PASS: all zero-use ties including hidden hands; seven concrete modification types, duplicates and removal')
    end,2)
    step('combinations_copies_and_pools',function()
        local old=G.jokers.cards
        for _,copy_key in ipairs({'j_blueprint','j_brainstorm'}) do
            local copier=SMODS.add_card{key=copy_key,area=G.jokers}
            for _,id in ipairs(ids) do
                G.jokers.cards=copy_key=='j_blueprint' and {copier,cards[id]} or {cards[id],copier}
                local copied=copier:calculate_joker{joker_main=true,cardarea=G.jokers,scoring_name='High Card'}
                local native=score(id)
                assert(copied and native and copied.mult==native.mult and copied.x_mult==native.x_mult,copy_key..': '..id)
                local gains=cards[id].ability.extra.gains
                copier:calculate_joker{portrait_overkill='copy-test',overkill_log10=2,portrait_hand_record='copy-test'}
                assert(cards[id].ability.extra.gains==gains,copy_key..' duplicated growth')
            end
            G.jokers.cards=old;copier:remove()
        end
        local clone=copy_card(cards.world_record)
        assert(clone.ability.extra~=cards.world_record.ability.extra and clone.ability.extra.gains==2)
        clone.ability.extra.gains=7;assert(cards.world_record.ability.extra.gains==2)
        clone:remove()
        local old_mult=mult;local old_current=SMODS.Scoring_Parameters.mult.current
        mult=10;SMODS.Scoring_Parameters.mult.current=10
        for _,id in ipairs({'tax_collector','world_record','collector','excessive_force','hipster'}) do
            local effect=score(id)
            for k,v in pairs(effect) do if k=='mult' or k=='x_mult' then
                SMODS.calculate_individual_effect({remove_default_message=true},cards[id],k,v)
            end end
        end
        assert(math.abs(mult-63.8)<1e-8,'Combined native Mult resolution failed')
        mult=old_mult;SMODS.Scoring_Parameters.mult.current=old_current
        for _,id in ipairs(ids) do
            local key='j_incj_'..id;local c=G.P_CENTERS[key]
            G.GAME.used_jokers[key]=nil
            local pool=get_current_pool('Joker',c.rarity==2 and .8 or .99)
            local seen=false;for _,v in ipairs(pool) do if v==key then seen=true end end
            assert(seen,'Missing rarity pool: '..id)
            G.GAME.incj_config.jokers[id]=false;assert(not c:in_pool())
            G.GAME.incj_config.jokers[id]=true;G.GAME.used_jokers[key]=true
        end
        for _,id in ipairs({'tax_collector','world_record','excessive_force'}) do
            cards[id].ability.extra.gains=0;cards[id].ability.extra.last_event=''
        end
        G.GAME.portrait_best_hand=0
        G.GAME.portrait_record_hand=nil;G.GAME.hands_played=0
        record('PASS: Blueprint and Brainstorm copy all five scores, never growth; real Mult pipeline, rarity pools and switches')
    end,2)
    step('editions_and_stickers',function()
        local editions={'foil','holo','polychrome','negative'}
        for _,id in ipairs(ids) do
            local card=cards[id];local extra=STR_PACK(card.ability.extra)
            for _,edition in ipairs(editions) do
                local limit=G.jokers.config.card_limit
                card:set_edition({[edition]=true},true,true)
                G.jokers:handle_card_limit()
                assert(card.edition.key=='e_'..edition and STR_PACK(card.ability.extra)==extra)
                if edition=='negative' then assert(G.jokers.config.card_limit==limit+1) end
                card:set_edition(nil,true,true);G.jokers:handle_card_limit()
                assert(G.jokers.config.card_limit==limit)
            end
            card:set_eternal(true);assert(card.ability.eternal and not card:can_sell_card())
            card:set_eternal(false);card:set_perishable(true)
            if id=='hipster' or id=='collector' then
                assert(card.ability.perishable)
                card.ability.perish_tally=1;card:calculate_perishable()
                assert(card.debuff and not score(id))
                card.ability.perishable=nil;card:set_debuff(false)
            else assert(not card.ability.perishable,'Scaling Joker must follow vanilla Perishable exclusion') end
            card:set_rental(true);assert(card.ability.rental and card.cost==1)
            card:set_rental(false)
        end
        cards.tax_collector:set_edition({foil=true},true,true);cards.tax_collector:set_eternal(true)
        cards.hipster:set_edition({holo=true},true,true);cards.hipster:set_perishable(true)
        cards.world_record:set_edition({polychrome=true},true,true)
        cards.excessive_force:set_edition({negative=true},true,true);cards.excessive_force:set_rental(true)
        record('PASS: all five accept four native editions; Negative slots restore; Eternal sale lock; Perishable debuff; Rental pricing')
    end,3)
    step('collection_all_five',collection,2)
    step('extra_jokers_config',function()
        close();G.ACTIVE_MOD_UI=nil;SMODS.LAST_SELECTED_MOD_TAB='config'
        G.FUNCS.openModUI_incremental_joker()
    end,2)
    step('actual_blind',function()
        close();G.ACTIVE_MOD_UI=nil
        G.FUNCS.select_blind{config={ref_table=G.P_BLINDS.bl_small},UIBox=G.blind_select}
    end,4)
    step('actual_hand',function()
        G.GAME.blind.chips=1;G.SETTINGS.GAMESPEED=4
        G.hand:unhighlight_all();G.hand:add_to_highlighted(G.hand.cards[1])
        G.FUNCS.play_cards_from_highlighted()
    end,9)
    step('actual_overkill_and_record',function()
        assert(G.round_eval and G.GAME.current_round.portrait_overkill.dollars>0)
        assert(cards.tax_collector.ability.extra.gains==1 and cards.excessive_force.ability.extra.gains==1)
        assert(cards.world_record.ability.extra.gains==1)
        local bonus=G.GAME.current_round.portrait_overkill
        S.evaluate();S.record(G.GAME.portrait_best_hand)
        assert(cards.tax_collector.ability.extra.gains==1 and cards.world_record.ability.extra.gains==1)
        G.FUNCS.cash_out{config={}}
        record('PASS: actual played hand / native score record / Overkill summary; no duplicate evaluation growth')
    end,4)
    step('save_checkpoint',function()
        save_run();G:save_progress();love.visible(false);love.visible(true)
        assert(G.GAME.current_round.portrait_overkill.paid and G.GAME.portrait_overkill.blinds==1)
        record('PASS: native disk checkpoint; Overkill money credited once')
    end,3)
end
