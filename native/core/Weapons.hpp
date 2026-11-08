#pragma once
// Arsenal native model, ported from Scripts/arsenal.gd.
namespace meridian {
enum { kWeaponCount = 6 };
struct WeaponInfo { const char *id,*name; int capacity,repair; };
struct WeaponStats {
    int damage,pellets,pierce,burn,burst;
    float interval,range,speed,spread,radius;
    bool automatic;
};
struct WeaponState {
    int level; float durability; bool owned;
    WeaponState():level(0),durability(0),owned(false){}
};
struct Arsenal {
    static const WeaponInfo &Info(int index);
    static int IndexOf(const char *id);
    static WeaponStats Stats(int index,int level);
    static void Reset(WeaponState (&slots)[kWeaponCount]);
};
}
