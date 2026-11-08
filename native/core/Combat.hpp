#pragma once
#include "Types.hpp"
namespace meridian {
struct Combat {
    static float Fraction(const Vec2 &start,const Vec2 &end,const Vec2 &center,float radius);
    static void TickShots(float dt,std::vector<Bullet> &shots,std::vector<Enemy> &enemies,int &coins);
    static void TickPatrol(float dt,std::vector<Enemy> &enemies);
};
}
