#pragma once
#include <cstddef>
#include <string>
namespace meridian {
struct MapRoom { const char *id; int x,y,w,h; };
#include "../generated/MapCatalog.inc"
class Map {
public:
    static size_t Count(){return sizeof(kMapRooms)/sizeof(kMapRooms[0]);}
    static const MapRoom &At(size_t index){return kMapRooms[index<Count()?index:0];}
    static const MapRoom *Find(const std::string &id){
        for(size_t i=0;i<Count();++i)if(id==kMapRooms[i].id)return &kMapRooms[i];
        return nullptr;
    }
};
} // namespace meridian
