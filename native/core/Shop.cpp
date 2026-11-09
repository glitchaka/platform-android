#include "Shop.hpp"
#include <algorithm>
#include <cmath>
namespace meridian {
namespace {
const ShopItem kItems[kShopItemCount] = {
    {"power","CANON REFORZADO","bone",55},
    {"rapid","DISPARO RAPIDO","royal",85},
    {"magnet","IMAN DE MONEDAS","nest",20},
    {"flask","FRASCO CURATIVO","nest",30},
    {"guard","AMULETO GUARDIAN","royal",70},
    {"satchel","BOLSA DE TONICOS","explorer",26},
    {"heart","CORAZON EXTRA","explorer",65},
    {"heal","CURACION","",3},
    {"tonic","TONICO DE VIAJE","nest",6},
    {"ember","ASPECTO BRASA","nest",18},
    {"storm","ASPECTO TORMENTA","explorer",35},
    {"starlight","ASPECTO ESTELAR","ending",50},
    {"shotgun","ESCOPETA","nest",42},
    {"flame","LANZALLAMAS","bone",60},
    {"forge","MEJORAR ARMA","",30},
    {"repair","REPARAR ARMA","",1}
};
}
const ShopItem &ShopCatalog::Item(int i){return kItems[std::max(0,std::min(kShopItemCount-1,i))];}
bool ShopCatalog::GateOpen(const ShopItem &i,const ShopAccess &a){
    const std::string gate=i.gate;
    return gate.empty()||(gate=="nest"&&a.nest)||(gate=="bone"&&a.bone)
        ||(gate=="royal"&&a.royal&&a.dash)
        ||(gate=="explorer"&&a.bone&&a.explorer)
        ||(gate=="ending"&&a.ending);
}
bool ShopCatalog::IsOneTime(const char *raw){
    const std::string s=raw;
    return s!="heal"&&s!="tonic"&&s!="heart"&&s!="forge"&&s!="repair";
}
int ShopCatalog::Price(const ShopItem &i,const ShopState &state,const WeaponState &weapon,int index){
    const std::string name=i.id;
    if(name=="heart")return 65+35*state.heartPurchases;
    if(name=="forge"){const int levels[]={30,60,100,0};return levels[std::max(0,std::min(3,weapon.level))];}
    if(name=="repair"){
        const WeaponInfo &info=Arsenal::Info(index);
        const float fraction=1.0f-weapon.durability/static_cast<float>(info.capacity);
        return std::max(1,static_cast<int>(std::ceil(info.repair*fraction)));
    }
    return i.price;
}
}
