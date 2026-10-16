-- Test-only callbacks in an isolated archive and save directory.
return function(step,record,write)
    local card, key, logic, offers_before
    local function factor(c) return IncJoker.logic.factor(c.ability.extra) end
    local function find()
        for _,c in ipairs(G.jokers.cards) do if c.config.center.key==IncJoker.key then return c end end
    end
    if QA.resume then
        step('restore_compound_shop',function()
            local saved=STR_UNPACK(assert(get_compressed('1/save.jkr')))
            offers_before=saved.cardAreas.shop_jokers.cards
            local random=pseudorandom
            pseudorandom=function(seed,...)
                assert(seed~='incj_normal_shop_offer','Saved shop performed another mod roll')
                return random(seed,...)
            end
            G:delete_run(); G:start_run({savetext=saved})
        end,5)
        step('dismiss_resume_unlock',function()
            if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end
        end,4)
        step('verify_restored_shop',function()
            card=assert(find()); assert(factor(card)==1.45,'Progress lost on process restart')
            assert(#G.shop_jokers.cards==#offers_before,'Shop count '..#G.shop_jokers.cards..' ~= '..#offers_before)
            for i,c in ipairs(G.shop_jokers.cards) do
                assert(c.config.center.key==offers_before[i].save_fields.center,'Shop changed on restart')
            end
            record('PASS: process restart preserved X1.45 and shop identities; zero new mod rolls')
        end)
        step('actual_scoring_and_spanish',function()
            local old_mult,old_current=mult,SMODS.Scoring_Parameters.mult.current
            mult=20; SMODS.Scoring_Parameters.mult.current=20
            SMODS.calculate_individual_effect({remove_default_message=true},card,'x_mult',1.3)
            assert(mult==26 and SMODS.Scoring_Parameters.mult.current==26,'Actual Mult calculation failed')
            mult=old_mult; SMODS.Scoring_Parameters.mult.current=old_current
            G.SETTINGS.language='es_ES'; G:set_language()
            SMODS.handle_loc_file(SMODS.Mods.incremental_joker.path,'incremental_joker'); init_localization()
            assert(localize{type='name_text',key=IncJoker.key,set='Joker'}=='Interés compuesto')
            local vars=G.P_CENTERS[IncJoker.key]:loc_vars({},card).vars
            assert(vars[1]=='0,15' and vars[2]=='1,45')
            card:hover()
            record('PASS: actual scoring pipeline 20 x 1.30 = 26; es_ES tooltip with current values')
        end)
        return
    end
    step('compound_start',function()
        G.SETTINGS.tutorial_complete=true; G.SETTINGS.tutorial_progress=nil
        if QA.skin then CardSkins.select(2) end
        G:delete_run(); G:start_run({seed='INCJQA'})
        key,logic=IncJoker.key,IncJoker.logic
        card=SMODS.add_card{key=key,area=G.jokers}
        assert(card.config.center.cost==10 and factor(card)==1)
        assert(card.children.center.atlas.name=='incj_compound_interest')
        assert(SMODS.Mods.incremental_joker.can_load~=false)
    end,3)
    step('compound_state_and_copies',function()
        card.ability.extra.won_rounds=2
        local effect=card:calculate_joker({joker_main=true,cardarea=G.jokers})
        assert(effect.x_mult==1.3 and 20*effect.x_mult==26)
        assert(factor(card)==1.3)
        for _,id in ipairs({'j_blueprint','j_brainstorm'}) do
            local copier=SMODS.add_card{key=id,area=G.jokers}
            if id=='j_blueprint' then G.jokers.cards={copier,card} else G.jokers.cards={card,copier} end
            local copy_effect=copier:calculate_joker({joker_main=true,cardarea=G.jokers})
            assert(copy_effect and copy_effect.x_mult==1.3,id..' did not copy score')
            copier:calculate_joker({end_of_round=true,main_eval=true})
            assert(factor(card)==1.3,id..' increased original')
            copier:remove()
        end
        G.jokers.cards={card}
        local clone=copy_card(card); G.jokers:emplace(clone)
        assert(clone.ability.extra~=card.ability.extra and factor(clone)==1.3)
        clone.ability.extra.won_rounds=7; assert(factor(card)==1.3)
        clone:remove()
        SMODS.debuff_card(card,true,'qa')
        assert(not card:calculate_joker({joker_main=true,cardarea=G.jokers}))
        assert(factor(card)==1.3)
        SMODS.debuff_card(card,false,'qa')
        card.ability.extra.won_rounds=0
        record('PASS: X1.30 maps 20 to 26; Blueprint/Brainstorm scoring; independent duplicate; debuff')
    end)
    for round=1,3 do
        local r=round
        step('compound_blind_'..r,function()
            local id=r==1 and 'bl_small' or r==2 and 'bl_big' or G.GAME.round_resets.blind_choices.Boss
            G.FUNCS.select_blind({config={ref_table=G.P_BLINDS[id]},UIBox=G.blind_select})
        end,4)
        step('compound_play_'..r,function()
            G.SETTINGS.GAMESPEED=4
            -- A low QA target exercises the ordinary played-hand victory path.
            G.GAME.blind.chips=1
            G.hand:unhighlight_all(); G.hand:add_to_highlighted(G.hand.cards[1])
            assert(card.ability.extra.won_rounds==r-1)
            G.FUNCS.play_cards_from_highlighted()
        end,10)
        step('compound_win_'..r,function()
            assert(G.round_eval,'Won hand failed to end round')
            assert(card.ability.extra.won_rounds==r,'Actual victory did not advance once')
            card:calculate_joker({end_of_round=true,main_eval=true})
            assert(card.ability.extra.won_rounds==r,'Repeated callback advanced twice')
            G.FUNCS.cash_out({config={}})
        end,4)
        if r<3 then step('compound_next_'..r,function() G.FUNCS.toggle_shop() end,4) end
    end
    local purchase, random, rates
    step('compound_normal_shop_hook',function()
        rates={}
        for _,kind in ipairs({'joker','tarot','planet','spectral','playing_card'}) do
            local field=kind..'_rate'; rates[field]=G.GAME[field]; G.GAME[field]=kind=='joker' and 1 or 0
        end
        random=pseudorandom
        local rolls=0
        pseudorandom=function(seed,...) if seed=='incj_normal_shop_offer' then rolls=rolls+1; return 0 end return random(seed,...) end
        G.GAME.used_jokers[key]=nil
        purchase=create_card_for_shop(G.shop_jokers)
        assert(purchase.config.center.key==key and rolls==1,'Normal offer hook failed')
        assert(factor(purchase)==1 and purchase.cost==10,'New offer did not start at X1/$10')
        G.shop_jokers:emplace(purchase)
        G.GAME.dollars=100
        G.FUNCS.buy_from_shop({config={ref_table=purchase,id='buy'}})
        pseudorandom=random
    end,3)
    step('compound_inspect_reorder_sell',function()
        assert(purchase.area==G.jokers and factor(purchase)==1)
        G.jokers.cards={purchase,card}; G.jokers:align_cards()
        G.jokers:add_to_highlighted(purchase)
        purchase:hover()
        assert(purchase.children.h_popup,'Joker tooltip did not open')
        local vars=G.P_CENTERS[key]:loc_vars({},card).vars
        assert(vars[1]=='0.15' and vars[2]=='1.45','Dynamic tooltip values wrong')
    end)
    step('compound_sale',function()
        purchase:stop_hover(); G.FUNCS.sell_card({config={ref_table=purchase}})
    end,3)
    step('compound_forced_and_new_instances',function()
        assert(#G.jokers.cards==1 and factor(card)==1.45)
        local rolls=0
        pseudorandom=function(seed,...) if seed=='incj_normal_shop_offer' then rolls=rolls+1; return 0 end return random(seed,...) end
        G.GAME.used_jokers[key]=nil
        local new=create_card_for_shop(G.shop_jokers)
        assert(new.config.center.key==key and factor(new)==1 and rolls==1)
        new:remove()
        local context=SMODS.calculate_context
        for _,forced in ipairs({{key='j_joker'}, {rarity=.99}, {legendary=true}}) do
            SMODS.calculate_context=function(c,...)
                if c.create_shop_card then return {shop_create_flags=forced} end
                return context(c,...)
            end
            local c=create_card_for_shop(G.shop_jokers)
            assert(c.config.center.key~=key and rolls==1,'Forced identity/rarity performed mod roll')
            c:remove()
        end
        SMODS.calculate_context=context
        G.SETTINGS.tutorial_progress={forced_shop={'j_joker'}}
        local tutorial=create_card_for_shop(G.shop_jokers)
        assert(tutorial.config.center.key=='j_joker' and rolls==1)
        tutorial:remove(); G.SETTINGS.tutorial_progress=nil
        add_tag(Tag('tag_rare'))
        local tagged=create_card_for_shop(G.shop_jokers)
        assert(tagged.config.center.key~=key and rolls==1,'Rare tag performed mod roll')
        G.shop_jokers:emplace(tagged)
        -- Ordinary non-shop pools cannot choose this center, even with Showman.
        for i=1,20 do
            local c=create_card('Joker',G.jokers,nil,nil,nil,nil,nil,'buf')
            assert(c.config.center.key~=key and rolls==1)
            c:remove()
        end
        pseudorandom=random
        for field,value in pairs(rates) do G.GAME[field]=value end
        G.GAME.used_jokers[key]=true
        record('PASS: normal offer one roll, purchase/inspect/reorder/sale/new X1; forced identity/rarity/tutorial/tag excluded')
    end,3)
    step('compound_probabilities',function()
        local old_used=G.GAME.used_jokers[key]; G.GAME.used_jokers[key]=nil
        local rng=copy_table(G.GAME.pseudorandom)
        local hits=0
        for i=1,100000 do if IncJoker.shop_offer('Joker',G.shop_jokers)==key then hits=hits+1 end end
        assert(hits>850 and hits<1150,'Implausible 1% count')
        record('PASS: '..hits..'/100000 eligible offers with production shop_offer + seeded game RNG')
        local state=copy_table(G.GAME.pseudorandom); local a={}
        for i=1,100 do a[i]=IncJoker.shop_offer('Joker',G.shop_jokers) or false end
        G.GAME.pseudorandom=state
        for i=1,100 do assert(a[i]==(IncJoker.shop_offer('Joker',G.shop_jokers) or false)) end
        G.GAME.pseudorandom=rng
        local random=pseudorandom
        pseudorandom=function(seed,...) assert(seed~='incj_normal_shop_offer','Ineligible roll'); return random(seed,...) end
        assert(not IncJoker.shop_offer('Tarot',G.shop_jokers))
        assert(not IncJoker.shop_offer('Joker',G.jokers))
        G.GAME.banned_keys[key]=true; assert(not IncJoker.shop_offer('Joker',G.shop_jokers)); G.GAME.banned_keys[key]=nil
        G.GAME.used_jokers[key]=true; assert(not IncJoker.shop_offer('Joker',G.shop_jokers))
        pseudorandom=random
        local showman=SMODS.add_card{key='j_ring_master',area=G.jokers}
        local rolls=0
        pseudorandom=function(seed,...) if seed=='incj_normal_shop_offer' then rolls=rolls+1; return 0 end return random(seed,...) end
        assert(IncJoker.shop_offer('Joker',G.shop_jokers)==key and rolls==1)
        showman:remove(); pseudorandom=random
        G.GAME.used_jokers[key]=old_used
    end)
    step('compound_save_shop',function()
        assert(factor(card)==1.45)
        save_run(); love.visible(false); love.visible(true)
        local saved=STR_UNPACK(assert(get_compressed('1/save.jkr')))
        assert(saved.cardAreas.shop_jokers and #saved.cardAreas.shop_jokers.cards>0)
        record('PASS: saved real shop checkpoint with three won blinds / X1.45')
    end)
end
