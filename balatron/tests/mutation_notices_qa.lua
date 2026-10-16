-- Two actual process launches verify durable unlock notices and profile isolation.
local function log(s) local f=assert(io.open(QA.out..'/result.txt','a'));f:write(s..'\n');f:close() end
love.errorhandler=function(err) log('FAIL '..tostring(err)..'\n'..debug.traceback());return function() return 1 end end
love.errhand=love.errorhandler
local steps={};local function step(name,fn,delay) steps[#steps+1]={name=name,fn=fn,delay=delay or 2} end
local U,M
local second=love.filesystem.getInfo('modifier-notice-phase-one')~=nil
local function initialize()
 U=PortraitModifierUnlocks;M=PortraitGameplay.modules.deck_mutations
 G.SETTINGS.tutorial_complete=true;G.SETTINGS.tutorial_progress=nil;G.SETTINGS.SOUND.volume=0
 G.SETTINGS.GAMESPEED=4
end
local function fresh()
 G:load_profile(G.SETTINGS.profile)
 local p=G.PROFILES[G.SETTINGS.profile];p.all_unlocked=nil;p.modifier_unlocks=nil;p.portrait_collection=nil;U.profile();set_profile_progress()
end
local function disk(n) return STR_UNPACK(assert(get_compressed(n..'/profile.jkr'))).modifier_unlocks end
local function shown(id)
 assert(G.STAGE==G.STAGES.MAIN_MENU)
 local notice=G.OVERLAY_MENU and G.OVERLAY_MENU.dm_unlock_notice
 assert(notice and notice.id==id,'Expected notice '..id..' profile='..G.SETTINGS.profile..' pending='..table.concat(U.profile().pending_notifications,',')..' overlay='..tostring(G.OVERLAY_MENU~=nil)..' paused='..tostring(G.SETTINGS.paused)..' queues='..#G.E_MANAGER.queues.unlock..' state='..tostring(G.STATE))
 assert(U.profile().unlocked[id] and not U.profile().seen_notifications[id])
end
if not second then
 step('unlock_in_run',function()
  initialize();G.SETTINGS.profile=1;fresh();G:delete_run();G:start_run{seed='NOTICE1'}
  U.record('sales',20,'real-progress');assert(U.unlocked('profitable_sale'))
  assert(#U.profile().pending_notifications==1 and not G.OVERLAY_MENU)
 end,3)
 step('saved_immediately_profile_one',function()
  local p=disk(1);assert(p.unlocked.profitable_sale and p.pending_notifications[1]=='profitable_sale')
  G:load_profile(2);G.SETTINGS.profile=2;fresh();U.unlock('free_reroll')
 end,3)
 step('profile_two_independent',function()
  local p=disk(2);assert(p.unlocked.free_reroll and not p.unlocked.profitable_sale)
  assert(p.pending_notifications[1]=='free_reroll')
  G.SETTINGS.profile=1;G:save_settings();love.filesystem.write('modifier-notice-phase-one','ready')
  log('PASS pending notices saved before returning to menu; exiting process');love.event.quit()
 end)
else
 step('enter_menu_after_restart',function() initialize();G.E_MANAGER:clear_queue();G:main_menu('game') end,4)
 step('restart_pending_notice',function() shown('profitable_sale') end,2)
 step('acknowledge_once',function() G.FUNCS.continue_unlock() end,2)
 step('no_repeat_on_menu',function()
  assert(not G.OVERLAY_MENU);unlock_notify();assert(#U.profile().pending_notifications==0)
  assert(disk(1).seen_notifications.profitable_sale)
 end,2)
 step('multiple_unlocks_in_run',function()
  assert(not G.OVERLAY_MENU);G:start_run{seed='NOTICE2'}
  U.record('rare',1,nil,true);U.record('editions',3,'editions')
  assert(#U.profile().pending_notifications==2 and not G.OVERLAY_MENU)
 end,3)
 step('return_to_menu',function() G.FUNCS.go_to_menu() end,4)
 step('first_queued_notice',function() shown('rare_market') end)
 step('continue_queue',function() G.FUNCS.continue_unlock() end)
 step('second_queued_notice',function() shown('shiny_market') end)
 step('finish_queue',function() G.FUNCS.continue_unlock() end)
 step('queue_exhausted',function()
  assert(not G.OVERLAY_MENU and #U.profile().pending_notifications==0)
  unlock_notify();G.focused_profile=2;G.FUNCS.load_profile()
 end,4)
 step('other_profile_kept_its_notice',function() shown('free_reroll') end)
 step('acknowledge_other_profile',function() G.FUNCS.continue_unlock() end)
 step('unlock_all_no_flood',function()
  G.FUNCS.profile_select();G.FUNCS.unlock_all{config={}}
  if not G.PROFILES[2].all_unlocked then G.FUNCS.unlock_all{config={}} end
  assert(#U.profile().pending_notifications==0 and PortraitCollection.count('mutations').tally==79)
  G.FUNCS.exit_overlay_menu();unlock_notify()
 end)
 step('no_unlock_all_notice',function()
  assert(not G.OVERLAY_MENU);G.SETTINGS.profile=1
  assert(U.profile().seen_notifications.profitable_sale and U.profile().seen_notifications.rare_market)
  assert(not U.profile().unlocked.free_reroll)
  log('PASS actual restart, native unlock queue, Continue, no repeats, multiple profiles and Unlock All')
 end)
 for _,filter in ipairs({3,4,5,6,7}) do local value=filter
  step('collection_family_'..value,function()
   G.PROFILES[1].all_unlocked=true;require('portrait_unlocks').apply()
   PortraitCollection.filter=value;G.FUNCS.your_collection_jokers()
  end,3)
 end
 step('spanish_modifier_collection',function()
  G.FUNCS.exit_overlay_menu();G.SETTINGS.language='es_ES';G:set_language();M.mod.process_loc_text();init_localization()
  assert(localize('k_dm_free_reroll')=='Reroll Gratis');PortraitCollection.open('mutations',10)
 end,3)
 step('done',function() log('PASS Collection families and ES presentation');love.event.quit() end)
end
local update,draw=love.update,love.draw;local i,t,pending=0,0
function love.update(dt)
 update(dt);t=t+dt
 if t<(i==0 and 4 or steps[i].delay) then return end
 if i>0 then log('PASS '..steps[i].name) end
 i=i+1;t=0;if steps[i] then steps[i].fn();pending=steps[i].name end
end
function love.draw()
 draw();if pending and t>0.5 then local name=pending;pending=nil;love.graphics.captureScreenshot(function(img)
  local f=assert(io.open(QA.out..'/'..name..'.png','wb'));f:write(img:encode('png'):getString());f:close() end) end
end

