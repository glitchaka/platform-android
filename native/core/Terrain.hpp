#pragma once
// Source-accurate 8x8 terrain atlas selections for the native idTech renderer.
#include <string>
namespace meridian {
enum class TerrainStyle { Original, Moss, Rock, Brick, Ember, Forest, Frost, Cave };
struct TileUV {float x,y;TileUV(float px=0,float py=0):x(px),y(py){}};
struct BackgroundRGB {float r,g,b;BackgroundRGB(float a,float c,float d):r(a),g(c),b(d){}};
class Terrain {
public:
    static TerrainStyle RoomStyle(const std::string &id){
        if(id=="moss_depths")return TerrainStyle::Moss;
        if(id=="deep_west")return TerrainStyle::Rock;
        if(id=="city_square"||id=="aurora_gate")return TerrainStyle::Brick;
        if(id=="reservoir")return TerrainStyle::Cave;
        if(id=="aurora_garden")return TerrainStyle::Forest;
        if(id=="aurora_core")return TerrainStyle::Frost;
        return TerrainStyle::Original;
    }
    static const char *Material(TerrainStyle style){
        switch(style){
            case TerrainStyle::Moss:return "meridian/tilesets/moss_full";
            case TerrainStyle::Rock:return "meridian/tilesets/rocks_full";
            case TerrainStyle::Brick:return "meridian/tilesets/bricks_full";
            case TerrainStyle::Ember:return "meridian/tilesets/orange_full";
            case TerrainStyle::Forest:
            case TerrainStyle::Frost:return "meridian/tilesets/tiles-and-enemies";
            case TerrainStyle::Cave:return "meridian/tilesets/tileset";
            default:return "meridian/tiles";
        }
    }
    static BackgroundRGB Background(TerrainStyle style){
        switch(style){
            case TerrainStyle::Moss:return BackgroundRGB(20/255.0f,43/255.0f,41/255.0f);
            case TerrainStyle::Rock:return BackgroundRGB(36/255.0f,35/255.0f,50/255.0f);
            case TerrainStyle::Brick:return BackgroundRGB(32/255.0f,33/255.0f,46/255.0f);
            case TerrainStyle::Ember:return BackgroundRGB(48/255.0f,29/255.0f,43/255.0f);
            case TerrainStyle::Forest:return BackgroundRGB(21/255.0f,37/255.0f,31/255.0f);
            case TerrainStyle::Frost:return BackgroundRGB(25/255.0f,38/255.0f,51/255.0f);
            case TerrainStyle::Cave:return BackgroundRGB(23/255.0f,30/255.0f,48/255.0f);
            default:return BackgroundRGB(0.12f,0.15f,0.16f);
        }
    }
    static TileUV Source(TerrainStyle style,int x,int y,int width,int height){
        const bool right=x+8>=width;
        const bool bottom=y+8>=height;
        const bool forest=style==TerrainStyle::Forest||style==TerrainStyle::Frost;
        if(forest){
            const int offset=style==TerrainStyle::Frost?104:0;
            int sourceX=offset+(x==0?0:right?40:8+(x/8%4)*8);
            const int sourceY=y==0?16:bottom?24:64+(y/8%3)*8;
            if(y>0&&!bottom)sourceX=offset+(x/8%3)*8;
            return TileUV(float(sourceX),float(sourceY));
        }
        if(style==TerrainStyle::Cave)
            return TileUV(float(x==0?0:right?16:8),float(y==0?48:bottom?64:56));
        return TileUV(float(x==0?0:right?24:8+(x/8%2)*8),
                      float(y==0?0:bottom?24:8+(y/8%2)*8));
    }
};
} // namespace meridian
