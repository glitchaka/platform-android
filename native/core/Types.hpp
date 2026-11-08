#pragma once
#include <algorithm>
#include <cmath>
#include <cstddef>
#include <string>
#include <set>
#include <vector>

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
    int hp;
    bool boss,flyer,alive;
    Enemy():patrolMin(0),patrolMax(0),speed(24),hp(1),boss(false),flyer(false),alive(true){}
};
struct Pickup {
    Vec2 position;
    std::string id,kind;
    bool taken;
    Pickup():taken(false){}
};
struct Bullet {
    Vec2 position,velocity;
    float remaining;
    int damage,pierce;
    std::set<size_t> hitIndices;
    Bullet():remaining(0),damage(1),pierce(0){}
};
struct Room {
    const RoomRecord *record;
    std::vector<Rect> platforms;
    std::vector<Door> doors;
    std::vector<Enemy> enemies;
    std::vector<Pickup> pickups;
    float floorY;
    Room():record(NULL),floorY(0){}
};
struct Input {
    bool left,right,jump,fire,interact,dash,pause,save;
    Input():left(false),right(false),jump(false),fire(false),interact(false),dash(false),pause(false),save(false){}
};
}
