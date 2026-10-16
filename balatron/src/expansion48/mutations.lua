-- Optional rules keep their debts, selections and receipts in the run snapshot.
return function(P,M,R,definitions)
 local X=PortraitExpansion48;local A={};X.mutations=A
 local T=X.text
 function A.state()
  local s=X.state();if not s then return end
  s.mutations=s.mutations or {version=1,shop=0,blacklist={},tags={},enhancement_choices={}}
  return s.mutations
 end
 function A.has(id) return X.mutation(id) end
 function A.safe() return G.STATE==G.STATES.SELECTING_HAND and not G.GAME.PACK_INTERRUPT and not G.booster_pack and not G.CONTROLLER.locked end
 function A.save() X.checkpoint() end
 function A.label(card)
  if card.playing_card then
   local label=localize(card.base.value,'ranks')..' '..localize(card.base.suit,'suits_plural')
   if card.config.center.set=='Enhanced' then label=label..' · '..localize{type='name_text',set='Enhanced',key=card.config.center.key} end
   if card.seal then label=label..' · '..localize{type='name_text',set='Other',key=card.seal:lower()..'_seal'} end
   if (card.ability.perma_bonus or 0)>0 then label=label..' (+'..card.ability.perma_bonus..')' end
   return label
  end
  return localize{type='name_text',set=card.ability.set,key=card.config.center.key}
 end
 function A.menu(title,rows,back)
  local nodes={P.text(title,0.45)}
  for _,v in ipairs(rows) do nodes[#nodes+1]=v end
  local scroll=require('portrait_run_scroll')(nodes,7,math.min(9,G.ROOM.T.h*0.57))
  G.SETTINGS.paused=true
  G.FUNCS.overlay_menu{definition=create_UIBox_generic_options{back_func=back or 'exp48_mutations',
   contents={{n=G.UIT.O,config={object=scroll}}}}}
 end
 function A.button(label,action,data)
  local labels=PortraitRunGallery and PortraitRunGallery.wrap({label},34) or {label}
  local node=UIBox_button{label=labels,button='exp48_mutation_action',minw=5.8,
   minh=portrait_touch_height(0.8)+math.max(0,#labels-1)*.24,scale=.32,colour=G.C.RED}
  local function bind(n)
   if n.config and n.config.button=='exp48_mutation_action' then n.config.ref_table={action=action,data=data} end
   for _,child in ipairs(n.nodes or {}) do bind(child) end
  end
  bind(node);return node
 end
 A.actions={}
 G.FUNCS.exp48_mutation_action=function(e)
  local ref=e.config.ref_table;local action=ref and A.actions[ref.action]
  if action then action(ref.data) end
 end
 function A.close() G.FUNCS.exit_overlay_menu();A.save() end
 function A.cards(title,cards,action,predicate)
  local rows={}
  for i,card in ipairs(cards or {}) do if not predicate or predicate(card) then
   rows[#rows+1]=A.button(tostring(i)..'. '..A.label(card),action,X.id(card))
  end end
  A.menu(title,rows)
 end
 function A.find(id)
  local c=X.find(id);if c then return c end
  for _,area in ipairs({G.jokers,G.consumeables,G.shop_jokers,G.shop_booster}) do
   for _,card in ipairs(area and area.cards or {}) do if X.id(card)==id then return card end end
  end
 end
 function A.afford(n) return (G.GAME.dollars or 0)-(G.GAME.bankrupt_at or 0)>=n end
 local old_shop=M.shop
 function M.shop()
  if old_shop then old_shop() end
  local s=A.state();local token=P.token()
  if s.shop_token~=token then s.shop_token=token;s.shop=s.shop+1;s.mortgaged_shop=nil;s.blacklisted_shop=nil end
 end
 require('expansion48.mutations_cards')(X,A,P,M,R)
 require('expansion48.mutations_shop')(X,A,P,M,R,definitions)
 require('expansion48.mutations_rewards')(X,A,P,M,R,definitions)
 function A.open()
  local s=A.state();if not s then return end
  local rows={}
  local function button(id,label,action,condition)
   if A.has(id) and condition~=false then rows[#rows+1]=A.button(T(label[1],label[2]),action) end
  end
  if s.enhancement_choices[1] then rows[#rows+1]=A.button(T('Elegir Enhancements','Choose Enhancements'),'enhancements') end
  if P.normal_shop() then
   button('M02',{'Mesa de trabajo','Workbench'},'workbench')
   button('M04',{'Hipotecar manos','Mortgage hands'},'mortgage',not s.mortgaged_shop)
   button('M11',{'Vetar Joker','Blacklist a Joker'},'blacklist',not s.blacklisted_shop)
   button('M12',{'Alquilar Joker','Rent a Joker'},'rent')
   button('M15',{'Fusion con sustituto ($6)','Fusion with substitute ($6)'},'spare_parts')
   button('M20',{'Guardar Booster Pack','Store a Booster Pack'},'takeaway',not s.takeaway)
  end
  if A.safe() or P.normal_shop() or G.STATE==G.STATES.BLIND_SELECT then
   if s.takeaway then rows[#rows+1]=A.button(T('Abrir pack guardado','Open stored pack'),'open_takeaway') end
   if #s.tags>0 then rows[#rows+1]=A.button(T('Consigna: liberar Tag','Left Luggage: release Tag'),'tags') end
  end
  if s.decanting then rows[#rows+1]=A.button(T('Trasvasar niveles','Transfer levels'),'decanting') end
  if s.molting then rows[#rows+1]=A.button(T('Mudar Mutation','Swap Mutation'),'molting') end
  if #rows==0 then rows[1]=P.text(T('No hay acciones disponibles','No actions available')) end
  A.menu(T('Acciones de Mutations','Mutation actions'),rows,'exit_overlay_menu')
 end
 G.FUNCS.exp48_mutations=A.open
 local run_panel=P.run_panel
 function P.run_panel(...)
  local node=run_panel(...)
  if A.state() then node.nodes[#node.nodes+1]=P.button(T('Acciones de Mutations','Mutation actions'),'exp48_mutations') end
  return node
 end
 local offer=M.offer
 function M.offer()
  local s=A.state()
  if s and s.enhancement_choices[1] then A.actions.enhancements();return true end
  if s and s.decanting and not s.decanting.shown then s.decanting.shown=true;A.actions.decanting();return true end
  if s and s.molting and not s.molting.shown then s.molting.shown=true;A.actions.molting();return true end
  return offer()
 end
 local required=M.required_offer
 function M.required_offer() local s=A.state();return s and s.enhancement_choices[1]~=nil or required() end
 local start=Game.start_run
 function Game:start_run(args,...)
  A.frozen_pack_active=nil;A.frozen_pack_dirty=nil;A.frozen_pack_source=nil;A.money_source=nil
  A.enhancement_queued=nil;A.in_scoring=nil
  local result=start(self,args,...)
  if A.state() then A.state().pack_preserve_hand=nil end
  if A.install then A.install() end
  if A.restore_workbench then A.restore_workbench() end
  if A.state() and A.state().enhancement_choices[1] then A.queue_enhancements() end
  return result
 end
end
