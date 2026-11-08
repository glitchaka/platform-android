#include "Weapons.hpp"
#include <algorithm>
// Avoid strcmp: the 2012 idTech headers redefine that token as a macro.
namespace meridian {
namespace {
const WeaponInfo kWeapons[kWeaponCount]={
    {"pistol","PISTOLA",240,12},
    {"shotgun","ESCOPETA",150,20},
    {"flame","LANZALLAMAS",480,26},
    {"needle","AGUJA DEL ALBA",180,28},
    {"tempest","TEMPESTAD",210,30},
    {"phoenix","FENIX",540,32}
};
}
const WeaponInfo &Arsenal::Info(int index){
    return kWeapons[std::max(0,std::min(kWeaponCount-1,index))];
}
int Arsenal::IndexOf(const char *id){
    if(!id)return -1;
    for(int i=0;i<kWeaponCount;++i){
        const char *a=id,*b=kWeapons[i].id;
        while(*a && *b && *a==*b){++a;++b;}
        if(*a==0 && *b==0)return i;
    }
    return -1;
}
WeaponStats Arsenal::Stats(int index,int level){
    const int n=std::max(0,std::min(3,level));
    WeaponStats s={1+n,1,std::max(0,n-1),0,1,
        0.25f-n*0.02f,190.0f+n*40.0f,290.0f,0,2.0f,false};
    switch(index){
        case 1:
            s.damage=1+n;s.interval=0.65f-n*0.055f;
            s.range=110.0f+n*26.0f;s.pellets=3+(n==3?2:0);
            s.spread=0.20f+n*0.035f;s.pierce=0;break;
        case 2:case 5:
            s.damage=1+n/2;s.interval=0.13f-n*0.01f;
            s.range=56.0f+n*16.0f;s.speed=130.0f;
            s.pierce=8;s.burn=1+n/2;s.automatic=true;s.radius=4.0f;
            if(index==5){s.pellets=3;s.spread=0.22f;s.burn=2+n;s.range=78.0f+n*18.0f;}
            break;
        case 3:
            s.damage=6+n*2;s.interval=0.8f-n*0.065f;
            s.range=340.0f+n*60.0f;s.speed=510.0f;s.pierce=4+n;s.radius=2.5f;break;
        case 4:
            s.damage=2+n;s.interval=0.48f-n*0.045f;
            s.range=230.0f+n*35.0f;s.speed=350.0f;s.burst=3;
            s.automatic=true;s.pierce=n>=2?1:0;break;
        default:break;
    }
    return s;
}
void Arsenal::Reset(WeaponState (&slots)[kWeaponCount]){
    for(int i=0;i<kWeaponCount;++i){
        slots[i]=WeaponState();
        slots[i].durability=static_cast<float>(kWeapons[i].capacity);
    }
    slots[0].owned=true;
}
}
