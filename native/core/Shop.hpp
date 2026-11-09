#pragma once
#include "Weapons.hpp"
#include <set>
#include <string>
namespace meridian {
enum { kShopItemCount = 16 };
struct ShopItem { const char *id,*name,*gate; int price; };
struct ShopState {
    std::set<std::string> owned;
    int heartPurchases,tonics,flaskCharges,style;
    bool guardCharged;
    ShopState():heartPurchases(0),tonics(0),flaskCharges(0),style(0),guardCharged(false){}
    bool Has(const std::string &id)const{return owned.count(id)!=0;}
    int TonicCapacity()const{return Has("satchel")?5:3;}
};
struct ShopAccess {
    bool nest,bone,royal,ending,explorer,dash;
    ShopAccess():nest(false),bone(false),royal(false),ending(false),explorer(false),dash(false){}
};
class ShopCatalog {
public:
    static const ShopItem &Item(int index);
    static int Count(){return kShopItemCount;}
    static bool GateOpen(const ShopItem &item,const ShopAccess &access);
    static bool IsOneTime(const char *id);
    static int Price(const ShopItem &item,const ShopState &state,const WeaponState &weapon,int weaponIndex);
};
}
