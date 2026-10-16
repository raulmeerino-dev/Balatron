-- Recolour only the existing SPLASH_BACK colour uniforms. No shader, texture,
-- render target, pattern, timer, contrast or shared G.C colour is replaced.
local M={elapsed=0,tint={80/255,132/255,110/255},
    colours={colour_1={0,0,0,1},colour_2={0,0,0,1},colour_3={0,0,0,1}}}
local green={80/255,132/255,110/255} -- Original G.C.BLIND.Small (50846e).
local function luma(c) return .2126*c[1]+.7152*c[2]+.0722*c[3] end
local level=luma(green)
local function prepare(config)
    if M.palette_source==config.background_palette then return end
    M.palette_source=config.background_palette
    M.palette={}
    for index,colour in ipairs(M.palette_source) do
        local scale=level/luma(colour)
        local out={colour[1]*scale,colour[2]*scale,colour[3]*scale}
        M.palette[index]=out
    end
    assert(#M.palette>=2,'Background palette needs at least two colours')
end
function M.sample(phase,config,enabled)
    prepare(config)
    if not enabled then
        for i=1,3 do M.tint[i]=green[i] end
        return M.tint
    end
    local position=(phase%1)*#M.palette
    local index=math.floor(position)
    local t=position-index
    t=t*t*(3-2*t) -- zero slope at both ends, including the wrap to green.
    local a,b=M.palette[index+1],M.palette[(index+1)%#M.palette+1]
    for i=1,3 do M.tint[i]=a[i]+(b[i]-a[i])*t end
    return M.tint
end
function M.update(dt,settings,config)
    local enabled=settings.animated_background
    if enabled==nil then enabled=config.background_animated_default end
    if not enabled then M.elapsed=0
    elseif not settings.reduced_motion then
        M.elapsed=(M.elapsed+math.min(math.max(dt,0),config.background_max_frame_seconds))%config.background_cycle_seconds
    end
    M.sample(M.elapsed/config.background_cycle_seconds,config,enabled)
end
function M.colour(name,source)
    local out=M.colours[name]
    if not out then return source end
    local y=luma(source)
    -- Keep each original tone's luma. Compress chroma near white rather than
    -- clipping RGB; this also preserves the original splash highlight/flash.
    -- Limit the current tint only: a vivid blue/red elsewhere in the cycle
    -- must not flatten the greens or the quieter intervals.
    local max_chroma=math.max(M.tint[1],M.tint[2],M.tint[3])-level
    local chroma=y/level
    if max_chroma>0 then chroma=math.min(chroma,(1-y)/max_chroma) end
    for i=1,3 do out[i]=y+chroma*(M.tint[i]-level) end
    out[4]=source[4]
    return out
end
function M.for_uniform(sprite,shader,name,source)
    if sprite~=G.SPLASH_BACK or (shader~='background' and shader~='splash') then return source end
    return M.colour(name,source)
end
return M
