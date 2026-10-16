dofile('src/portrait_config.lua')
local M=dofile('src/portrait_background.lua')
local cfg=PORTRAIT_CONFIG
local function y(c) return .2126*c[1]+.7152*c[2]+.0722*c[3] end
local function near(a,b,eps) assert(math.abs(a-b)<(eps or 1e-10),a..' ~= '..b) end
local settings={animated_background=true}
M.update(0,settings,cfg)
local first={M.tint[1],M.tint[2],M.tint[3]}
local source={.9*80/255,.9*132/255,.9*110/255,.8}
local out=M.colour('colour_1',source)
for i=1,4 do near(out[i],source[i]) end
local level=y(first)
for p=0,2400 do
    M.sample(p/2400,cfg,true)
    near(y(M.tint),level)
    for _,c in ipairs({source,{1,1,1,1},{0,0,0,.5},{.99,.2,.1,1},{.3,.7,.2,1}}) do
        local result=M.colour('colour_2',c)
        near(y(result),y(c)); near(result[4],c[4])
        for i=1,3 do assert(result[i]>=-1e-12 and result[i]<=1+1e-12) end
    end
end
for k=0,#cfg.background_palette do
    local left={unpack(M.sample(k/#cfg.background_palette-1e-7,cfg,true))}
    local right=M.sample(k/#cfg.background_palette+1e-7,cfg,true)
    for i=1,3 do near(left[i],right[i],1e-10) end
end
M.elapsed=0
for i=1,cfg.background_cycle_seconds*60 do M.update(1/60,settings,cfg) end
for i=1,3 do near(M.tint[i],first[i],1e-10) end
settings.animated_background=false
M.update(1000,settings,cfg); assert(M.elapsed==0)
for i=1,3 do near(M.tint[i],first[i]) end
settings.animated_background=true; settings.reduced_motion=true
M.update(1,settings,cfg); assert(M.elapsed==0)
settings.reduced_motion=false; M.update(1000,settings,cfg)
near(M.elapsed,cfg.background_max_frame_seconds)
G={SPLASH_BACK={}}
local foreground={}
assert(M.for_uniform(foreground,'background','colour_1',source)==source)
assert(M.for_uniform(G.SPLASH_BACK,'dissolve','colour_1',source)==source)
assert(M.for_uniform(G.SPLASH_BACK,'background','time',17)==17)
assert(M.for_uniform(G.SPLASH_BACK,'background','contrast',2)==2)
assert(M.for_uniform(G.SPLASH_BACK,'background','colour_1',source)==out)
near(source[1],.9*80/255)
assert(cfg.background_cycle_seconds==480)
print('PASS: 2401 phases, luma/alpha/gamut, all palette boundaries/wrap, full cycle clock, Off/reduced motion, foreground isolation, reused buffers')
