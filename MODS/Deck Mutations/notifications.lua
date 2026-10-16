-- Durable per-profile receipts; native unlock queue, modal, sounds and Continue.
return function(U,M)
    local queued={}
    local function pending(p,id)
        if p.seen_notifications[id] then return false end
        for _,key in ipairs(p.pending_notifications) do if key==id then return true end end
        return false
    end
    function U.acknowledge(profile,id)
        local p=G.PROFILES[profile] and G.PROFILES[profile].modifier_unlocks
        if not p then return end
        p.seen_notifications[id]=true
        for i=#p.pending_notifications,1,-1 do
            if p.pending_notifications[i]==id then table.remove(p.pending_notifications,i) end
        end
        queued[tostring(profile)..':'..id]=nil
        G:save_progress();G.FILE_HANDLER.force=true
    end
    function U.notify_pending()
        if G.STAGE~=G.STAGES.MAIN_MENU then return end
        local profile=G.SETTINGS.profile;local p=U.profile()
        if not p then return end
        U.check()
        for _,value in ipairs(p.pending_notifications) do
            local id=value;local token=tostring(profile)..':'..id
            if U.definitions[id] and not queued[token] and pending(p,id) then
                queued[token]=true
                create_unlock_overlay('dm_notice_'..id,{
                    valid=function()
                        local valid=G.SETTINGS.profile==profile and G.STAGE==G.STAGES.MAIN_MENU and pending(p,id)
                        if not valid then queued[token]=nil end
                        return valid
                    end,
                    definition=function()
                        local sprite=M.icon(id,3.2).config.object
                        sprite:juice_up(0.3,0.3)
                        local es=(G.SETTINGS.language or ''):sub(1,2)=='es'
                        return create_UIBox_card_unlock(nil,{
                            heading=es and 'Modificador' or 'Modifier',sprite=sprite,
                            description={n=G.UIT.R,config={align='cm',padding=0.16,maxw=7},nodes={
                                {n=G.UIT.T,config={text=localize('k_dm_'..id),scale=0.55,colour=G.C.UI.TEXT_DARK}}
                            }}
                        })
                    end,
                    shown=function(box) box.dm_unlock_notice={profile=profile,id=id} end,
                })
            end
        end
    end
    local notify=unlock_notify
    function unlock_notify(...)
        local result=notify(...);U.notify_pending();return result
    end
    local exit=G.FUNCS.exit_overlay_menu
    G.FUNCS.exit_overlay_menu=function(...)
        local notice=G.OVERLAY_MENU and G.OVERLAY_MENU.dm_unlock_notice
        if notice and notice.profile==G.SETTINGS.profile then U.acknowledge(notice.profile,notice.id) end
        return exit(...)
    end
end
