return function(R,E)
    -- Presentation only: nothing here is stored in ability.extra or save data.
    local A={pending=setmetatable({},{__mode='k'}),next_start=0}
    local function smooth(t) t=math.max(0,math.min(1,t)); return t*t*(3-2*t) end
    local function valid(card,entry)
        return G.GAME==entry.game and not card.removed and not card.getting_sliced and
            card.area==G.jokers and R.for_card(card)==entry.def
    end
    local function restore(card,job)
        if not job or not job.started then return end
        if job.particles then job.particles:remove();job.particles=nil end
        if not card.removed and not card.getting_sliced then
            card.T.scale=job.scale
            card.dissolve=job.dissolve
            card.dissolve_colours=job.colours
            if card.juice==job.juice then card.juice=nil end
            for name,can in pairs(job.controls) do card.states[name].can=can end
        end
    end
    function A.reset()
        for card,entry in pairs(A.pending) do restore(card,entry.active) end
        A.pending=setmetatable({},{__mode='k'});A.game=nil;A.next_start=0
    end
    function A.display_stage(card)
        local entry=A.pending[card]
        if not entry then return end
        -- Also release transient locks if native code cleared the event queue.
        if not valid(card,entry) or G.TIMERS.TOTAL>entry.tail+0.1 then
            restore(card,entry.active); A.pending[card]=nil
            return
        end
        return entry.display
    end
    local function label(card)
        local room=G.ROOM.T
        local width=math.min(card.T.w*1.8,room.w-0.4)
        local cx=card.T.x+card.T.w/2
        local x=math.max(room.x+width/2+0.2,math.min(room.x+room.w-width/2-0.2,cx))
        local inset=G.F_PORTRAIT and get_mobile_safe_area_top and get_mobile_safe_area_top(love.system.getOS()) or 0
        local y=math.max(room.y+inset+0.3,card.T.y-0.25)
        attention_text{text=localize('k_upg_upgrade'),scale=0.42,hold=0.25,maxw=width,
            major=card,align='cm',offset={x=x-cx,y=y-card.T.y-card.T.h/2},
            colour=G.C.RARITY.upg_upgraded or G.C.GOLD,silent=true}
    end
    function A.play(card,old_stage,new_stage,def)
        local now=G.TIMERS.TOTAL
        if A.game~=G.GAME then A.game=G.GAME; A.next_start=now end
        local entry=A.pending[card]
        if entry and entry.target>=new_stage then return end
        local fx=require('portrait_reward_fx')
        local level=fx.admit('evolution',tostring(card.sort_id)..':'..new_stage,2,80,
            {final=def.stages[new_stage] and def.stages[new_stage].final,
             forced=G.STATE==G.STATES.PLAY_TAROT})
        local c=copy_table(R.mod.config.evolution_animation)
        for _,key in ipairs({'prepare','compress','flash','reveal','settle','reduced_duration','stagger'}) do c[key]=PortraitQOL.duration(c[key]) end
        local duration=c.prepare+c.compress+c.flash+c.reveal+c.settle
        local reduced=G.SETTINGS.reduced_motion
        if reduced then duration=c.reduced_duration end
        entry=entry or {game=G.GAME,def=def,display=old_stage,tail=now,count=0}
        local start=math.max(now,A.next_start,entry.tail)
        local job={start=start,finish=start+duration,new_stage=new_stage}
        entry.tail=job.finish; entry.target=new_stage; entry.count=entry.count+1
        A.next_start=start+c.stagger
        A.pending[card]=entry
        -- TOTAL follows native game speed; this event never blocks other events.
        G.E_MANAGER:add_event(Event({blocking=false,blockable=false,func=function()
            if A.pending[card]~=entry then return true end
            if not valid(card,entry) then
                restore(card,entry.active); A.pending[card]=nil
                return true
            end
            local elapsed=G.TIMERS.TOTAL-start
            if elapsed<0 then return false end
            if not job.started then
                job.started=true; entry.active=job
                job.scale=card.T.scale; job.dissolve=card.dissolve; job.colours=card.dissolve_colours
                job.controls={}
                for _,name in ipairs({'hover','click','drag'}) do
                    job.controls[name]=card.states[name].can; card.states[name].can=false
                end
                if not reduced then card:juice_up(0.06,0.06); job.juice=card.juice end
            end
            local flash_start=c.prepare+c.compress
            local peak=reduced and duration*0.4 or flash_start+c.flash/2
            if not reduced then
                local scale=1
                if elapsed>=c.prepare and elapsed<flash_start then
                    scale=1+(c.compressed_scale-1)*smooth((elapsed-c.prepare)/c.compress)
                elseif elapsed>=flash_start and elapsed<peak then scale=c.compressed_scale
                elseif elapsed>=peak and elapsed<flash_start+c.flash then
                    scale=c.compressed_scale+(c.reveal_scale-c.compressed_scale)*smooth((elapsed-peak)/(c.flash/2))
                elseif elapsed>=flash_start+c.flash then
                    scale=c.reveal_scale+(1-c.reveal_scale)*smooth((elapsed-flash_start-c.flash)/c.reveal)
                end
                card.T.scale=job.scale*scale
                local flash=math.max(0,1-math.abs(elapsed-peak)/(c.flash/2))
                card.dissolve=(job.dissolve or 0)+c.flash_dissolve*flash
                card.dissolve_colours={G.C.GOLD,G.C.WHITE}
            end
            if not job.swapped and elapsed>=peak then
                job.swapped=true; entry.display=new_stage
                if level>=2 then PortraitQOL.haptic('evolution') end
                E.refresh(def,card)
                if not reduced and level>=2 then
                    card:juice_up(0.10,0.04); job.juice=card.juice
                    job.particles=Particles(0,0,0,0,{attach=card,fill=true,
                        timer_type='TOTAL',timer=0.015,pulse_max=c.particle_count,max=0,
                        scale=0.12,speed=0.7,lifespan=0.35,colours={G.C.GOLD,G.C.GOLD,G.C.RED}})
                end
                if level>=2 then play_sound('tarot1',1.12,0.35);label(card) end
                if level==3 then fx.milestone(card,nil,{admitted=3}) end
            end
            if elapsed>=duration then
                restore(card,job); entry.active=nil; entry.count=entry.count-1
                if entry.count==0 then A.pending[card]=nil end
                E.refresh(def,card)
                return true
            end
            return false
        end}))
    end
    return A
end
