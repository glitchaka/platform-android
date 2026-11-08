#include "Combat.hpp"
#include <algorithm>
#include <cmath>
namespace meridian {
float Combat::Fraction(const Vec2 &a,const Vec2 &b,const Vec2 &center,float radius){
    const float dx=b.x-a.x,dy=b.y-a.y;
    const float ox=a.x-center.x,oy=a.y-center.y;
    const float c=ox*ox+oy*oy-radius*radius;
    if(c<=0)return 0;
    const float aa=dx*dx+dy*dy;
    if(aa<0.000001f)return -1;
    const float bb=2*(ox*dx+oy*dy);
    const float disc=bb*bb-4*aa*c;
    if(disc<0)return -1;
    const float t=(-bb-std::sqrt(disc))/(2*aa);
    return (t>=0&&t<=1)?t:-1;
}
void Combat::TickPatrol(float dt,std::vector<Enemy> &enemies){
    for(size_t i=0;i<enemies.size();++i){
        Enemy &e=enemies[i];
        if(!e.alive)continue;
        e.position.x+=e.speed*dt;
        if(e.position.x<e.patrolMin){
            e.position.x=e.patrolMin;e.speed=std::fabs(e.speed);
        } else if(e.position.x>e.patrolMax){
            e.position.x=e.patrolMax;e.speed=-std::fabs(e.speed);
        }
    }
}
void Combat::TickShots(float dt,std::vector<Bullet> &shots,std::vector<Enemy> &enemies,int &coins){
    for(size_t si=0;si<shots.size();){
        Bullet &shot=shots[si];
        const Vec2 old=shot.position;
        const Vec2 next(old.x+shot.velocity.x*dt,old.y+shot.velocity.y*dt);
        shot.position=next;
        shot.remaining-=std::sqrt(shot.velocity.x*shot.velocity.x+shot.velocity.y*shot.velocity.y)*dt;
        struct Contact {float fraction;size_t index;};
        std::vector<Contact> impacts;
        for(size_t i=0;i<enemies.size();++i){
            const Enemy &e=enemies[i];
            if(!e.alive||shot.hitIndices.count(i)!=0)continue;
            const Vec2 center(e.position.x,e.position.y-(e.boss?4.0f:0.0f));
            const float fraction=Fraction(old,next,center,e.boss?11.0f:6.0f);
            if(fraction>=0){Contact hit={fraction,i};impacts.push_back(hit);}
        }
        for(size_t i=0;i<impacts.size();++i)
            for(size_t j=i+1;j<impacts.size();++j)
                if(impacts[j].fraction<impacts[i].fraction)std::swap(impacts[i],impacts[j]);
        bool finished=shot.remaining<=0;
        for(size_t i=0;i<impacts.size()&&!finished;++i){
            Enemy &e=enemies[impacts[i].index];
            if(!e.alive)continue;
            shot.hitIndices.insert(impacts[i].index);
            e.hp-=shot.damage;
            if(e.hp<=0){
                e.alive=false;
                if(!e.boss)++coins;
            }
            --shot.pierce;
            if(shot.pierce<0)finished=true;
        }
        if(finished)shots.erase(shots.begin()+si);
        else ++si;
    }
}
}
