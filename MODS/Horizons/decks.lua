return function(H)
 local D={};H.decks=D
 local X,P=H.X,H.P
 local function state() local s=H.state();if s then s.decks=s.decks or {};return s.decks end end
 function D.active(id)
  return G.STAGE==G.STAGES.RUN and G.GAME and G.GAME.selected_back and
   G.GAME.selected_back.effect.center.key==H.key(id)
 end
 local descriptions={
  DK01={'Empiezas con {C:attention}6{} espacios de Joker.','En cada ciega jugada se alternan los','Jokers de posiciones {C:attention}impares/pares{} activos.'},
  DK02={'Tu dinero pasa a {C:money}$20{} al entrar','en la tienda y a {C:money}$0{} al salir.'},
  DK03={'Juega las tres ciegas de cada Ante','en {C:attention}cualquier orden{}.','No puedes saltarlas.'},
  DK04={'Las cartas puntuantes suben {C:attention}1 rango{}','tras cada mano; las descartadas bajan {C:attention}1{}.','Los rangos circulan entre As y 2.'}}
 local english={
  DK01={'Start with {C:attention}6{} Joker slots.','{C:attention}Odd/even{} Joker positions alternate','being active each played Blind.'},
  DK02={'Money becomes {C:money}$20{} on entering','the shop and {C:money}$0{} on leaving.'},
  DK03={'Play all three Blinds of each Ante','in {C:attention}any order{}.','Blinds cannot be skipped.'},
  DK04={'Scoring cards gain {C:attention}1 rank{} after','each hand; discarded cards lose {C:attention}1{}.','Ranks wrap between Ace and 2.'}}
 local unlocks={DK01='Win a run ending the Ante 6, 7 and 8 Bosses with at least six Jokers.',DK02='Win a run spending at least $180, ending every Boss with $5 or less.',DK03='Win a run without skips and with at least four different Boss-winning hand types.',DK04='Win a run after changing at least eight distinct playing cards with Strength.'}
 for _,id in ipairs({'DK01','DK02','DK03','DK04'}) do
  local d=H.meta[id];d.unlock_en=unlocks[id];d.effect_en=table.concat(english[id],' '):gsub('{.-}','')
  SMODS.Back(H.decorate({key=d.key:gsub('^b_hz_',''),atlas=H.atlas(d.key..'_art','decks/'..id..'.png'),pos={x=0,y=0},
   config=id=='DK01' and {joker_slot=1} or {},unlocked=false,discovered=false,
   loc_txt={['es_ES']={name=d.name,text=descriptions[id]},['es_419']={name=d.name,text=descriptions[id]},['en-us']={name=d.name_en,text=english[id]}},
   apply=function() end},id))
 end
 function D.closes_ante()
  if not D.active('DK03') then return G.GAME.blind:get_type()=='Boss' end
  local current=G.GAME.blind:get_type()
  for _,slot in ipairs({'Small','Big','Boss'}) do
   if slot~=current and G.GAME.round_resets.blind_states[slot]~='Defeated' then return false end
  end
  return true
 end
 function D.is_winning_round()
  return G.GAME.round_resets.ante==G.GAME.win_ante and D.closes_ante()
 end
 function D.close_ante()
  local s=state();if not s then return end
  s.closed_ante=G.GAME.round_resets.ante
  X.track{hz_ante_closed=true,ante=s.closed_ante}
 end
 function D.finish_round()
  if not D.active('DK03') then return false end
  local s=state();local slot=G.GAME.blind:get_type()
  G.GAME.round_resets.blind_states[slot]='Defeated'
  if s and s.closed_ante and s.cleaned_ante~=s.closed_ante then
   s.cleaned_ante=s.closed_ante
   G.GAME.current_round.voucher=get_next_voucher_key()
   for _,c in ipairs(G.playing_cards) do c.ability.played_this_ante=nil end
  end
  return true
 end
 local function relay(card)
  local s=state();if not s or not card or card.ability.set~='Joker' then return end
  local disabled=false
  if D.active('DK01') and G.GAME.facing_blind and s.relay then
   local id=X.id(card)
   if s.relay[id]==nil then
    for i,c in ipairs(G.jokers.cards) do if c==card then s.relay[id]=i%2==s.parity;break end end
   end
   disabled=s.relay[id]==false
  end
  if (card.ability.debuff_sources or {}).hz_relay~=(disabled or nil) then SMODS.debuff_card(card,disabled or nil,'hz_relay') end
 end
 function D.relay_start()
  if not D.active('DK01') then return end
  local s=state();local token=P.token();if not s or s.relay_token==token then return end
  s.relay_token=token;s.parity=s.parity==1 and 0 or 1;s.relay={}
  for i,c in ipairs(G.jokers.cards) do s.relay[X.id(c)]=i%2==s.parity end
  for _,c in ipairs(G.jokers.cards) do relay(c) end
 end
 local ranks={'2','3','4','5','6','7','8','9','10','Jack','Queen','King','Ace'}
 local function tide_family(card)
  return X.mutations and X.mutations.has('M08') and card.ability.exp48_lineage or X.id(card)
 end
 local function tide(cards,delta)
  local groups,targets={},{}
  for _,c in ipairs(cards) do
   if c.playing_card and not c.removed and not SMODS.has_no_rank(c) then
    local family=tide_family(c)
    if not groups[family] then
     groups[family]=true;targets[#targets+1]={card=c,rank=ranks[((c.base.id-2+delta)%13)+1]}
    end
   end
  end
  for _,entry in ipairs(targets) do SMODS.change_base(entry.card,nil,entry.rank) end
 end
 function D.after_hand()
  local s=state();if not s then return end
  if D.active('DK04') and s.tides then
   local cards={};for _,id in ipairs(s.tides) do local c=X.find(id);if c then cards[#cards+1]=c end end
   s.tides=nil;tide(cards,1)
  end
  if H.challenges then H.challenges.after_hand() end
 end
 H.on(function(c)
  local s=state();if not s then return end
  if c.after and P.real(c) and D.active('DK04') then
   s.tides={};local seen={}
   for _,card in ipairs(c.scoring_hand or {}) do local id=X.id(card);if not seen[id] then seen[id]=true;s.tides[#s.tides+1]=id end end
  end
  if c.pre_discard and P.real(c) then s.discard_seen={} end
  if c.discard and c.other_card and P.real(c) and D.active('DK04') then
   s.discard_seen=s.discard_seen or {};local id=tide_family(c.other_card)
   if not s.discard_seen[id] and c.other_card.area~=G.play then s.discard_seen[id]=true;tide({c.other_card},-1) end
  end
  if c.ending_shop and P.real(c) and D.active('DK02') then D.allowance(0) end
 end)
 function D.allowance(amount)
  -- Allocation/expiry is not a purchase and must not satisfy spend Contracts.
  local calculating=SMODS.ease_dollars_calc;SMODS.ease_dollars_calc=true
  ease_dollars(amount-G.GAME.dollars,true);SMODS.ease_dollars_calc=calculating
 end
 local ready=P.shop_ready
 function P.shop_ready(...)
  local r=ready(...)
  if D.active('DK02') and P.normal_shop() then
   local s=state();local visit=H.rewardUI and H.rewardUI.state() and H.rewardUI.state().visit or tostring(G.GAME.round)
   if s and s.shop_visit~=visit then s.shop_visit=visit;D.allowance(20);save_run() end
  end
  return r
 end
 local reset=reset_blinds
 function reset_blinds(...)
  if D.active('DK03') then
   local bs=G.GAME.round_resets.blind_states
   if bs and not (bs.Small=='Defeated' and bs.Big=='Defeated' and bs.Boss=='Defeated') then return end
  end
  return reset(...)
 end
 local set=Blind.set_blind
 function Blind:set_blind(blind,reset,silent,...)
  local r=set(self,blind,reset,silent,...)
  if blind and not reset then D.relay_start() end
  return r
 end
 local defeat=Blind.defeat
 function Blind:defeat(...)
  local r=defeat(self,...)
  if D.active('DK01') then for _,c in ipairs(G.jokers.cards) do SMODS.debuff_card(c,nil,'hz_relay') end end
  return r
 end
 local emplace=CardArea.emplace
 function CardArea:emplace(card,...)
  local r=emplace(self,card,...);if self==G.jokers then relay(card) end;return r
 end
 H.installers[#H.installers+1]=function()
  local select=G.FUNCS.select_blind
  G.FUNCS.select_blind=function(e,...)
   if D.active('DK03') then
    local choice=e.config.ref_table
    for _,slot in ipairs({'Small','Big','Boss'}) do
     if G.P_BLINDS[G.GAME.round_resets.blind_choices[slot]]==choice then
      if G.GAME.round_resets.blind_states[slot]=='Defeated' then return end
      G.GAME.blind_on_deck=slot;G.GAME.round_resets.blind_states[slot]='Select';break
     end
    end
   end
   return select(e,...)
  end
  local skip=G.FUNCS.skip_blind
  G.FUNCS.skip_blind=function(...) if D.active('DK03') then return end;return skip(...) end
  local handler=G.FUNCS.blind_choice_handler
  G.FUNCS.blind_choice_handler=function(e,...)
   if not D.active('DK03') or e.config.ref_table.run_info then return handler(e,...) end
   local slot=e.config.id;local previous=G.GAME.blind_on_deck
   local available=slot and G.GAME.round_resets.blind_states[slot]~='Defeated'
   if available then G.GAME.blind_on_deck=slot;G.GAME.round_resets.blind_states[slot]='Select' end
   local r=handler(e,...);G.GAME.blind_on_deck=previous
   local tag=e.UIBox:get_UIE_by_ID('tag_container');if tag then tag.states.visible=false end
   local node=e.UIBox:get_UIE_by_ID('portrait_blind_token')
   if node and available then
    local sprite=node.config.object;sprite.states.click.can=true
    sprite.click=function(self)
     if G.STATE~=G.STATES.BLIND_SELECT or G.GAME.facing_blind then return end
     G.GAME.blind_on_deck=slot;self:stop_hover();self.UIBox=G.blind_select_opts[slot:lower()];UIElement.click(self)
    end
   end
   return r
  end
 end
 assert(SMODS.load_file('challenge_deck_missions.lua'))()(H)
end
