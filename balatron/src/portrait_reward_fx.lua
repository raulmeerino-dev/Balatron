-- Short, local reward effects. Never enqueue gameplay delays or mutate rewards.
local F={}
-- Optional presentation arbiter. Callers retain ownership of their transaction.
function F.admit(kind,token,level,priority,details)
    if F.arbiter then return F.arbiter(kind,token,level,priority,details) end
    return level
end
local tiers={OVERKILL=1,['MASSIVE OVERKILL']=2,['ABSURD OVERKILL']=3,OBLITERATED=4}
local function text(value,scale,colour,maxw)
    return DynaText{string={value},scale=scale,colours={colour},maxw=maxw,
        shadow=true,silent=true,pop_in=not G.SETTINGS.reduced_motion and 0 or nil,pop_in_rate=12}
end
local function object(value)
    return {n=G.UIT.O,config={object=value}}
end
local function row(value)
    return {n=G.UIT.R,config={align='cl',padding=0},nodes={object(value)}}
end
local function remove(value)
    if value and not value.REMOVED then value:remove() end
end
local function burst(target,tier)
    if G.SETTINGS.reduced_motion then return end
    local p=Particles(target.T.x,target.T.y,target.T.w,target.T.h,{
        timer_type='REAL',timer=0.012,max=0,pulse_max=4+2*tier,
        lifespan=0.22,scale=0.07+0.012*tier,speed=0.45+0.08*tier,
        colours={copy_table(G.C.GOLD),copy_table(G.C.WHITE)}})
    p:set_alignment{major=target,type='cm',bond='Strong'}
    target.children.particle_effect=p
    return p
end
local function flash(colour,base,age)
    local strength=G.SETTINGS.reduced_motion and 0 or math.max(0,1-age/0.16)*0.7
    for i=1,3 do colour[i]=base[i]+(1-base[i])*strength end
end
local function impact(target,tier)
    if G.SETTINGS.reduced_motion then return end
    target:juice_up(0.12+0.035*tier,0.008+0.004*tier)
    target:pulse(0.13+0.025*tier)
end
local function animate(owner,duration,step,finish)
    local game,start=G.GAME,G.TIMERS.REAL
    G.E_MANAGER:add_event(Event{blocking=false,blockable=false,no_delete=true,
        pause_force=true,timer='REAL',presentation=false,func=function()
            local age=G.TIMERS.REAL-start
            if G.GAME~=game or owner.REMOVED or age>=duration then
                finish();return true
            end
            step(age)
            return false
        end})
end
function F.milestone(target,label,config)
    config=config or {}
    if not target or not target.T or target.REMOVED or target.removed then return end
    local level=config.admitted or F.admit(config.kind or 'reward',config.token,config.level or 2,config.priority or 40)
    if level<=0 then return end
    if not G.SETTINGS.reduced_motion and target.juice_up then target:juice_up(level==3 and .22 or .12,.025) end
    if level<2 then return end
    if label then attention_text{text=label,major=target,align='cm',scale=level==3 and .52 or .4,
        maxw=math.min(4,G.ROOM.T.w-.6),hold=PortraitQOL.duration(level==3 and .65 or .35),
        colour=config.colour or G.C.GOLD,silent=true} end
    local sparks=target.children and burst(target,level)
    if config.sound then play_sound(config.sound,1.05,.35) end
    if config.haptic then PortraitQOL.haptic(config.haptic) end
    if sparks then animate(target,.55,function() end,function()
        remove(sparks);if target.children.particle_effect==sparks then target.children.particle_effect=nil end
    end) end
end
function F.overkill(config,center)
    local owner,game=G.round_eval,G.GAME
    -- Wait for preceding native rows, but add no delay to the cash-out button.
    G.E_MANAGER:add_event(Event{blocking=false,presentation=false,func=function()
        if G.GAME~=game or G.round_eval~=owner or owner.REMOVED then return true end
        local width,tier=owner.T.w-0.51,tiers[config.label] or 1
        local receipt=game.current_round.portrait_overkill
        local token=tostring(game.round_resets.ante)..':'..tostring(game.round)
        local level=receipt and receipt.hz_feedback_seen and 0 or F.admit('overkill',token,tier>=3 and 2 or 1,65,{category=config.label})
        if receipt then receipt.hz_feedback_seen=true end
        local gold,money=copy_table(G.C.GOLD),copy_table(G.C.MONEY)
        money[4]=0
        local title=text(config.label,0.34,gold,width*0.53)
        local multiplier=text(config.ratio_text..(config.boss and ' · BOSS +50%' or ''),0.39,gold,width*0.53)
        local reward=text('+'..localize('$')..config.dollars,0.58,money,width*0.4)
        owner:add_child({n=G.UIT.R,config={align='cm',minw=width,padding=0.025},nodes={
            {n=G.UIT.C,config={align='cl',minw=width*0.55,minh=0.65},nodes={row(title),row(multiplier)}},
            {n=G.UIT.C,config={align='cr',minw=width*0.45},nodes={object(reward)}},
        }},owner:get_UIE_by_ID('bonus_round_eval'))
        center()
        if level>0 then impact(multiplier,level) end
        local sparks=level>=2 and burst(multiplier,level) or nil
        if level>0 then play_sound('gold_seal',1.16-0.055*tier,0.28+0.025*tier) end
        if level>=2 then PortraitQOL.haptic('overkill_big') end
        local revealed=false
        local function settle()
            remove(sparks)
            multiplier.children.particle_effect=nil
            multiplier.config.pulse=nil
            reward.config.pulse=nil
            for i=1,4 do gold[i]=G.C.GOLD[i];money[i]=G.C.MONEY[i] end
        end
        animate(owner,0.9,function(age)
            flash(gold,G.C.GOLD,age)
            if age>=0.18 and not revealed then
                revealed=true;money[4]=1
                if level>0 and not G.SETTINGS.reduced_motion then reward:pop_in(0);impact(reward,1) end
                if level>0 then play_sound('coin3',1.15,0.35) end
            end
            if age>=0.38 then remove(sparks);multiplier.children.particle_effect=nil end
            if age>=0.65 then multiplier.config.pulse=nil;reward.config.pulse=nil end
        end,settle)
        return true
    end})
