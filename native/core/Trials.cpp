#include "Trials.hpp"
#include <algorithm>
#include <cstdio>
namespace meridian {
namespace {
const char *const locations[]={"nest","bone_lord","royal_spire"};
int RankOf(const std::string &id){
    for(int i=0;i<3;++i)if(id==locations[i])return i;
    return -1;
}
std::string Key(const char *category,const std::string &id){
    return std::string("trial:")+category+":"+id;
}
}
Trials::Trials():elapsed(0),hits(0),round(0),healed(false),active(false){}
void Trials::Reset(){location.clear();elapsed=0;hits=0;round=0;healed=false;active=false;}
void Trials::Tick(float dt){if(active&&dt>0)elapsed+=dt;}
void Trials::OnHit(){if(active)++hits;}
void Trials::OnHeal(){if(active)healed=true;}
bool Trials::IsTrialRoom(const std::string &id){return RankOf(id)>=0||id=="throne";}
bool Trials::HasThreeClean(const std::set<std::string> &collected){
    for(int i=0;i<3;++i)if(!collected.count(Key("clean",locations[i])))return false;
    return true;
}
bool Trials::HasThreeFast(const std::set<std::string> &collected){
    for(int i=0;i<3;++i)if(!collected.count(Key("speed",locations[i])))return false;
    return true;
}
bool Trials::HasMarathon(const std::set<std::string> &collected){
    return collected.count("trial:marathon")!=0;
}
void Trials::Spawn(Room &room){
    if(!room.record)return;
    const float width=static_cast<float>(room.record->width);
    const int rank=location=="throne"?round:RankOf(location);
    Enemy boss;
    boss.boss=true;
    boss.elite=false;
    boss.tag="trial:active";
    boss.position=Vec2(std::max(48.0f,std::min(width-48.0f,width*0.68f)),room.floorY-4);
    boss.baseY=boss.position.y;
    boss.patrolMin=48.0f;
    boss.patrolMax=width-32.0f;
    boss.hp=480+rank*160;
    boss.maxHp=boss.hp;
    boss.contactDamage=8+rank;
    boss.speed=24.0f;
    room.enemies.push_back(boss);
}
bool Trials::Start(Room &room,const std::string &id){
    if(active||!room.record||!IsTrialRoom(id)||id!=room.record->id)return false;
    for(size_t i=0;i<room.enemies.size();++i)
        if(room.enemies[i].elite&&room.enemies[i].alive)return false;
    Reset();location=id;active=true;Spawn(room);return true;
}
bool Trials::Advance(Room &room,std::set<std::string> &collected,int &coins,std::string &notice){
    if(!active)return false;
    bool found=false;
    for(size_t i=0;i<room.enemies.size();++i){
        const Enemy &e=room.enemies[i];
        if(e.tag!="trial:active")continue;
        found=true;
        if(e.alive)return false;
    }
    if(!found)return false;
    if(location=="throne"){
        ++round;
        if(round<3){
            Spawn(room);
            notice="PRUEBA DEL TRONO: SIGUIENTE ECO";
            return false;
        }
        coins+=24;
        if(!healed){collected.insert("trial:marathon");notice="PRUEBA SIN CURAS: FENIX DESBLOQUEADO";}
        else notice="PRUEBA COMPLETA. REPITE SIN CURARTE PARA FENIX";
    }else{
        coins+=8;
        if(hits==0)collected.insert(Key("clean",location));
        if(elapsed<=12.0f)collected.insert(Key("speed",location));
        char number[64];std::sprintf(number,"ECO VENCIDO EN %.1f SEGUNDOS",elapsed);
        notice=number;
    }
    Reset();
    return true;
}
}
