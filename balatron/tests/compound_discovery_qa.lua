-- All forcing here belongs to the isolated QA archive, never the shipped mod.
return function(step,record,write)
    local key='j_incj_compound_interest'
    local expected=QA.discovery=='reopen'
    local bought
    local function close() if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end end
    local function collection(discovered)
        close(); G.ACTIVE_MOD_UI=nil
        G.FUNCS.your_collection()
        G.FUNCS.your_collection_jokers()
        local pool=SMODS.collection_pool(G.P_CENTER_POOLS.Joker)
        local index
        for i,c in ipairs(pool) do if c.key==key then assert(not index); index=i end end
        assert(index,'Missing from normal Collection > Jokers')
        local function find_next(node)
            local c=node.config or {}
            if c.button=='option_cycle' and c.ref_value=='r' and c.ref_table
                and c.ref_table.opt_callback=='SMODS_card_collection_page' then return node end
            for _,child in pairs(node.children or {}) do
                local found=find_next(child); if found then return found end
            end
        end
        local next_button=assert(find_next(G.OVERLAY_MENU.UIRoot),'Collection page control missing')
        for page=2,math.ceil(index/15) do G.FUNCS.option_cycle(next_button) end
        assert(next_button.config.ref_table.current_option==math.ceil(index/15))
        local shown
        for _,area in ipairs(G.your_collection) do
            for _,card in ipairs(area.cards) do if card.config.center.key==key then shown=card end end
        end
        assert(shown,'Collection page did not include Joker')
        assert(shown.config.center.unlocked and not shown.config.center.no_collection)
        assert(shown.config.center.discovered==discovered)
        assert((shown.children.center.atlas.name=='incj_compound_interest')==discovered,'Wrong discovery artwork')
        shown:hover()
        record('PASS: normal Collection > Jokers page '..math.ceil(index/15)..', '..(discovered and 'discovered artwork' or 'undiscovered placeholder'))
    end
    step('collection_on_boot',function()
        assert(G.P_CENTERS[key].unlocked and G.P_CENTERS[key].discovered==expected)
        assert(not G.P_CENTERS[key].no_collection)
        assert(IncJoker.config.shop_probability==.01 and not IncJoker.config.debug)
        G.SETTINGS.tutorial_complete=true; G.SETTINGS.tutorial_progress=nil
        G:delete_run(); G:main_menu()
        collection(expected)
    end,3)
    if QA.discovery=='buy' then
        step('normal_unseeded_shop',function()
            close(); G:delete_run(); G:start_run({})
            assert(not G.GAME.seeded and not G.GAME.challenge)
            G.STATE=G.STATES.SHOP; G.STATE_COMPLETE=false
        end,4)
        step('undiscovered_offer',function()
            assert(not G.P_CENTERS[key].discovered)
            local rng=pseudorandom
            local rolls=0
            pseudorandom=function(seed,...)
                if seed=='incj_normal_shop_offer' then rolls=rolls+1; return .01 end
                return rng(seed,...)
            end
            assert(not IncJoker.shop_offer('Joker',G.shop_jokers) and rolls==1)
            pseudorandom=function(seed,...)
                if seed=='incj_normal_shop_offer' then rolls=rolls+1; return .009999 end
                return rng(seed,...)
            end
            G.GAME.joker_rate=1
            for _,s in ipairs({'tarot','planet','spectral','playing_card'}) do G.GAME[s..'_rate']=0 end
            bought=create_card_for_shop(G.shop_jokers)
            pseudorandom=rng
            assert(bought.config.center.key==key and rolls==2,'Undiscovered Joker not eligible at 1% boundary')
            G.shop_jokers:emplace(bought)
            assert(not G.P_CENTERS[key].discovered,'Shop display discovered Joker before acquisition')
        end)
        step('first_purchase',function()
            G.GAME.dollars=100
            G.FUNCS.buy_from_shop({config={ref_table=bought,id='buy'}})
        end,3)
        step('collection_after_purchase',function()
            assert(bought.area==G.jokers and G.P_CENTERS[key].discovered)
            collection(true)
            record('PASS: first ordinary purchase discovers through native game logic')
        end)
    end
    step('profile_metadata',function()
        close(); G:save_progress(); love.visible(false); love.visible(true)
    end,3)
    step('discovery_persisted',function()
        local meta=STR_UNPACK(assert(get_compressed(G.SETTINGS.profile..'/meta.jkr')))
        assert(not not meta.discovered[key]==(QA.discovery~='initial'),'Profile discovery metadata mismatch')
        assert(G.P_CENTERS[key].unlocked)
        record('PASS: '..QA.discovery..' profile discovery persisted; no manual discover/save flag override')
    end)
end
