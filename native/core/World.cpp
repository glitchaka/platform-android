#include "World.hpp"
#include <cstdio>
#include <functional>
namespace meridian {
#include "../generated/RoomCatalog.inc"

const RoomRecord *FindRoom(const std::string &id) {
    for(size_t i=0;i<kRoomCount;++i) if(id==kRooms[i].id) return &kRooms[i];
    return NULL;
}
size_t RoomCount(){return kRoomCount;}
size_t LinkCount(){return kLinkCount;}
static void addPlatform(Room &r,float x,float y,float w,float h){
    r.platforms.push_back(Rect(x,y,w,h));
}
static void addEnemy(Room &r,float x,float y,float minX,float maxX,bool boss,bool flyer){
    Enemy e; e.position=Vec2(x,y); e.patrolMin=minX; e.patrolMax=maxX;
    e.boss=boss; e.flyer=flyer; e.hp=boss?12:flyer?2:3; e.speed=boss?40.0f:flyer?30.0f:22.0f;
    r.enemies.push_back(e);
}
static void addPickup(Room &r,const char *kind,const std::string &id,float x,float y,const std::set<std::string> &collected){
    Pickup o; o.kind=kind; o.id=id; o.position=Vec2(x,y); o.taken=collected.count(id)!=0; r.pickups.push_back(o);
}
Room CreateRoom(const std::string &id,const std::set<std::string> &collected,const std::set<std::string> &defeated){
    Room r; r.record=FindRoom(id);
    if(!r.record) return r;
    const float w=static_cast<float>(r.record->width);
    const float h=static_cast<float>(r.record->height);
    const std::string zone=r.record->zone;
    const std::string reward=r.record->reward;
    r.floorY=h-40.0f;
    addPlatform(r,0,r.floorY,w,40);
    const bool town=id=="town",tutorial=id=="tutorial",aurora=zone=="aurora";
    if(town){
        const int xs[]={64,136,208,352,448,544};
        for(size_t i=0;i<6;++i)addPlatform(r,(float)xs[i],r.floorY-32,56,16);
        addPlatform(r,280,r.floorY-64,56,16);
        addPlatform(r,360,r.floorY-96,64,16);
    }else if(tutorial){
        addPlatform(r,80,r.floorY-32,64,16);
        addPlatform(r,144,r.floorY-64,64,16);
        addPlatform(r,232,r.floorY-64,64,16);
    }else if(aurora){
        for(int x=64;x<(int)w-80;x+=112)addPlatform(r,(float)x,r.floorY-32,80,16);
        for(int x=120;x<(int)w-120;x+=112)addPlatform(r,(float)x,r.floorY-64,64,16);
        if(id=="aurora_garden"){
            addPlatform(r,232,r.floorY-96,80,16);
            addPlatform(r,288,r.floorY-128,64,16);
        }
    }else{
        // The original room generator constructs step and return platforms per zone.
        unsigned int variation=0;
        for(size_t i=0;i<id.size();++i)variation=variation*33u+(unsigned char)id[i];
        const int variant=static_cast<int>(variation%3);
        for(int i=0;i<(int)((r.floorY-40)/32);++i){
            addPlatform(r,64+(float)((i+variant)%3)*48,r.floorY-32-i*32,64,16);
        }
        for(int x=280;x<(int)w-56;x+=96){
            addPlatform(r,(float)x,r.floorY-32,64,16);
            if((x/96)%2==0)addPlatform(r,(float)x-32,r.floorY-64,56,16);
        }
    }
    for(size_t i=0;i<kLinkCount;++i){
        const LinkRecord &l=kLinks[i];
        const char *destination=NULL;
        if(id==l.a)destination=l.b;
        else if(id==l.b)destination=l.a;
        if(!destination)continue;
        Door d; d.target=destination; d.gate=l.gate;
        if(id=="bone_return"||d.target=="bone_return")d.gate="boss:bone_lord";
        if(id=="city_end"||d.target=="city_end")d.gate="boss:royal_spire";
        d.number=static_cast<int>(r.doors.size())+1;
        r.doors.push_back(d);
    }
    for(size_t i=0;i<r.doors.size();++i){
        const float t=id=="tutorial"?1.0f:(r.doors.size()==1?0.0f:(float)i/(float)(r.doors.size()-1));
        r.doors[i].x=20+t*(w-40);
        r.doors[i].y=r.floorY-4;
    }
    if(reward=="rest")addPickup(r,"bench",id+":bench",w/2,r.floorY-4,collected);
    if(town){
        addPickup(r,"guide",id+":guide",92,r.floorY-4,collected);
        addPickup(r,"shop",id+":shop",164,r.floorY-4,collected);
    }
    if(tutorial){
        addPickup(r,"lever",id+":lever",112,r.floorY-4,collected);
        addEnemy(r,312,r.floorY-4,240,340,false,false);
    }
    if(reward=="boss"){
        addPickup(r,"chest",id+":chest",w*0.72f,r.floorY-4,collected);
        if(defeated.count(id)==0)addEnemy(r,w*0.62f,r.floorY-4,72,w-32,true,false);
    }else if(!town&&!tutorial&&reward!="rest"){
        for(int x=152;x<(int)w-32;x+=128)addEnemy(r,(float)x,r.floorY-4,x-36,std::min((float)x+44,w-32),false,false);
        for(size_t i=2;i<r.platforms.size();i+=3){
            const Rect &p=r.platforms[i];
            addEnemy(r,p.x+32,p.y-16,p.x,p.x+p.w,false,true);
        }
        addPickup(r,"chest",id+":chest",w*0.5f,r.floorY-80,collected);
    }
    for(size_t i=1;i<r.platforms.size()&&i<=3;++i){
        char num[32]; std::sprintf(num,"coin%u",(unsigned)i);
        const Rect &p=r.platforms[i];
        addPickup(r,"coin",id+":"+num,p.x+16,p.y-10,collected);
    }
    for(int x=128;x<(int)w-40;x+=144)
        addPickup(r,"crate",id+":crate"+std::to_string(x),(float)x,r.floorY-4,collected);
    return r;
}
}
