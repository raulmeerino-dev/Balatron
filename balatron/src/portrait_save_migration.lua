-- One-way, in-memory adaptation of pre-Steamodded portrait runs. The original
-- compressed checkpoint is backed up before the next normal save replaces it.
local M={}
local function fill(target,defaults)
    for k,v in pairs(defaults) do
        if target[k]==nil then target[k]=type(v)=='table' and copy_table(v) or v
        elseif type(target[k])=='table' and type(v)=='table' then fill(target[k],v) end
    end
end
function M.convert(saved,defaults)
    if not saved or saved.SCORING_CALC then return saved end
    saved=copy_table(saved)
    fill(saved.GAME,defaults)
    saved.SCORING_CALC={key='multiply',config={}}
    local voucher=saved.GAME.current_round.voucher
    if type(voucher)~='table' then
        saved.GAME.current_round.voucher={spawn={}}
        if voucher then
            saved.GAME.current_round.voucher[1]=voucher
            saved.GAME.current_round.voucher.spawn[voucher]=true
        end
    end
    local free=0
    for name,area in pairs(saved.cardAreas) do
        local extra=0
        for _,card in ipairs(area.cards) do
            card._portrait_legacy=true
            local edition=card.edition
            if edition then
                edition.key=edition.key or 'e_'..edition.type
                local center=G.P_CENTERS[edition.key]
                if center then fill(edition,center.config) end
            end
            card.ability.card_limit=edition and edition.card_limit or 0
            card.ability.extra_slots_used=0
            extra=extra+card.ability.card_limit
            if name=='jokers' and card.save_fields.center=='j_chaos' and not card.debuff then free=free+1 end
            if name=='shop_vouchers' then card.shop_voucher=true end
        end
        local config=area.config
        if not config.card_limits then
            local limit=config.card_limit or #area.cards
            local handled=(config.type=='joker' or config.type=='hand') and not config.fixed_limit
            extra=handled and extra or 0
            config.card_limits={base=limit-extra,mod=0,extra_slots=extra,extra_slots_used=0,total_slots=limit,old_slots=limit}
            config.card_limit=nil
        end
    end
    saved.GAME.round_resets.free_rerolls=free
    return saved
end
function M.install()
    local start_run=Game.start_run
    function Game:start_run(args)
        if args and args.savetext and not args.savetext.SCORING_CALC then
            local profile=tostring(G.SETTINGS.profile)
            local backup=profile..'/save.pre-steamodded.jkr'
            if not love.filesystem.getInfo(backup) then
                local original=love.filesystem.read(profile..'/save.jkr')
                if original then assert(love.filesystem.write(backup,original)) end
            end
            args.savetext=M.convert(args.savetext,self:init_game_object())
        end
        return start_run(self,args)
    end
    local load_card=Card.load
    function Card:load(saved,...)
        if saved._portrait_legacy then
            fill(saved.ability,self.ability)
            saved._portrait_legacy=nil
        end
        return load_card(self,saved,...)
    end
end
return M
