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
void Combat::TickPatrol(float dt,std::vector<Enemy> &enemies,int &coins,const Vec2 &playerPosition){
    for(size_t i=0;i<enemies.size();++i){
        Enemy &e=enemies[i];
        if(!e.alive)continue;
        e.time+=dt;
        if(e.burnRemaining>0){
            e.burnRemaining=std::max(0.0f,e.burnRemaining-dt);
            e.burnTick-=dt;
            if(e.burnTick<=0){
                e.burnTick+=0.4f;
                e.hp-=e.burnDamage;
                if(e.hp<=0){e.alive=false;if(!e.boss)++coins;continue;}
            }
        }
        if(e.boss){
            const float phase=std::fmod(e.time,2.7f);
            if(phase<0.8f){
                e.speed=0;
                const float dx=playerPosition.x-e.position.x;
                if(dx!=0)e.chargeDirection=(dx>0)?1.0f:-1.0f;
            }else if(phase<1.65f){
                e.speed=e.chargeDirection*((e.elite||e.hp<e.maxHp/2)?125.0f:100.0f);
            }else{
                e.speed=e.chargeDirection*18.0f;
            }
        }else if(e.flyer){
            e.speed=e.speed>0?33.0f:-33.0f;
            e.position.y=e.baseY+std::sin(e.time*2.4f)*10.0f;
        }
        e.position.x+=e.speed*dt;
        if(e.position.x<=e.patrolMin || e.position.x>=e.patrolMax){
            e.position.x=std::max(e.patrolMin,std::min(e.position.x,e.patrolMax));
            e.speed=-e.speed;
            e.chargeDirection=-e.chargeDirection;
        }
    }
}
void Combat::TickShots(float dt,std::vector<Bullet> &shots,std::vector<Enemy> &enemies,int &coins){
    for(size_t si=0;si<shots.size();){
        Bullet &shot=shots[si];
        float travelTime=dt;
        if(shot.delay>0){
            shot.delay-=dt;
            if(shot.delay>=0){++si;continue;}
            travelTime=-shot.delay;shot.delay=0;
        }
        const Vec2 old=shot.position;
        const float speed=std::sqrt(shot.velocity.x*shot.velocity.x+shot.velocity.y*shot.velocity.y);
        const float distance=std::min(shot.remaining,speed*travelTime);
        const float fraction=speed>0?distance/speed:0.0f;
        const Vec2 next(old.x+shot.velocity.x*fraction,old.y+shot.velocity.y*fraction);
        shot.position=next;
        shot.remaining=std::max(0.0f,shot.remaining-distance);
        struct Contact {float fraction;size_t index;};
        std::vector<Contact> impacts;
        for(size_t i=0;i<enemies.size();++i){
            const Enemy &e=enemies[i];
            if(!e.alive||shot.hitIndices.count(i)!=0)continue;
            const Vec2 center(e.position.x,e.position.y-(e.boss?4.0f:0.0f));
            const float fraction=Fraction(old,next,center,(e.boss?11.0f:6.0f)+shot.radius);
            if(fraction>=0){Contact hit={fraction,i};impacts.push_back(hit);}
        }
        for(size_t i=0;i<impacts.size();++i)
            for(size_t j=i+1;j<impacts.size();++j)
                if(impacts[j].fraction<impacts[i].fraction)std::swap(impacts[i],impacts[j]);
        bool finished=false;
        for(size_t i=0;i<impacts.size()&&!finished;++i){
            Enemy &e=enemies[impacts[i].index];
            if(!e.alive)continue;
            shot.hitIndices.insert(impacts[i].index);
            e.hp-=shot.damage;
            if(shot.burn>0){
                e.burnDamage=std::max(e.burnDamage,shot.burn);
                if(e.burnRemaining<=0)e.burnTick=0.4f;
                e.burnRemaining=1.25f;
            }
            if(e.hp<=0){
                e.alive=false;
                if(!e.boss)++coins;
            }
            --shot.pierce;
            if(shot.pierce<0)finished=true;
        }
        if(finished||shot.remaining<=0)shots.erase(shots.begin()+si);
        else ++si;
    }
}
}
