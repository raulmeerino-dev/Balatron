-- Native Blind instances own all temporary effects; profile missions own only receipts.
return function(H)
 local X,P=H.X,H.P
 local B={};H.bosses=B
 local definitions={
  {'BS01','broom','65877B',2,{'Cada descarte descarta','toda tu mano'},{'Every discard discards','your entire hand'},'Defeat five different Boss Blinds.'},
  {'BS02','comb','506D91',3,{'Las cartas jugadas puntúan','de menor a mayor rango'},{'Played cards score','from lowest to highest rank'},'Win an Ante 6+ Boss with at least four scoring cards in its winning hand.'},
  {'BS03','mute','785475',4,{'Las cartas jugables','no pueden repetirse'},{'Playing cards','cannot retrigger'},'Win a Boss by retriggering the same card at least four times in its winning hand.'},
  {'BS04','lacquer','B09C81',3,{'Las ediciones no aportan','fichas ni Mult'},{'Editions give no','Chips or Mult'},'Own Foil, Holographic and Polychrome simultaneously and win an Ante 4+ Boss.'},
  {'BS05','vault','975E3B',4,{'Aparta tu dinero al entrar','Lo recuperas al ganar: $#1#'},{'Your money is held in custody','Returned on victory: $#1#'},'Defeat an Ante 4+ Boss with at least $75.'},
  {'BS06','hinge','875C7D',3,{'Los Dobles alternan tras cada mano','No puedes cambiar su modo'},{'Doubles alternate after each hand','You cannot switch their modes'},'Win a run after using both modes of the same Double during a Boss Blind.'},
 }
 local function state()
  local s=H.state();if not s then return end
  s.bosses=s.bosses or {modes={},activations={}}
  return s.bosses
 end
 local function double(card)
  return card and card.config and card.config.center and card.ability and
   card.config.center.portrait_family=='doubles' and type(card.ability.extra)=='table'
 end
 function B.active(id)
  local blind=G.GAME and G.GAME.blind
  return G.STAGE==G.STAGES.RUN and blind and not blind.disabled and
   blind.config and blind.config.blind and blind.config.blind.key==H.key(id) and G.GAME.facing_blind
 end
 local function bank()
  local blind=G.GAME and G.GAME.blind
  if not blind then return end
  blind.effect=blind.effect or {};return blind.effect
 end
 local function refresh_money()
  G.GAME.dollar_buffer=G.GAME.dollar_buffer or 0
  local node=G.HUD and G.HUD:get_UIE_by_ID('dollar_text_UI')
  if node and node.config.object then node.config.object:update_text() end
 end
 function B.restore_vault()
  local blind=G.GAME and G.GAME.blind
  if not blind or not blind.config or not blind.config.blind or blind.config.blind.key~=H.key('BS05') then return end
  local s=bank();if s.hz_vault_restored then return end
  s.hz_vault_restored=true
  G.GAME.dollars=(G.GAME.dollars or 0)+(s.hz_deposit or 0)
  refresh_money() -- Restoration is not income, interest, an ability or a reward.
 end
 for _,d in ipairs(definitions) do
  local id,key,colour,minimum,es,en,unlock=unpack(d)
  H.meta[id].unlock_en=unlock
  H.meta[id].effect_en=id=='BS05' and 'Your positive balance is held on entry and returned on victory or when the Blind is disabled.' or table.concat(en,' ')
  local loc={['en-us']={name=H.meta[id].name_en,text=en},es_ES={name=H.meta[id].name,text=es},es_419={name=H.meta[id].name,text=es}}
  SMODS.Blind{key=key,horizons=id,unlocked=false,discovered=false,
   atlas=H.atlas('boss_'..key,'bosses/'..key..'.png',34,34),pos={x=0,y=0},
   boss={min=minimum,max=10},boss_colour=HEX(colour),mult=2,dollars=5,loc_txt=loc,
   in_pool=function(self)
    if not H.enabled('bosses',id) or not H.unlocked(id) or
     (G.GAME.round_resets.ante or 0)<minimum then return false end
    if id=='BS06' then
     if not IncJoker or not IncJoker.family_enabled(G.GAME.incj_config,'doubles') then return false end
     for _,card in ipairs(G.jokers and G.jokers.cards or {}) do if double(card) then return true end end
     return false
    end
    return true
   end,
   set_blind=function()
    if id=='BS05' then
     local s=bank()
     if not s.hz_deposit then
      s.hz_deposit=math.max(0,G.GAME.dollars or 0);G.GAME.dollars=G.GAME.dollars-s.hz_deposit
      refresh_money();G.GAME.blind:set_text()
     end
    end
   end,
   disable=function() if id=='BS05' then B.restore_vault() end end,
   defeat=function() if id=='BS05' then B.restore_vault() end end,
   loc_vars=function()
    local s=bank();return {vars={s and s.hz_deposit or 0}}
   end,
   collection_loc_vars=function() return {vars={0}} end,
  }
 end
 H.meta.BS01.profile_unlock=true
 local function profile_state()
  local p=X.profile();if not p then return end
  p.horizons=p.horizons or {};p.horizons.defeated_bosses=p.horizons.defeated_bosses or {}
  return p.horizons.defeated_bosses
 end
 H.on_profile(function()
  local p=profile_state();if not p then return end
  -- Native Blind discovery happens on victory, so existing legitimate profiles count.
  for key,def in pairs(G.P_BLINDS) do if def.boss and def.discovered and not def.horizons then p[key]=true end end
  if X.count(p)>=5 then H.unlock('BS01',true) end
 end)
 H.on(function(c)
  local s=state();if not s then return end
  if c.setting_blind then s.modes={};s.activations={};s.hand_token=nil;s.scoring_count=0 end
  if c.initial_scoring_step and P.real(c) then
   s.activations={};s.scoring_count=#(c.scoring_hand or {})
   for _,card in ipairs(G.jokers.cards) do if double(card) and not card.debuff then
    local id=X.id(card);s.modes[id]=s.modes[id] or {};s.modes[id][card.ability.extra.selected=='B' and 'B' or 'A']=true
   end end
  end
  if c.exp48_score_card then
   local id=X.id(c.card);s.activations[id]=(s.activations[id] or 0)+1
  end
  if P.won(c) and c.beat_boss and H.once('boss_mission:'..P.token()) then
   if not G.GAME.seeded and not G.GAME.challenge then
    profile_state()[G.GAME.blind.config.blind.key]=true;X.persist()
   end
   local ante=G.GAME.round_resets.ante
   if ante>=6 and s.scoring_count>=4 then H.unlock('BS02') end
   for _,n in pairs(s.activations) do if n>=5 then H.unlock('BS03') end end
   local editions={}
   for _,list in ipairs({G.playing_cards or {},G.jokers.cards,G.consumeables.cards}) do
    for _,card in ipairs(list) do
     for _,e in ipairs({'foil','holo','polychrome'}) do if card.edition and card.edition[e] then editions[e]=true end end
    end
   end
   if ante>=4 and editions.foil and editions.holo and editions.polychrome then H.unlock('BS04') end
   if ante>=4 and G.GAME.dollars>=75 then H.unlock('BS05') end
   for _,modes in pairs(s.modes) do if modes.A and modes.B then s.double_boss=true end end
  end
 end)
 H.installers[#H.installers+1]=function()
  local evaluate_card=eval_card
  function eval_card(card,context,...)
   -- The shared event counts played activations; held activations also qualify.
   if context.main_scoring and context.cardarea==G.hand and card.playing_card and not card.debuff and
    not context.extra_enhancement and not SMODS.extra_enhancement_calc_in_progress then
    local s=state();if s then local id=X.id(card);s.activations[id]=(s.activations[id] or 0)+1 end
   end
   return evaluate_card(card,context,...)
  end
  local discard=G.FUNCS.discard_cards_from_highlighted
  G.FUNCS.discard_cards_from_highlighted=function(e,hook,...)
   if B.active('BS01') and not hook and G.GAME.current_round.discards_left>0 and #G.hand.highlighted>0 then
    local list={}
    for _,card in ipairs(G.hand.cards) do
     if not card.removed and not card.getting_sliced and not card.ability.x48_pin then list[#list+1]=card;card.highlighted=true end
    end
    G.hand.highlighted=list
   end
   return discard(e,hook,...)
  end
  local can_discard=G.FUNCS.can_discard
  G.FUNCS.can_discard=function(e,...)
   local r=can_discard(e,...)
   B.preview_broom=B.active('BS01') and e.config.button and
    ((e.states.hover and e.states.hover.is) or (e.states.focus and e.states.focus.is))
   local label=localize('b_discard')
   if B.active('BS01') then
    local n=0;for _,card in ipairs(G.hand.cards) do if not card.ability.x48_pin then n=n+1 end end
    label=H.text('Todas','All')..' ('..n..')'
   end
   local function update(node)
    if node.config and node.config.func=='set_button_pip' and node.config.text~=label then
     node.config.text=label;node:update_text()
     if node.config.text_drawable then node.config.text_drawable:set(label) end
     if node.UIBox then node.UIBox:recalculate() end
    end
    for _,child in pairs(node.children or {}) do update(child) end
   end
   update(e);return r
  end
  local align=CardArea.align_cards
  function CardArea:align_cards(...)
   if self~=G.hand or not B.preview_broom or not B.active('BS01') then return align(self,...) end
   -- Preview the discard's actual reach without changing selected identities.
   local old={}
   for i,card in ipairs(self.cards) do old[i]=card.highlighted;card.highlighted=not card.ability.x48_pin end
   local r=align(self,...)
   for i,card in ipairs(self.cards) do card.highlighted=old[i] end
   return r
  end
  local scoring=SMODS.calculate_main_scoring
  function SMODS.calculate_main_scoring(context,scoring_hand)
   if not B.active('BS02') or context.cardarea~=G.play or not scoring_hand then return scoring(context,scoring_hand) end
   local physical,previous=G.play.cards,context.scoring_hand
   local order,positions={},{}
   for i,card in ipairs(physical) do order[i]=card;positions[card]=i end
   local function less(a,b)
    local ar=SMODS.has_no_rank(a) and math.huge or a:get_id()
    local br=SMODS.has_no_rank(b) and math.huge or b:get_id()
    return ar==br and positions[a]<positions[b] or ar<br
   end
   table.sort(order,less)
   local scored={};for _,card in ipairs(order) do if SMODS.in_scoring(card,scoring_hand) then scored[#scored+1]=card end end
   G.play.cards=order;context.scoring_hand=scored
   local result=scoring(context,scored)
   G.play.cards=physical;context.scoring_hand=previous
   return result
  end
  local repetitions=SMODS.calculate_repetitions
  function SMODS.calculate_repetitions(card,context,reps)
   -- Stop discovery before its callbacks can report/redirect nonexistent repeats.
   if B.active('BS03') and card and card.playing_card then
    for i=#reps,2,-1 do reps[i]=nil end
    return
   end
   return repetitions(card,context,reps)
  end
  local scoring_keys={chips=true,chip_mod=true,h_chips=true,p_chips=true,mult=true,mult_mod=true,h_mult=true,
   x_chips=true,xchips=true,xchip_mod=true,Xchip_mod=true,x_mult=true,xmult=true,Xmult_mod=true,xmult_mod=true,
   h_x_mult=true,p_mult=true,p_x_mult=true,Xmult=true,x_mult_mod=true}
  for _,method in ipairs({'calculate_edition','get_edition'}) do
   local native=Card[method]
   if native then Card[method]=function(card,...)
    local result=native(card,...)
    if result and B.active('BS04') then
     local filtered={};for key,value in pairs(result) do filtered[key]=value end;result=filtered
     for key in pairs(result) do if scoring_keys[key] then result[key]=nil end end
    end
    return result
   end end
  end
  local evaluate=G.FUNCS.evaluate_round
  G.FUNCS.evaluate_round=function(...)
   -- Native end-of-round card/Rental charges precede this; interest follows it.
   -- ROUND_EVAL clears facing_blind before calling this function.
   if G.GAME.blind and G.GAME.chips>=G.GAME.blind.chips then B.restore_vault() end
   return evaluate(...)
  end
  if IncJoker and IncJoker.options and IncJoker.options.can_switch then
   local switch=IncJoker.options.can_switch
   IncJoker.options.can_switch=function(card,...) if B.active('BS06') then return false end;return switch(card,...) end
  end
  local finish=G.FUNCS.draw_from_play_to_discard
  G.FUNCS.draw_from_play_to_discard=function(...)
   if IncJoker and IncJoker.options and B.active('BS06') and H.once('hinge:'..P.token()..':'..G.GAME.hands_played) then
    for _,card in ipairs(G.jokers.cards) do if double(card) then
     card.ability.extra.selected=card.ability.extra.selected=='B' and 'A' or 'B';IncJoker.options.sync(card)
     if not G.SETTINGS.reduced_motion then card:juice_up(.1,.02) end
    end end
   end
   return finish(...)
  end
  local win=win_game
  function win_game(...)
   local s=state();if s and s.double_boss then H.unlock('BS06') end
   return win(...)
  end
 end
end
