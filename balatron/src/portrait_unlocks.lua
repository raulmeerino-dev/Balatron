-- Apply the profile's choice to loaded registries, including future SMODS sets.
local U={}
function U.apply()
    local profile=G.PROFILES and G.PROFILES[G.SETTINGS.profile]
    if not (profile and profile.all_unlocked) then return end
    local seen={}
    local function unlock(obj)
        if type(obj)~='table' or seen[obj] or obj.demo or obj.wip then return end
        seen[obj]=true
        if obj.key and (type(obj.unlocked)=='boolean' or type(obj.discovered)=='boolean' or obj._saved_d_u) then
            -- Some classes (notably challenges) expose methods with these
            -- names. Preserve their callbacks and let all_unlocked drive them.
            if type(obj.unlocked)~='function' then obj.unlocked=true end
            if type(obj.discovered)~='function' then obj.discovered=true end
            if type(obj.alerted)~='function' then obj.alerted=true end
        end
    end
    for name,registry in pairs(G) do
        if type(name)=='string' and name:match('^P_') and type(registry)=='table' then
            for _,obj in pairs(registry) do unlock(obj) end
        end
    end
    for _,class in pairs(SMODS or {}) do
        if type(class)=='table' and type(class.obj_table)=='table' then
            for _,obj in pairs(class.obj_table) do unlock(obj) end
        end
    end
    G.P_LOCKED={}
    profile.challenges_unlocked=#G.CHALLENGES
end
function U.install()
    if U.installed then return end;U.installed=true
    -- SMODS restores defaults when switching profiles/reinjecting registries.
    -- Reapply afterwards; never overwrite _d/_u, which belong to those defaults.
    local restore=SMODS.SAVE_UNLOCKS
    function SMODS.SAVE_UNLOCKS(...)
        local result=restore(...);U.apply();return result
    end
    local save=Game.save_progress
    function Game:save_progress(...)
        U.apply();return save(self,...)
    end
    U.apply()
    -- Steamodded's achievement checks read G.GAME; registry installation can
    -- happen before the title screen creates that table on a cold launch.
    if G.GAME then set_discover_tallies()
    else G.E_MANAGER:add_event(Event{blocking=false,blockable=false,func=function()
        if not G.GAME then return false end
        set_discover_tallies();return true
    end}) end
end
return U
