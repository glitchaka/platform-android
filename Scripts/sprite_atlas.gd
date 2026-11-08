@tool
extends RefCounted

# The thin top strip and the long outer corner are separate sprites in each biome.
const TERRAIN = {
	"moss": {"surface": Rect2i(8,0,88,8), "left": Rect2i(56,8,8,24), "right": Rect2i(96,0,8,8), "rock": Rect2i(0,80,8,16), "tree": Rect2i(50,101,13,37), "plant": Rect2i(3,49,11,10)},
	"sand": {"surface": Rect2i(8,160,88,8), "left": Rect2i(56,168,8,24), "right": Rect2i(96,160,8,8), "rock": Rect2i(0,232,8,16), "tree": Rect2i(50,277,13,27), "plant": Rect2i(3,209,11,10)},
	"ruins": {"surface": Rect2i(8,320,88,8), "left": Rect2i(56,328,8,24), "right": Rect2i(96,320,8,8), "rock": Rect2i(0,424,8,16), "tree": Rect2i(49,475,15,29), "plant": Rect2i(3,369,11,10)},
	"slate": {"surface": Rect2i(8,520,88,8), "left": Rect2i(56,528,8,24), "right": Rect2i(96,520,8,8), "rock": Rect2i(0,616,8,16), "tree": Rect2i(116,656,9,16), "plant": Rect2i(3,569,11,10)}
}
const ZONE_TERRAIN = {"tutorial":"slate", "town":"slate", "fungus":"moss", "bone":"sand", "city":"ruins", "cross":"slate", "palace":"slate", "deep":"ruins", "aurora":"moss"}
const COLLECTABLES = {"heart":Rect2i(0,0,8,8), "coin":Rect2i(8,0,8,8), "double_jump":Rect2i(16,0,8,8), "dash":Rect2i(16,0,8,8), "key":Rect2i(24,0,8,8), "ending":Rect2i(24,0,8,8)}
const PLAYER_FRAME = Vector2i(8,8)
const PLAYER_ROWS = {"idle":64,"run":16,"jump":88,"climb":104,"hurt":120}
