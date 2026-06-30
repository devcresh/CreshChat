local _, CC = ...
if not CC then return end

local Audio = { version = CC.version, loopSeconds = 11.95, generation = 0 }
CC.GameAudio = Audio
if CC.RegisterModule then CC:RegisterModule("GameAudio", Audio) end

local ROOT = "Interface\\AddOns\\CreshGames\\Media\\GameAudio\\"
local MUSIC = {
    FROGGER = "Music\\arcade_loop", TETRIS = "Music\\arcade_loop", PONG = "Music\\arcade_loop",
    HOLDEM = "Music\\cards_loop", BLACKJACK = "Music\\cards_loop", HIGHERLOWER = "Music\\cards_loop",
    DUNGEON = "Music\\dungeon_loop", CHESS = "Music\\strategy_loop",
}
local SFX = {
    CLICK="SFX\\ui_click", MOVE="SFX\\game_move", CARD="SFX\\card_flip",
    WIN="SFX\\game_win", LOSS="SFX\\game_loss", LEVEL="SFX\\level_up",
    LINE_CLEAR="SFX\\tetris_line_clear", REVEAL="SFX\\tetris_reveal",
}

local function clamp(v) v=tonumber(v) or 0; if v<0 then return 0 elseif v>1 then return 1 end return v end
local function bucket(v)
    v=clamp(v)
    if v <= 0.01 then return 0 end
    if v < 0.38 then return 25 elseif v < 0.63 then return 50 elseif v < 0.88 then return 75 end
    return 100
end
local function fileFor(base, volume)
    local b=bucket(volume); if b==0 then return nil end
    return ROOT .. base .. (b==100 and ".ogg" or ("_v"..b..".ogg"))
end
local function playFile(path)
    if not path or type(_G.PlaySoundFile)~="function" then return false,nil end
    local ok, played, handle = pcall(_G.PlaySoundFile, path, "Master")
    if not ok or played == false then return false,nil end
    return true, handle
end

function Audio:Ensure()
    if not CC.db then return nil end
    CC.db.gameAudio = type(CC.db.gameAudio)=="table" and CC.db.gameAudio or {}
    local s=CC.db.gameAudio
    if s.musicEnabled==nil then s.musicEnabled=true end
    if s.effectsEnabled==nil then s.effectsEnabled=true end
    s.musicVolume=clamp(s.musicVolume==nil and 0.35 or s.musicVolume)
    s.effectsVolume=clamp(s.effectsVolume==nil and 0.55 or s.effectsVolume)
    return s
end
function Audio:StopMusic()
    self.generation=(self.generation or 0)+1
    if self.handle and type(_G.StopSound)=="function" then pcall(_G.StopSound,self.handle,180) end
    self.handle=nil; self.currentGame=nil
end
function Audio:PlayMusic(game)
    local s=self:Ensure(); game=string.upper(tostring(game or "")); local base=MUSIC[game]
    self:StopMusic()
    if not s or s.musicEnabled==false or not base or s.musicVolume<=0 then return false end
    self.currentGame=game; local generation=self.generation
    local function loop()
        if generation~=Audio.generation or Audio.currentGame~=game then return end
        local settings=Audio:Ensure(); if not settings or settings.musicEnabled==false then Audio:StopMusic(); return end
        if Audio.handle and type(_G.StopSound)=="function" then pcall(_G.StopSound,Audio.handle,40) end
        local path=fileFor(base,settings.musicVolume); local ok,handle=playFile(path); if ok then Audio.handle=handle end
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(Audio.loopSeconds,loop) end
    end
    loop(); return true
end
function Audio:RestartMusic()
    if self.currentGame then local game=self.currentGame; self:PlayMusic(game) end
end
function Audio:PlayEffect(kind)
    local s=self:Ensure(); kind=string.upper(tostring(kind or "CLICK")); local base=SFX[kind]
    if not s or s.effectsEnabled==false or not base or s.effectsVolume<=0 then return false end
    return playFile(fileFor(base,s.effectsVolume))
end

function Audio:PlayInteraction(kind)
    local stamp=type(_G.GetTime)=="function" and _G.GetTime() or 0
    if stamp-(self.lastInteraction or 0)<0.07 then return false end
    self.lastInteraction=stamp
    return self:PlayEffect(kind or "CLICK")
end
