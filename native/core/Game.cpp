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
bool nearbyPoint(const Vec2 &a,const Vec2 &b,float limit){
    const float dx=a.x-b.x,dy=a.y-b.y;
    return dx*dx+dy*dy<limit*limit;
}
}
Game::Game():started(false),paused(false),completed(false),postgame(false),weaponIndex(0),shopOpen(false),shopCursor(0),enemyTime(0),noticeTime(0){}
void Game::NewGame(){
    visited.clear();collected.clear();defeated.clear();shots.clear();
    hero=Hero();previous=Input();completed=false;postgame=false;paused=false;
    weaponIndex=0;Arsenal::Reset(weapons);shop=ShopState();shopOpen=false;shopCursor=0;started=true;notice="NUEVA PARTIDA";
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
    if(!Progression::CanEnter(RoomRank(d.target),collected,defeated,
        hero.doubleJump,hero.dashUnlocked,false))return false;
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
    if(shopOpen){
        if(input.weaponNext&&!previous.weaponNext){shopOpen=false;notice="TIENDA CERRADA";}
        else if(input.left&&!previous.left)shopCursor=(shopCursor+kShopItemCount-1)%kShopItemCount;
        else if(input.right&&!previous.right)shopCursor=(shopCursor+1)%kShopItemCount;
        else if((input.interact&&!previous.interact)||(input.jump&&!previous.jump))BuySelected();
        previous=input;return;
    }
    if(input.pause&&!previous.pause)paused=!paused;
    if(input.save&&!previous.save){Save("meridian-native.save");notice="PARTIDA GUARDADA";}
    if(paused){previous=input;return;}
    if(input.heal&&!previous.heal)Heal();
    hero.shotCooldown=std::max(0.0f,hero.shotCooldown-dt);
    hero.invulnerability=std::max(0.0f,hero.invulnerability-dt);
    hero.dashTimer=std::max(0.0f,hero.dashTimer-dt);
    hero.dashCooldown=std::max(0.0f,hero.dashCooldown-dt);
    noticeTime=std::max(0.0f,noticeTime-dt);
    if(input.weaponNext&&!previous.weaponNext)NextWeapon();
    Move(dt,input);
    const WeaponStats stats=Arsenal::Stats(weaponIndex,weapons[weaponIndex].level);
    if(input.fire&&hero.shotCooldown<=0&&(!previous.fire||stats.automatic||shop.Has("rapid")))Fire();
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
bool Game::GrantWeapon(int index){
    if(index<0||index>=kWeaponCount||weapons[index].owned)return false;
    weapons[index].owned=true;
    weapons[index].durability=static_cast<float>(Arsenal::Info(index).capacity);
    weapons[index].level=0;
    weaponIndex=index;
    notice=Arsenal::Info(index).name;
    return true;
}
void Game::NextWeapon(){
    for(int next=1;next<=kWeaponCount;++next){
        const int candidate=(weaponIndex+next)%kWeaponCount;
        if(!weapons[candidate].owned)continue;
        weaponIndex=candidate;
        notice=Arsenal::Info(weaponIndex).name;
        break;
    }
}
void Game::Fire(){
    if(weapons[weaponIndex].durability<=0&&weaponIndex!=0){
        weaponIndex=0;notice="ARMA AGOTADA. EQUIPADA PISTOLA";return;
    }
    WeaponStats stats=Arsenal::Stats(weaponIndex,weapons[weaponIndex].level);
    if(weaponIndex==0&&weapons[0].durability<=0){
        stats.damage=1;stats.interval=0.55f;stats.pierce=0;stats.range=130.0f;
    }
    const int relicStrength=Progression::AttackBonus(collected,defeated,
                                      hero.doubleJump,hero.dashUnlocked);
    stats.damage+=(shop.Has("power")?1:0)+relicStrength;
    if(stats.burn>0)stats.burn+=relicStrength/2;
    if(shop.Has("rapid"))stats.interval*=0.5f;
    hero.shotCooldown=stats.interval;
    const float f=hero.facing;
    for(int burst=0;burst<stats.burst;++burst){
        for(int pellet=0;pellet<stats.pellets;++pellet){
            const float ratio=stats.pellets>1?float(pellet)/float(stats.pellets-1):0.5f;
            const float angle=-stats.spread+2.0f*stats.spread*ratio;
            Bullet b;
            b.position=Vec2(hero.position.x+f*6.0f,hero.position.y-1);
            b.velocity=Vec2(f*std::cos(angle)*stats.speed,
                             f*std::sin(angle)*stats.speed);
            b.remaining=stats.range;b.damage=stats.damage;
            b.pierce=stats.pierce;b.burn=stats.burn;
            b.radius=stats.radius;b.delay=float(burst)*0.055f;
            shots.push_back(b);
        }
    }
    weapons[weaponIndex].durability=std::max(0.0f,weapons[weaponIndex].durability-1.0f);
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
    Combat::TickPatrol(dt,room.enemies,hero.coins,hero.position);
    for(size_t i=0;i<room.enemies.size();++i){
        Enemy &e=room.enemies[i];
        if(!e.alive)continue;
        if(std::fabs(hero.position.x-e.position.x)<(e.boss?12.0f:8.0f) &&
           std::fabs(hero.position.y-e.position.y)<(e.boss?14.0f:8.0f))
            DamageHero(e.contactDamage);
    }
}
void Game::DamageHero(int amount){
    if(hero.invulnerability>0)return;
    hero.invulnerability=1.2f;
    if(shop.Has("guard")&&shop.guardCharged){
        shop.guardCharged=false;notice="EL AMULETO ABSORBIO EL GOLPE";return;
    }
    const int armor=Progression::ArmorBonus(collected,defeated,
                                  hero.doubleJump,hero.dashUnlocked);
    hero.health=std::max(0,hero.health-std::max(1,amount-armor));
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
        if(p.taken||p.kind!="coin"||!nearbyPoint(hero.position,p.position,shop.Has("magnet")?30.0f:10.0f))continue;
        p.taken=true;collected.insert(p.id);++hero.coins;
    }
}
void Game::Interact(){
    // Doors have priority only when no accessible object occupies the same space.
    for(size_t i=0;i<room.pickups.size();++i){
        Pickup &p=room.pickups[i];
        if(!nearbyPoint(hero.position,p.position,14))continue;
        if(p.kind=="bench"){
            hero.health=hero.maxHealth;
            weapons[0].durability=(float)Arsenal::Info(0).capacity;
            if(shop.Has("flask"))shop.flaskCharges=1;
            if(shop.Has("guard"))shop.guardCharged=true;
            Save("meridian-native.save");notice="DESCANSO Y GUARDADO";return;
        }
        if(p.kind=="shop"){
            shopOpen=true;shopCursor=0;notice="TIENDA: A/D ELEGIR  E COMPRAR  Q SALIR";
            return;
        }
        if(p.kind=="guide"){
            if(collected.count("quest:started")==0){
                collected.insert("quest:started");
                notice="LIBERA EL NIDO. RECOMPENSA: 6 MONEDAS";
            }else if(defeated.count("nest")!=0&&collected.count("quest:paid")==0){
                collected.insert("quest:paid");hero.coins+=6;
                notice="AMULETO DEL NIDO Y 6 MONEDAS";
            }else notice="LIBERA EL NIDO Y REGRESA";
            return;
        }
        if(p.taken)continue;
        if(p.kind=="chest"){
            if(roomId=="tutorial"&&collected.count("tutorial:lever")==0){
                notice="ACTIVA PRIMERO EL MECANISMO";return;
            }
            bool bossAlive=false;
            for(size_t k=0;k<room.enemies.size();++k)
                if(room.enemies[k].boss&&room.enemies[k].alive)bossAlive=true;
            if(bossAlive){notice="COFRE PROTEGIDO";return;}
            p.taken=true;collected.insert(p.id);hero.coins+=4;
            const std::string reward=room.record->reward;
            if(reward=="double_jump"){hero.doubleJump=true;notice="DOBLE SALTO"; }
            else if(reward=="dash"){hero.dashUnlocked=true;notice="IMPULSO DESBLOQUEADO";}
            else if(reward=="ending"){completed=true;postgame=true;notice="AVENTURA COMPLETADA";}
            else if(reward=="heart"){hero.maxHealth=std::min(8,hero.maxHealth+1);hero.health=hero.maxHealth;notice="CORAZON VITAL";}
            else notice="COFRE ABIERTO";
            return;
        }
        if(p.kind=="lever"){p.taken=true;collected.insert(p.id);notice="MECANISMO ACTIVADO";return;}
        if(p.kind=="crate"){p.taken=true;collected.insert(p.id);++hero.coins;notice="CAJA ROTA";return;}
    }
    for(size_t i=0;i<room.doors.size();++i){
        const Door d=room.doors[i];
        if(!nearbyPoint(hero.position,Vec2(d.x,d.y),17))continue;
        if(!GateOpen(d)){notice="ACCESO BLOQUEADO";return;}
        const std::string fromRoom=roomId;
        EnterRoom(d.target,fromRoom);
        return;
    }
}
ShopAccess Game::AvailableShop()const{
    ShopAccess a;a.nest=defeated.count("nest")!=0;
    a.bone=defeated.count("bone_lord")!=0;
    a.royal=defeated.count("royal_spire")!=0;
    a.ending=completed;a.explorer=visited.size()>=18;
    a.dash=hero.dashUnlocked;
    return a;
}
void Game::Heal(){
    if(hero.health>=hero.maxHealth)return;
    if(shop.flaskCharges>0){--shop.flaskCharges;hero.health=std::min(hero.maxHealth,hero.health+2);notice="FRASCO CURATIVO";return;}
    if(shop.tonics>0){--shop.tonics;hero.health=std::min(hero.maxHealth,hero.health+2);notice="TONICO DE VIAJE";}
}
bool Game::BuySelected(){
    if(!shopOpen)return false;
    const ShopItem &item=ShopCatalog::Item(shopCursor);
    const std::string id=item.id;
    const ShopAccess a=AvailableShop();
    if(!ShopCatalog::GateOpen(item,a)){notice="AUN NO DISPONIBLE";return false;}
    if(ShopCatalog::IsOneTime(item.id)&&shop.Has(id)){notice="YA ADQUIRIDO";return false;}
    if(id=="shotgun"&&weapons[1].owned){notice="ESCOPETA ADQUIRIDA";return false;}
    if(id=="flame"&&weapons[2].owned){notice="LANZALLAMAS ADQUIRIDO";return false;}
    if(id=="heart"&&(shop.heartPurchases>=2||hero.maxHealth>=8)){notice="MAXIMO DE CORAZONES";return false;}
    if(id=="tonic"&&shop.tonics>=shop.TonicCapacity()){notice="BOLSA LLENA";return false;}
    if(id=="heal"&&hero.health>=hero.maxHealth){notice="SALUD COMPLETA";return false;}
    if(id=="forge"){
        const int level=weapons[weaponIndex].level;
        if(level>=3){notice="NIVEL MAXIMO";return false;}
        if((level==0&&!a.bone)||(level==1&&!a.royal)||(level==2&&!completed)){
            notice="MEJORA BLOQUEADA";return false;
        }
    }
    if(id=="repair"&&weapons[weaponIndex].durability>=Arsenal::Info(weaponIndex).capacity){
        notice="ARMA REPARADA";return false;
    }
    const int price=ShopCatalog::Price(item,shop,weapons[weaponIndex],weaponIndex);
    if(hero.coins<price){notice="MONEDAS INSUFICIENTES";return false;}
    hero.coins-=price;
    if(id=="shotgun")GrantWeapon(1);
    else if(id=="flame")GrantWeapon(2);
    else if(id=="forge"){++weapons[weaponIndex].level;weapons[weaponIndex].durability=(float)Arsenal::Info(weaponIndex).capacity;}
    else if(id=="repair"){weapons[weaponIndex].durability=(float)Arsenal::Info(weaponIndex).capacity;}
    else if(id=="heart"){++shop.heartPurchases;++hero.maxHealth;hero.health=hero.maxHealth;}
    else if(id=="heal")hero.health=hero.maxHealth;
    else if(id=="tonic")++shop.tonics;
    else if(id=="flask"){shop.flaskCharges=1;shop.owned.insert(id);}
    else if(id=="guard"){shop.guardCharged=true;shop.owned.insert(id);}
    else if(id=="ember"){shop.style=1;shop.owned.insert(id);}
    else if(id=="storm"){shop.style=2;shop.owned.insert(id);}
    else if(id=="starlight"){shop.style=3;shop.owned.insert(id);}
    else shop.owned.insert(id);
    notice=std::string("COMPRADO: ")+item.name;
    Save("meridian-native.save");
    return true;
}
bool Game::Save(const std::string &path)const{
    if(!started)return false;
    std::ofstream f(path.c_str(),std::ios::out|std::ios::trunc);
    if(!f)return false;
    f<<"MERIDIAN_NATIVE_3\n"<<roomId<<"\n"<<hero.coins<<" "<<hero.health<<" "
        <<hero.maxHealth<<" "<<hero.keys<<" "<<hero.doubleJump<<" "<<hero.dashUnlocked<<" "
        <<completed<<" "<<postgame<<" "<<weaponIndex<<"\n";
    const std::set<std::string>* groups[]={&visited,&collected,&defeated};
    for(int i=0;i<3;++i){
        f<<groups[i]->size()<<"\n";
        for(std::set<std::string>::const_iterator it=groups[i]->begin();it!=groups[i]->end();++it)f<<*it<<"\n";
    }
    for(int i=0;i<kWeaponCount;++i)
        f<<weapons[i].owned<<" "<<weapons[i].level<<" "<<weapons[i].durability<<"\n";
    f<<shop.heartPurchases<<" "<<shop.tonics<<" "<<shop.flaskCharges<<" "<<shop.style<<" "<<shop.guardCharged<<"\n";
    f<<shop.owned.size()<<"\n";
    for(std::set<std::string>::const_iterator it=shop.owned.begin();it!=shop.owned.end();++it)f<<*it<<"\n";
    return f.good();
}
bool Game::Load(const std::string &path){
    std::ifstream f(path.c_str());
    std::string magic,roomName;
    if(!std::getline(f,magic)||
        (magic!="MERIDIAN_NATIVE_1"&&magic!="MERIDIAN_NATIVE_2"&&magic!="MERIDIAN_NATIVE_3"))return false;
    const bool newer=(magic!="MERIDIAN_NATIVE_1");
    const bool shopSaved=(magic=="MERIDIAN_NATIVE_3");
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
    WeaponState restored[kWeaponCount];
    Arsenal::Reset(restored);
    if(newer){
        for(int i=0;i<kWeaponCount;++i){
            int owned=0,level=0;float durability=0;
            if(!(f>>owned>>level>>durability))return false;
            if(owned<0||owned>1||level<0||level>3||
                !(durability>=0)||durability>Arsenal::Info(i).capacity)return false;
            restored[i].owned=(owned!=0);
            restored[i].level=level;
            restored[i].durability=durability;
        }
        if(!restored[0].owned)return false;
    }
    ShopState restoredShop;
    if(shopSaved){
        int guard=0;
        if(!(f>>restoredShop.heartPurchases>>restoredShop.tonics>>restoredShop.flaskCharges
             >>restoredShop.style>>guard))return false;
        if(restoredShop.heartPurchases<0||restoredShop.heartPurchases>2||
           restoredShop.tonics<0||restoredShop.tonics>5||
           restoredShop.flaskCharges<0||restoredShop.flaskCharges>1||
           restoredShop.style<0||restoredShop.style>3||
           guard<0||guard>1)return false;
        restoredShop.guardCharged=(guard!=0);
        unsigned count=0;
        if(!(f>>count)||count>kShopItemCount)return false;
        for(unsigned i=0;i<count;++i){
            std::string id;
            if(!(f>>id)||id.size()>64)return false;
            bool valid=false;
            for(int k=0;k<kShopItemCount;++k)if(id==ShopCatalog::Item(k).id)valid=true;
            if(!valid)return false;
            restoredShop.owned.insert(id);
        }
    }
    started=true;paused=false;hero=loaded;shop=restoredShop;shopOpen=false;shopCursor=0;
    for(int i=0;i<kWeaponCount;++i)weapons[i]=restored[i];
    hero.doubleJump=doubleJumpFlag!=0;
    hero.dashUnlocked=dashFlag!=0;
    completed=completedFlag!=0;postgame=postgameFlag!=0;
    weaponIndex=std::max(0,std::min(kWeaponCount-1,newWeapon));
    if(!weapons[weaponIndex].owned)weaponIndex=0;
    visited=groups[0];collected=groups[1];defeated=groups[2];
    EnterRoom(roomName,"");
    notice="PARTIDA CARGADA";
    return true;
}
}
