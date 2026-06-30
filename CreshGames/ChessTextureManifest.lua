local _, CC = ...

-- CreshChat Chess piece texture manifest
-- WoW TBC-ready 64x64 uncompressed TGA textures with alpha.
_G.CreshGamesChessTextures = {
    White = {
        King = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\King_White.tga",
        Queen = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Queen_White.tga",
        Rook = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Rook_White.tga",
        Bishop = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Bishop_White.tga",
        Knight = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Knight_White.tga",
        Pawn = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Pawn_White.tga",
    },
    Black = {
        King = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\King_Black.tga",
        Queen = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Queen_Black.tga",
        Rook = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Rook_Black.tga",
        Bishop = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Bishop_Black.tga",
        Knight = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Knight_Black.tga",
        Pawn = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Pawn_Black.tga",
    },
    Notation = {
        WK = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\King_White.tga",
        BK = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\King_Black.tga",
        WQ = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Queen_White.tga",
        BQ = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Queen_Black.tga",
        WR = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Rook_White.tga",
        BR = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Rook_Black.tga",
        WB = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Bishop_White.tga",
        BB = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Bishop_Black.tga",
        WN = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Knight_White.tga",
        BN = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Knight_Black.tga",
        WP = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Pawn_White.tga",
        BP = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Pawn_Black.tga",
    }
}

-- Example: texture:SetTexture(CreshGamesChessTextures.White.King)
if CC then
    CC.Assets = CC.Assets or {}
    CC.Assets.Chess = _G.CreshGamesChessTextures
    if CC.RegisterModule then CC:RegisterModule("ChessAssets", { version = CC.version, library = _G.CreshGamesChessTextures }) end
end
