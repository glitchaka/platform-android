#include "Postgame.hpp"
#include <algorithm>
#include <cmath>
#include <cstdio>
namespace meridian {
namespace {
const char *const quest0[]={"tutorial","town","west_tower","upper_gallery","central_shaft","well","nest","shrine","west_road","heart_room","lower_gallery"};
const char *const quest1[]={"fungal_road","fungal_drop","moss_gate","spore_hall","fungal_stem","canopy","roots","moss_depths","root_shaft","fungal_exit","buried_path","deep_west"};
const char *const quest2[]={"bone_road","bone_gate","ossuary","rib_hall","bone_crown","bone_lord","bone_return","lower_tower","junction","deep_well"};
const char *const quest3[]={"city_gate","reservoir","city_spire","city_square","east_spire","archive","royal_spire","city_end","deep_city"};
const char *const quest4[]={"east_tower","east_shaft","caverns","east_bridge","east_lift","palace_gate","palace_stairs","palace_hall","palace_tower","throne"};
const PostQuest quests[]={
 {"RUTAS DEL ALBA",60,11,quest0},
 {"SEMILLAS DE VIDA",85,12,quest1},
 {"DEUDA DE HUESOS",110,10,quest2},
 {"FORJA DE LA CIUDAD",140,9,quest3},
 {"ULTIMA GUARDIA",180,10,quest4}
};
static bool postgameNear(const Vec2 &a,const Vec2 &b,float limit){
 const float dx=a.x-b.x,dy=a.y-b.y;return dx*dx+dy*dy<limit*limit;
}
}
const PostQuest &Postgame::Quest(int stage){return quests[std::max(0,std::min(4,stage))];}
bool Postgame::IsTarget(int stage,const std::string &room){
 if(stage<0||stage>4)return false;
 const PostQuest &q=Quest(stage);
 for(int i=0;i<q.roomCount;++i)if(room==q.rooms[i])return true;
 return false;
}
std::string Postgame::Token(int stage,const std::string &room){
 char digit[16];std::sprintf(digit,"%d",stage);
 return std::string("post:")+digit+":"+room;
}
std::string Postgame::SwitchToken(int stage,const std::string &room){
 return Token(stage,room)+":switch";
}
std::string Postgame::GuardToken(int stage,const std::string &room,int index){
 char digit[16];std::sprintf(digit,"%d",index);
 return Token(stage,room)+":guard:"+digit;
}
int Postgame::Recovered(int stage,const std::set<std::string> &collected){
 if(stage<0||stage>4)return 0;
 const PostQuest &q=Quest(stage);
 int count=0;for(int i=0;i<q.roomCount;++i)if(collected.count(Token(stage,q.rooms[i])))++count;
 return count;
}
int Postgame::Stage(const std::set<std::string> &collected){
 int stage=0;
 while(stage<5&&Recovered(stage,collected)==Quest(stage).roomCount)++stage;
 return stage;
}
bool Postgame::Complete(const std::set<std::string> &collected){return Stage(collected)>=5;}
void Postgame::EnterRoom(Room &room,bool completed,const std::set<std::string> &collected){
 if(!completed||!room.record)return;
 const int stage=Stage(collected);
 const std::string id=room.record->id;
 if(stage>=5||!IsTarget(stage,id)||collected.count(Token(stage,id)))return;
 const float width=static_cast<float>(room.record->width);
 const bool safe=std::string(room.record->reward)=="rest";
 Vec2 cache(width*0.42f,room.floorY-4.0f);
 if(stage==1&&!safe)cache=room.rewardPosition;
 else{
   bool placed=false;
   for(int x=48;x<static_cast<int>(width)-32;x+=16){
     const Vec2 candidate(static_cast<float>(x),room.floorY-4.0f);
     bool clear=true;
     for(size_t i=0;i<room.doors.size();++i)
       if(postgameNear(candidate,Vec2(room.doors[i].x,room.doors[i].y),26.0f)){clear=false;break;}
     for(size_t i=0;i<room.pickups.size();++i)
       if(postgameNear(candidate,room.pickups[i].position,26.0f)){clear=false;break;}
     if(clear){cache=candidate;placed=true;break;}
   }
   if(!placed)cache=Vec2(std::max(48.0f,std::min(width-48.0f,cache.x)),room.floorY-4);
 }
 Pickup p;p.id=Token(stage,id);p.kind="quest";p.position=cache;
 room.pickups.push_back(p);
 if(stage==3){
    Pickup sw;sw.id=SwitchToken(stage,id);sw.kind="switch";
    sw.position=Vec2(std::max(32.0f,cache.x-28.0f),cache.y-5.0f);
    sw.taken=collected.count(sw.id)!=0;
    room.pickups.push_back(sw);
 }
 if(safe)return;
 const int count=(stage==1||stage==4)?2:1;
 for(int i=0;i<count;++i){
   const std::string tag=GuardToken(stage,id,i);
   if(collected.count(tag)!=0)continue;
   Enemy e;
   e.elite=true;e.tag=tag;
   e.boss=(i==0&&(id=="nest"||id=="bone_lord"||id=="royal_spire"||id=="throne"));
   e.flyer=stage==1;
   e.position=Vec2(std::max(48.0f,std::min(width-48.0f,cache.x+32+i*28.0f)),
                   e.flyer?std::min(room.floorY-12.0f,cache.y-8.0f):room.floorY-4.0f);
   e.baseY=e.position.y;e.patrolMin=std::max(40.0f,e.position.x-48.0f);
   e.patrolMax=std::min(width-32.0f,e.position.x+88.0f);
   if(e.boss){e.patrolMin=48;e.patrolMax=width-32;}
   const int attack=6+stage*2;
   e.hp=attack*(e.boss?22:5);e.maxHp=e.hp;e.contactDamage=6+stage;
   e.speed=e.boss?24.0f:33.0f;
   room.enemies.push_back(e);
 }
}
}
