#include "Game.hpp"
#include "Combat.hpp"
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <sstream>
namespace meridian {
namespace {
float clampValue(float x,float lo,float hi){return std::min(hi,std::max(lo,x));}
float absValue(float x){return x<0?-x:x;}
bool near(const Vec2 &a,const Vec2 &b,float limit){
    const float dx=a.x-b.x,dy=a.y-b.y;
    return dx*dx+dy*dy<limit*limit;
}
}
Game::Game():started(false),paused(false),completed(false),postgame(false),weaponIndex(0),enemyTime(0),noticeTime(0){}
void Game::NewGame(){
    visited.clear();collected.clear();defeated.clear();shots.clear();
    hero=Hero();previous=Input();completed=false;postgame=false;paused=false;
    weaponIndex=0;started=true;notice="NUEVA PARTIDA";
    EnterRoom("tutorial","");
}
void Game::EnterRoom(const std::string &id,const std::string &from){
    const RoomRecord *rec=FindRoom(id);
    if(!rec)return;
    roomId=id;
    visited.insert(id);
    room=CreateRoom(id,collected,defeated);
    shots.clear();
    hero.position=Vec2(24,room.floorY-4);
    for(size_t i=0;i<room.doors.size();++i)
        if(room.doors[i].target==from){
            hero.position.x=clampValue(room.doors[i].x+22,24,(float)rec->width-24);
            break;
        }
    hero.velocity=Vec2();
    hero.grounded=true;hero.jumps=0;
    notice=rec->name;noticeTime=2.0f;
}
bool Game::GateOpen(const Door &d)const{
    if(d.gate.empty())return true;
    if(d.gate=="double_jump")return hero.doubleJump;
    if(d.gate=="dash")return hero.dashUnlocked;
    if(d.gate=="keys")return hero.keys>=2;
    if(d.gate=="postgame")return postgame;
    if(d.gate=="boss:bone_lord")return defeated.count("bone_lord")!=0;
    if(d.gate=="boss:royal_spire")return defeated.count("royal_spire")!=0;
    return false;
}
void Game::Tick(float dt,const Input &input){
    if(!started||dt<=0)return;
    dt=std::min(dt,0.04f);
    if(input.pause&&!previous.pause)paused=!paused;
    if(input.save&&!previous.save){Save("meridian-native.save");notice="PARTIDA GUARDADA";}
    if(paused){previous=input;return;}
    hero.shotCooldown=std::max(0.0f,hero.shotCooldown-dt);
    hero.invulnerability=std::max(0.0f,hero.invulnerability-dt);
    hero.dashTimer=std::max(0.0f,hero.dashTimer-dt);
    hero.dashCooldown=std::max(0.0f,hero.dashCooldown-dt);
    noticeTime=std::max(0.0f,noticeTime-dt);
    Move(dt,input);
    if(input.fire&&hero.shotCooldown<=0)Fire();
    UpdateEnemies(dt);
    Attack(dt);
    Collect();
    if(input.interact&&!previous.interact)Interact();
    previous=input;
}
void Game::Move(float dt,const Input &input){
    const int dir=(input.right?1:0)-(input.left?1:0);
    if(dir!=0)hero.facing=(float)dir;
    const float target=dir*96.0f;
    const float acceleration=1300.0f*dt;
    hero.velocity.x=clampValue(target,hero.velocity.x-acceleration,hero.velocity.x+acceleration);
    if(input.jump&&!previous.jump&&(hero.grounded||(hero.doubleJump&&hero.jumps<2))){
        hero.velocity.y=-220;hero.grounded=false;++hero.jumps;
    }
    if(input.dash&&!previous.dash&&hero.dashUnlocked&&hero.dashCooldown<=0){
        hero.dashTimer=0.16f;hero.dashCooldown=0.65f;
    }
    if(hero.dashTimer>0){hero.velocity.x=hero.facing*250;hero.velocity.y=0;}
    else hero.velocity.y=std::min(hero.velocity.y+620*dt,280.0f);
    const float oldY=hero.position.y;
    hero.position.x+=hero.velocity.x*dt;
    hero.position.y+=hero.velocity.y*dt;
    hero.position.x=clampValue(hero.position.x,4,(float)room.record->width-4);
    bool landed=false;
    for(size_t i=0;i<room.platforms.size();++i){
        const Rect &p=room.platforms[i];
        if(p.overlapsX(hero.position.x,3)&&oldY+4<=p.y+0.1f
           &&hero.position.y+4>=p.y&&hero.velocity.y>=0){
            hero.position.y=p.y-4;hero.velocity.y=0;landed=true;
        }
    }
    hero.grounded=landed;
    if(landed)hero.jumps=0;
    if(hero.position.y>(float)room.record->height+50){
        --hero.health;
        hero.position=Vec2(24,room.floorY-4);
        hero.velocity=Vec2();
    }
    if(hero.health<=0){
        hero.health=hero.maxHealth;
        EnterRoom("tutorial","");
        notice="REAPARECES EN EL TUTORIAL";
    }
}
void Game::Fire(){
    hero.shotCooldown=weaponIndex==1?0.63f:weaponIndex==2?0.12f:0.27f;
    Bullet b;
    b.position=Vec2(hero.position.x+6*hero.facing,hero.position.y-1);
    b.velocity=Vec2(hero.facing*(weaponIndex==2?140.0f:290.0f),0);
    b.remaining=weaponIndex==1?105.0f:weaponIndex==2?64.0f:195.0f;
    b.damage=weaponIndex==1?2:1;
    b.pierce=weaponIndex==2?6:0;
    shots.push_back(b);
    if(weaponIndex==1){
        Bullet up=b;up.velocity.y=-40;shots.push_back(up);
        Bullet down=b;down.velocity.y=40;shots.push_back(down);
    }
}
void Game::Attack(float dt){
    Combat::TickShots(dt,shots,room.enemies,hero.coins);
    if(room.record&&std::string(room.record->reward)=="boss"){
        bool alive=false;
        for(size_t i=0;i<room.enemies.size();++i)
            if(room.enemies[i].boss&&room.enemies[i].alive)alive=true;
        if(!alive&&defeated.count(roomId)==0)OnBossDefeated();
    }
}
void Game::UpdateEnemies(float dt){
    Combat::TickPatrol(dt,room.enemies);
    for(size_t i=0;i<room.enemies.size();++i){
        Enemy &e=room.enemies[i];
        if(!e.alive)continue;
        if(near(hero.position,e.position,e.boss?14.0f:9.0f))DamageHero();
    }
}
void Game::DamageHero(){
    if(hero.invulnerability>0)return;
    hero.invulnerability=1.2f;
    --hero.health;
    notice="GOLPE RECIBIDO";
}
void Game::OnBossDefeated(){
    defeated.insert(roomId);
    notice="GUARDIAN DERROTADO";
    if(roomId=="bone_lord"||roomId=="royal_spire"){
        ++hero.keys;
        notice="LLAVE OBTENIDA";
    }
    if(roomId=="nest")notice="NIDO LIBERADO";
    if(roomId=="aurora_core")notice="SANTUARIO DEL ALBA LIBERADO";
}
void Game::Collect(){
    for(size_t i=0;i<room.pickups.size();++i){
        Pickup &p=room.pickups[i];
        if(p.taken||p.kind!="coin"||!near(hero.position,p.position,10.0f))continue;
        p.taken=true;collected.insert(p.id);++hero.coins;
    }
}
void Game::Interact(){
    // Doors have priority only when no accessible object occupies the same space.
    for(size_t i=0;i<room.pickups.size();++i){
        Pickup &p=room.pickups[i];
        if(!near(hero.position,p.position,14))continue;
        if(p.kind=="bench"){hero.health=hero.maxHealth;Save("meridian-native.save");notice="DESCANSO Y GUARDADO";return;}
        if(p.kind=="shop"){notice="TIENDA: 12 MONEDAS PARA CURAR";if(hero.coins>=12&&hero.health<hero.maxHealth){hero.coins-=12;hero.health=hero.maxHealth;}return;}
        if(p.kind=="guide"){notice="LIBERA EL NIDO Y REGRESA";return;}
        if(p.taken)continue;
        if(p.kind=="chest"){
            bool bossAlive=false;
            for(size_t k=0;k<room.enemies.size();++k)
                if(room.enemies[k].boss&&room.enemies[k].alive)bossAlive=true;
            if(bossAlive){notice="COFRE PROTEGIDO";return;}
            p.taken=true;collected.insert(p.id);hero.coins+=4;
            const std::string reward=room.record->reward;
            if(reward=="double_jump"){hero.doubleJump=true;notice="DOBLE SALTO"; }
            else if(reward=="dash"){hero.dashUnlocked=true;notice="IMPULSO DESBLOQUEADO";}
            else if(reward=="ending"){completed=true;postgame=true;notice="AVENTURA COMPLETADA";}
            else notice="COFRE ABIERTO";
            return;
        }
        if(p.kind=="lever"){p.taken=true;collected.insert(p.id);notice="MECANISMO ACTIVADO";return;}
        if(p.kind=="crate"){p.taken=true;collected.insert(p.id);++hero.coins;notice="CAJA ROTA";return;}
    }
    for(size_t i=0;i<room.doors.size();++i){
        const Door d=room.doors[i];
        if(!near(hero.position,Vec2(d.x,d.y),17))continue;
        if(!GateOpen(d)){notice="ACCESO BLOQUEADO";return;}
        EnterRoom(d.target,roomId);
        return;
    }
}
bool Game::Save(const std::string &path)const{
    if(!started)return false;
    std::ofstream f(path.c_str(),std::ios::out|std::ios::trunc);
    if(!f)return false;
    f<<"MERIDIAN_NATIVE_1\n"<<roomId<<"\n"<<hero.coins<<" "<<hero.health<<" "
        <<hero.maxHealth<<" "<<hero.keys<<" "<<hero.doubleJump<<" "<<hero.dashUnlocked<<" "
        <<completed<<" "<<postgame<<" "<<weaponIndex<<"\n";
    const std::set<std::string>* groups[]={&visited,&collected,&defeated};
    for(int i=0;i<3;++i){
        f<<groups[i]->size()<<"\n";
        for(std::set<std::string>::const_iterator it=groups[i]->begin();it!=groups[i]->end();++it)f<<*it<<"\n";
    }
    return f.good();
}
bool Game::Load(const std::string &path){
    std::ifstream f(path.c_str());
    std::string magic,roomName;
    if(!std::getline(f,magic)||magic!="MERIDIAN_NATIVE_1")return false;
    if(!std::getline(f,roomName)||!FindRoom(roomName))return false;
    Hero loaded;
    int doubleJumpFlag,dashFlag,completedFlag,postgameFlag,newWeapon;
    if(!(f>>loaded.coins>>loaded.health>>loaded.maxHealth>>loaded.keys
        >>doubleJumpFlag>>dashFlag>>completedFlag>>postgameFlag>>newWeapon))return false;
    if(loaded.coins<0||loaded.coins>1000000||loaded.health<1||loaded.health>12||
       loaded.maxHealth<3||loaded.maxHealth>12||loaded.keys<0||loaded.keys>2)return false;
    std::set<std::string> groups[3];
    for(int i=0;i<3;++i){
        unsigned count=0;
        if(!(f>>count)||count>100000)return false;
        for(unsigned j=0;j<count;++j){
            std::string item;
            if(!(f>>item)||item.size()>160)return false;
            groups[i].insert(item);
        }
    }
    started=true;paused=false;hero=loaded;
    hero.doubleJump=doubleJumpFlag!=0;
    hero.dashUnlocked=dashFlag!=0;
    completed=completedFlag!=0;postgame=postgameFlag!=0;
    weaponIndex=std::max(0,std::min(2,newWeapon));
    visited=groups[0];collected=groups[1];defeated=groups[2];
    EnterRoom(roomName,"");
    notice="PARTIDA CARGADA";
    return true;
}
}
