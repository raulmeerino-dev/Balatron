return function(H)
 local X,P=H.X,H.P;local M={};H.challenge_deck_missions=M
 local function state() local s=H.state();if s then s.challenge_deck_missions=s.challenge_deck_missions or {fusion={},destroyed={},contracts={},families={},strength={},bosses={},boss_hands={},greed_bosses={},relay={}};return s.challenge_deck_missions end end
 local function valid() return G.STAGE==G.STAGES.RUN and G.GAME and not G.GAME.seeded and not G.GAME.challenge end
 local begin=P.begin_run
 function P.begin_run(loading,...)
  local r=begin(loading,...);local s=state()
  if s and not loading then s.history_complete=true end
  return r
 end
 local function owned(key) for _,c in ipairs(G.jokers.cards) do if c.config.center.key==key then return true end end;return false end
 function M.after_hand()
  local s=state();if not s or not valid() then return end
  if G.GAME.blind:get_type()=='Boss' and G.GAME.dollars<0 then s.greed_debt=true end
 end
 H.on(function(c)
  local s=state();if not s or not valid() or not P.real(c) then return end
  if c.setting_blind then s.greed_debt=false end
  if c.after then s.last_hand=c.scoring_name end
  if c.skip_blind then s.skipped=true end
  if c.remove_playing_cards then for _,card in ipairs(c.removed or {}) do s.destroyed[X.id(card)]=true end end
  if c.using_consumeable then
   local card=c.consumeable or c.card
   if card then s.consumables=(s.consumables or 0)+1;s.families[card.ability.set]=true end
  end
  if c.exp48_contract_result and c.success and G.GAME.round_resets.ante<=6 then s.contracts[c.contract.id]=true end
  if c.exp48_tarot_resolved and c.key=='c_strength' then
   for id,old in pairs(c.before or {}) do local card=X.find(id);if card and card.base.id~=old.rank then s.strength[id]=true end end
  end
  if c.money_altered and c.from_shop and c.amount<0 then s.spent=(s.spent or 0)-c.amount end
  if P.won(c) and G.GAME.blind:get_type()=='Boss' and H.once('hz_mission_boss_'..P.token()) then
   local ante=G.GAME.round_resets.ante
   s.bosses[G.GAME.blind.config.blind.key]=true
   if s.last_hand then s.boss_hands[s.last_hand]=true end
   s.greed_bosses[#s.greed_bosses+1]=owned('j_risk_greed') and not s.greed_debt
   if #s.greed_bosses>3 then table.remove(s.greed_bosses,1) end
   if ante>=6 and ante<=8 then s.relay[ante]=#G.jokers.cards>=6 end
  end
  if c.exp48_blind_paid and G.GAME.blind:get_type()=='Boss' then
   local game=G.GAME
   G.E_MANAGER:add_event(Event{func=function() if G.GAME==game and G.GAME.dollars>5 then s.rich_boss=true end;return true end})
  end
 end)
 local add=Card.add_to_deck
 function Card:add_to_deck(from_debuff,...)
  if not from_debuff and not self.added_to_deck and valid() and self.ability.set=='Joker' and G.GAME.round_resets.ante>=6 then
   local s=state();if s then s.late_joker=true end
  end
  return add(self,from_debuff,...)
 end
 local disable=Blind.disable
 function Blind:disable(...)
  local s=state();if s and valid() and self:get_type()=='Boss' and not self.disabled then s.changed_boss=true end
  return disable(self,...)
 end
 H.installers[#H.installers+1]=function()
  local F=PortraitFusion
  if F then local fuse=F.fuse
   function F.fuse(selection,...)
    local result=fuse(selection,...);local s=state()
    if result and s and valid() then s.fusion[selection.id]=true end
    return result
   end
  end
  local reroll=G.FUNCS.reroll_boss
  G.FUNCS.reroll_boss=function(...)
   local s=state();if s and valid() then s.changed_boss=true end;return reroll(...)
  end
  local win=win_game
  function win_game(...)
   local s=state()
   if s and valid() then
    if X.count(s.fusion)>=2 then H.unlock('CH01') end
    if #s.greed_bosses==3 and s.greed_bosses[1] and s.greed_bosses[2] and s.greed_bosses[3] then H.unlock('CH02') end
    if X.count(s.destroyed)>=15 and #G.playing_cards<=30 then H.unlock('CH03') end
    if X.count(s.contracts)>=4 then H.unlock('CH04') end
    if s.history_complete and not s.late_joker then H.unlock('CH05') end
    if (s.consumables or 0)>=12 and X.count(s.families)>=3 then H.unlock('CH06') end
    if s.history_complete and not s.changed_boss and X.count(s.bosses)>=6 then H.unlock('CH08') end
    if s.relay[6] and s.relay[7] and s.relay[8] then H.unlock('DK01') end
    if s.history_complete and (s.spent or 0)>=180 and not s.rich_boss then H.unlock('DK02') end
    if s.history_complete and not s.skipped and X.count(s.boss_hands)>=4 then H.unlock('DK03') end
    if X.count(s.strength)>=8 then H.unlock('DK04') end
   end
   return win(...)
  end
 end
 H.on_profile(function()
  local p=G.PROFILES[G.SETTINGS.profile]
  if p.challenge_progress and p.challenge_progress.completed and p.challenge_progress.completed.c_xray_1 then H.unlock('CH07',true) end
 end)
end
