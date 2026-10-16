return function(step,record,write)
    local M=require('portrait_background')
    local cfg=PORTRAIT_CONFIG
    local function close() if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end end
    local function find(node,predicate)
        if predicate(node.config or {}) then return node end
        if node.config and node.config.object and node.config.object.UIRoot then
            local found=find(node.config.object.UIRoot,predicate); if found then return found end
        end
        for _,c in pairs(node.children or {}) do local found=find(c,predicate); if found then return found end end
    end
    local function graphics()
        close(); G.FUNCS.settings()
        local tab=assert(find(G.OVERLAY_MENU.UIRoot,function(c)
            return c.button=='change_tab' and c.ref_table.tab_definition_function_args=='Graphics'
        end),'Graphics tab missing')
        G.FUNCS.change_tab(tab)
        return assert(find(G.OVERLAY_MENU.UIRoot,function(c)
            return c.button=='option_cycle' and c.ref_value=='r' and c.ref_table.opt_callback=='change_animated_background'
        end),'Animated Background cycle missing')
    end
    local background_image
    if QA.background~='exercise' then
        local before,shader_time
        step('preference_restored',function()
            assert(G.SETTINGS.animated_background==(QA.background=='resume_on'),'Saved preference lost')
            assert(cfg.background_cycle_seconds==480)
            graphics()
            record('PASS: '..QA.background..' restored from settings.jkr in new process')
        end,3)
        step('wave_start',function()
            close()
            before=background_image(5/7,false):getString()
            shader_time=G.TIMERS.REAL_SHADER
        end,2)
        step('waves_move',function()
            assert(G.TIMERS.REAL_SHADER>shader_time,'Original shader clock stopped')
            assert(before~=background_image(5/7,false):getString(),'Waves stopped with fixed new tint')
            record('PASS: original waves move with fixed new tint, colour-cycle setting '..QA.background)
        end)
        if QA.background=='resume_off' then
            step('enable_again',function()
                local button=graphics(); G.FUNCS.option_cycle(button)
                assert(G.SETTINGS.animated_background)
                close(); love.visible(false); love.visible(true)
            end,3)
        end
    end
    background_image=function(phase,bypass)
        M.sample(phase,cfg,true)
        local original=M.for_uniform
        if bypass then M.for_uniform=function(_,_,_,value) return value end end
        local w,h=G.CANVAS:getPixelDimensions()
        local canvas=love.graphics.newCanvas(w,h)
        love.graphics.push('all'); love.graphics.setCanvas(canvas); love.graphics.clear(0,0,0,1)
        love.graphics.origin(); love.graphics.scale(G.CANV_SCALE)
        G.SPLASH_BACK:translate_container(); G.SPLASH_BACK:draw()
        love.graphics.pop()
        M.for_uniform=original
        local data=canvas:newImageData(); canvas:release()
        return data
    end
    if QA.background~='exercise' then return end
    local function verify_scene(name)
        local refs={background=G.SHADERS.background,splash=G.SHADERS.splash,atlas=G.SPLASH_BACK.atlas}
        local colours=STR_PACK(G.C)
        local old=background_image(0,true)
        write(name..'-original.png',old:encode('png'):getString())
        local reference=background_image(0,false)
        local original_delta=0
        for p=0,6 do
            local data=background_image(p/7,false)
            write(name..'-tint-'..p..'.png',data:encode('png'):getString())
            local max_delta,max_rgb=0,0
            for y=0,data:getHeight()-1,7 do for x=0,data:getWidth()-1,7 do
                local r,g,b,a=reference:getPixel(x,y)
                local R,H,B,A=data:getPixel(x,y)
                local or_,og,ob=old:getPixel(x,y)
                original_delta=math.max(original_delta,math.abs(.2126*(R-or_)+.7152*(H-og)+.0722*(B-ob)))
                max_delta=math.max(max_delta,math.abs(.2126*(R-r)+.7152*(H-g)+.0722*(B-b)))
                max_rgb=math.max(max_rgb,math.abs(R-r),math.abs(H-g),math.abs(B-b))
                assert(a==A,'Background alpha changed')
            end end
            assert(max_delta<.0041,'Luma/pattern changed: '..max_delta)
            if p==0 and (name=='hand' or name=='blind-selection') then
                assert(original_delta<.0041,'Original green no longer matches: '..original_delta)
            end
        end
        assert(refs.background==G.SHADERS.background and refs.splash==G.SHADERS.splash and refs.atlas==G.SPLASH_BACK.atlas)
        assert(STR_PACK(G.C)==colours,'Shared UI/card palette mutated')
        -- Pixel comparison of everything except the background at identical game time.
        local back=G.SPLASH_BACK; G.SPLASH_BACK=nil
        M.sample(0,cfg,true); G:draw(); local a=G.CANVAS:newImageData():getString()
        M.sample(5/7,cfg,true); G:draw(); local b=G.CANVAS:newImageData():getString()
        G.SPLASH_BACK=back
        assert(a==b,'Foreground pixels changed with tint')
        record(string.format('PASS: %s: original shader/atlas, seven tones, cycle luma error < 0.0041; foreground byte-identical; max original luma delta %.5f',name,original_delta))
    end
    step('menu',function()
        assert(G.SETTINGS.animated_background==true)
        G.SETTINGS.tutorial_complete=true; G.SETTINGS.tutorial_progress=nil
        G:delete_run(); G:main_menu()
    end,3)
    step('menu_tints',function() verify_scene('menu') end)
    step('graphics_option',function() graphics() end,2)
    step('blind_selection',function()
        close(); CardSkins.select(2); G:delete_run(); G:start_run({seed='TINTQA'})
    end,3)
    step('blind_selection_tints',function() verify_scene('blind-selection') end)
    step('hand',function()
        G.FUNCS.select_blind({config={ref_table=G.P_BLINDS.bl_small},UIBox=G.blind_select})
    end,4)
    step('hand_tints',function()
        SMODS.add_card{key=IncJoker.key,area=G.jokers}
        verify_scene('hand')
    end)
    for p=0,6 do
        local phase=p/7
        step('hand_palette_'..p,function() M.elapsed=phase*cfg.background_cycle_seconds end,.3)
    end
    step('play',function()
        G.GAME.blind.chips=1; G.SETTINGS.GAMESPEED=4
        G.hand:unhighlight_all(); G.hand:add_to_highlighted(G.hand.cards[1]); G.FUNCS.play_cards_from_highlighted()
    end,10)
    step('cashout',function()
        assert(G.round_eval)
        assert(IncJoker.logic.factor(G.jokers.cards[1].ability.extra)==1.15)
        G.FUNCS.cash_out({config={}})
    end,4)
    step('shop_tints',function() assert(G.shop); verify_scene('shop') end)
    step('pack',function() G.FUNCS.use_card({config={ref_table=G.shop_booster.cards[1]}}) end,4)
    step('pack_tints',function() assert(G.pack_cards); verify_scene('pack') end)
    step('close_pack',function() G.FUNCS.skip_booster() end,3)
    step('performance',function()
        local c={.3,.5,.4,1}
        local count=200000
        for i=1,10000 do M.update(1/60,G.SETTINGS,cfg); M.colour('colour_1',c) end
        collectgarbage('collect'); local memory=collectgarbage('count')
        local t=love.timer.getTime()
        for i=1,count do
            M.update(1/60,G.SETTINGS,cfg)
            M.for_uniform(G.SPLASH_BACK,'background','colour_1',c)
            M.for_uniform(G.SPLASH_BACK,'background','colour_2',c)
            M.for_uniform(G.SPLASH_BACK,'background','colour_3',c)
        end
        local micros=(love.timer.getTime()-t)*1e6/count
        collectgarbage('collect'); local delta=collectgarbage('count')-memory
        write('performance.txt',string.format('CPU update + 3 colour uniforms: %.3f microseconds/iteration; retained memory delta %.3f KiB; %d iterations\n',micros,delta,count))
        record(string.format('PASS: performance %.3f us/frame CPU benchmark; no added GPU draw/pass/texture',micros))
        cfg.background_cycle_seconds=10; M.elapsed=0
    end)
    step('accelerated_cycle',function() end,10.2)
    step('restore_release_and_off',function()
        cfg.background_cycle_seconds=480
        local button=graphics(); G.FUNCS.option_cycle(button)
        assert(G.SETTINGS.animated_background==false)
        close(); local before={unpack(M.tint)}
        M.update(100,G.SETTINGS,cfg)
        for i=1,3 do assert(M.tint[i]==before[i]) end
        assert(M.elapsed==0)
        love.visible(false); love.visible(true)
        record('PASS: 240s restored; Off holds original green while retaining shader motion')
    end,3)
end
