#pragma once
// The 2012 engine redefines NULL as a user-defined idNullPtr. That macro
// breaks constexpr constructors in current MSVC STL; hide it while importing STL.
#if defined(_MSC_VER) && defined(NULL)
#pragma push_macro("NULL")
#undef NULL
#define MERIDIAN_RESTORE_NULL
#endif
#include <algorithm>
#include <cmath>
#include <cstddef>
#include <string>
#include <set>
#include <vector>
#ifdef MERIDIAN_RESTORE_NULL
#pragma pop_macro("NULL")
#undef MERIDIAN_RESTORE_NULL
#endif

namespace meridian {
struct Vec2 {
    float x, y;
    Vec2(float px=0.0f,float py=0.0f):x(px),y(py){}
};
struct Rect {
    float x,y,w,h;
    Rect(float px=0,float py=0,float pw=0,float ph=0):x(px),y(py),w(pw),h(ph){}
    bool overlapsX(float px,float radius) const { return px+radius > x && px-radius < x+w; }
};
struct RoomRecord {
    const char *id, *name, *zone, *reward;
    int width, height;
};
struct LinkRecord { const char *a, *b, *gate; };
struct Door {
    std::string target,gate;
    float x, y;
    int number;
};
struct Enemy {
    Vec2 position;
    float patrolMin,patrolMax,speed;
    int hp,maxHp,contactDamage,burnDamage;
    float burnRemaining,burnTick,time,baseY,chargeDirection;
    bool boss,flyer,alive,elite;
    std::string tag;
    Enemy():patrolMin(0),patrolMax(0),speed(24),hp(1),maxHp(1),contactDamage(1),
        burnDamage(0),burnRemaining(0),burnTick(0),time(0),baseY(0),
        chargeDirection(-1),boss(false),flyer(false),alive(true),elite(false){}
};
struct Pickup {
    Vec2 position;
    std::string id,kind;
    bool taken;
    Pickup():taken(false){}
};
struct Bullet {
    Vec2 position,velocity;
    float remaining,delay,radius;
    int damage,pierce,burn;
    std::set<size_t> hitIndices;
    Bullet():remaining(0),delay(0),radius(2),damage(1),pierce(0),burn(0){}
};
struct Room {
    const RoomRecord *record;
    std::vector<Rect> platforms;
    std::vector<Door> doors;
    std::vector<Enemy> enemies;
    std::vector<Pickup> pickups;
    float floorY;
    Vec2 rewardPosition,restPosition;
    Room():record(NULL),floorY(0),rewardPosition(),restPosition(){}
};
struct Input {
    bool left,right,jump,fire,interact,dash,pause,save,weaponNext,heal;
    Input():left(false),right(false),jump(false),fire(false),interact(false),dash(false),pause(false),save(false),weaponNext(false),heal(false){}
};
}