end
local function record_position(width,height,marker)
    local hud,room=G.HUD.T,G.ROOM.T
    local candidates={
        {x=marker.T.x+marker.T.w/2-width/2,y=hud.y-height-0.07},
        {x=hud.x+hud.w+0.10,y=marker.T.y-height-0.05},
    }
    for _,p in ipairs(candidates) do
        p.x=math.max(room.x+0.1,math.min(p.x,room.x+room.w-width-0.1))
        local clear=p.y>=room.y+0.05 and p.y+height<=room.y+room.h-0.05
        for _,area in pairs({G.HUD,G.hand,G.play,G.jokers,G.consumeables,G.deck,G.round_eval}) do
            local t=area.T
            if p.x<t.x+t.w and p.x+width>t.x and p.y<t.y+t.h and p.y+height>t.y then clear=false end
        end
        if clear then return p end
    end
end
function F.record(amount)
    if not G.HUD or G.HUD.REMOVED then return end
    if F.record_popup and F.record_popup.game==G.GAME and not F.record_popup.box.REMOVED then
        F.record_popup.value.text=number_format(amount)
        return -- Coalesce rapid records: no stacked popups, sounds or haptics.
    end
    local level=F.admit('record',G.GAME.portrait_record_feedback_hand,2,60,{amount=amount})
    local dock=G.F_PORTRAIT and G.HUD:get_UIE_by_ID('portrait_record_dock')
    local marker=G.HUD:get_UIE_by_ID('hand_text_area') or G.HUD
    local es=(G.SETTINGS.language or ''):sub(1,2)=='es'
    local gold,white=copy_table(G.C.GOLD),copy_table(G.C.WHITE)
    local value={text=number_format(amount)}
    local label=text(es and 'NUEVO RÉCORD ' or 'NEW RECORD ',dock and 0.21 or 0.29,gold,dock and dock.T.w-0.08 or 3.1)
    local score=text({ref_table=value,ref_value='text'},dock and 0.27 or 0.38,white,dock and dock.T.w-0.08 or 3.2)
    local box=UIBox{definition={n=G.UIT.ROOT,config={align='cm',padding=0.015,colour=G.C.CLEAR},
        nodes=dock and {row(label),row(score)} or {object(label),object(score)}},
        config={align=dock and 'cm' or 'tli',major=dock or G.ROOM,can_collide=false}}
    box.attention_text=true
    local pos=not dock and record_position(box.T.w,box.T.h+0.05,marker)
    if level>=2 then play_sound('foil1',1.28,0.26);PortraitQOL.haptic('record') end
    if not dock and not pos then
        -- On a crowded/custom layout, preserve all information and pulse the
        -- existing score instead of placing a banner over cards or the HUD.
        local target=G.HUD:get_UIE_by_ID('hand_chip_total')
        if target and target.config.object then target.config.object:juice_up(0.15,0) end
        box:remove();return
    end
    if pos then
        box.alignment.offset.x=pos.x-G.ROOM.T.x
        box.alignment.offset.y=pos.y-G.ROOM.T.y
        box:align_to_major();box:hard_set_T(pos.x,pos.y,box.T.w,box.T.h)
    end
    F.record_popup={game=G.GAME,box=box,value=value}
    if level>0 then impact(score,level==3 and 3 or 1) end
    if level==3 then F.milestone(score,nil,{admitted=3}) end
    animate(box,1.0,function(age)
        flash(gold,G.C.GOLD,age)
        if age>=0.5 then score.config.pulse=nil end
        local alpha=math.min(1,math.max(0,(1-age)/0.18))
        gold[4]=alpha;white[4]=alpha
    end,function()
        remove(box)
        if F.record_popup and F.record_popup.box==box then F.record_popup=nil end
    end)
end
function F.joker_result(card,title,message,won)
    local colour=won and G.C.GOLD or G.C.RED
    local label=text(title,0.22,colour,2.35)
    local value=text(message,0.3,G.C.WHITE,2.35)
    local box=UIBox{definition={n=G.UIT.ROOT,config={align='cm',padding=0.025,colour=G.C.CLEAR},
        nodes={row(label),row(value)}},config={align='bmi',offset={x=0,y=0.18},major=card,can_collide=false}}
    box.attention_text=true
    impact(value,1)
    play_sound(won and 'coin3' or 'tarot2',won and 1.15 or 0.85,0.35)
    PortraitQOL.haptic(won and 'buy' or 'select')
    animate(box,0.8,function(age)
        if age>=0.45 then value.config.pulse=nil end
    end,function() remove(box) end)
end
return F
