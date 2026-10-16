-- Presentation tokens never grant rewards, change RNG, or resume unfinished FX.
return function(H)
 local F=require('portrait_reward_fx');local X,P=H.X,H.P
 local runtime={}
 local function state()
  local s=H.state();if not s then return end
  s.feedback=s.feedback or {seen={}};return s.feedback
 end
 local function reset()
  runtime={game=G.GAME,profile=G.SETTINGS.profile,until_time=0,priority=0}
 end
 F.arbiter=function(kind,token,level,priority,details)
  if not H.enabled('feedback') then return math.min(level,2) end
  if runtime.game~=G.GAME or runtime.profile~=G.SETTINGS.profile then reset() end
  local s=state();local now=G.TIMERS.REAL;local key=kind..':'..tostring(token or '')
  if s and token and s.seen[key] then return 0 end
  if s and token then s.seen[key]=true end
  if s and kind=='record' and details and s.prior_record and s.prior_record>0 and
   details.amount>=10*s.prior_record and not s.record_peak then level=3;s.record_peak=true end
  if s and kind=='overkill' and details and details.category=='OBLITERATED' and not s.obliterated then
   level=3;s.obliterated=true
  end
  if s and kind=='evolution' and details and details.final and not details.forced and not s.final_upg then
   level=3;s.final_upg=true
  end
  if level>=3 and s then
   local blind=P.token()
   if s.level3_blind==blind then level=2 else s.level3_blind=blind end
  end
  if now<(runtime.until_time or 0) and priority<=(runtime.priority or 0) then return 1 end
  if level>=2 then runtime.until_time=now+PortraitQOL.duration(1.5);runtime.priority=priority end
  return level
 end
 H.on(function(c)
  if c.initial_scoring_step then
   local s=state();if s and s.prior_record==nil then
    local r=PortraitQOL.records();s.prior_record=r.hand and r.hand.amt or 0
   end
  end
 end)
 function H.feedback(card,kind,token,level,title,priority,details)
  local admitted=F.admit(kind,token,level,priority or 50,details)
  F.milestone(card,title,{admitted=admitted,colour=G.C.GOLD})
  return admitted
 end
 H.installers[#H.installers+1]=function()
  local begin=P.begin_run
  function P.begin_run(...) reset();return begin(...) end
  local won=win_game
  function win_game(...)
   local id=G.GAME.challenge;local profile=G.PROFILES[G.SETTINGS.profile]
   local first=id and not profile.challenge_progress.completed[id]
   local r=won(...)
   if first then
    local game=G.GAME;local started=G.TIMERS.REAL
    G.E_MANAGER:add_event(Event{blocking=false,blockable=false,pause_force=true,timer='REAL',func=function()
     if G.GAME~=game or G.TIMERS.REAL-started>4 then return true end
     if not G.OVERLAY_MENU or not G.OVERLAY_MENU:get_UIE_by_ID('jimbo_spot') then return false end
     H.feedback(G.OVERLAY_MENU,'challenge',id,3,H.text('RETO COMPLETADO','CHALLENGE COMPLETE'),100)
     return true
    end})
   end
   return r
  end
  local defeat=Blind.defeat
  function Blind:defeat(...)
   local id=self.config.blind.horizons;local token=P.token()
   if id and id:sub(1,2)=='BS' and G.GAME.chips>=self.chips then
    H.feedback(self.children.animatedSprite,'boss',token,2,nil,40)
   end
   return defeat(self,...)
  end
  local notice=X.notice_shown
  X.notice_shown=function(id,box)
   if notice then notice(id,box) end
   local d=H.meta[id]
   if d then H.feedback(box,'unlock',tostring(G.SETTINGS.profile)..':'..id,d.category=='decks' and 3 or 2,nil,85) end
  end
  local add=Card.add_to_deck
  function Card:add_to_deck(from_debuff,...)
   local fresh=not self.added_to_deck and not from_debuff
   local rarity=self.config.center.rarity
   local r=add(self,from_debuff,...)
   if fresh and (rarity==4 or rarity=='Legendary') and not G.pg_roulette_area then
    local game,started=G.GAME,G.TIMERS.REAL;local card=self
    G.E_MANAGER:add_event(Event{blocking=false,blockable=false,timer='REAL',func=function()
     if game~=G.GAME or card.removed or G.TIMERS.REAL-started>3 then return true end
     if card.area~=G.jokers or G.OVERLAY_MENU then return false end
     local s=state();if not s then return true end
     local ante=G.GAME.round_resets.ante;local level=s.premium_ante==ante and 2 or 3;s.premium_ante=ante
     F.milestone(card,localize('k_legendary'),{kind='premium',token=X.id(card),level=level,priority=90,sound='timpani',haptic='fusion'})
     return true
    end})
   end
   return r
  end
 end
end
