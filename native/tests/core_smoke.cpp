#include "../core/Game.hpp"
#include "../core/Combat.hpp"
#include "../core/Weapons.hpp"
#include <cstdio>
#include <cstdlib>
#include <set>
using namespace meridian;
static void require(bool value,const char *message){
    if(!value){std::fprintf(stderr,"FAIL: %s\n",message);std::exit(1);}
}
int main(){
    require(RoomCount()==55,"The native room catalog contains all 55 rooms");
    require(LinkCount()==65,"The native graph contains all 65 actual links");
    std::set<std::string> empty;
    Room tutorial=CreateRoom("tutorial",empty,empty);
    require(tutorial.record!=NULL,"Tutorial exists");
    require(tutorial.platforms.size()>=4,"Tutorial collision platforms exist");
    require(tutorial.doors.size()==1,"Tutorial has one outward door");
    require(tutorial.doors[0].target=="town","Tutorial connects to Town");
    require(!tutorial.enemies.empty(),"Tutorial has a playable enemy");
    require(Combat::Fraction(Vec2(0,0),Vec2(10,0),Vec2(5,0),1)>0,"Swept hit returns a valid fraction");
    require(Combat::Fraction(Vec2(0,0),Vec2(10,0),Vec2(5,6),1)<0,"Swept hit rejects misses");
    Game game;
    game.NewGame();
    require(game.IsStarted(),"New game starts");
    require(Arsenal::IndexOf("phoenix")==5,"All six original weapons are enumerated");
    require(Arsenal::Stats(1,3).pellets==5,"Upgraded shotgun fires five pellets");
    require(Arsenal::Stats(4,2).burst==3,"Tempest fires three-bullet bursts");
    require(Arsenal::Stats(5,3).burn==5,"Phoenix has the original maximum burn");
    require(game.GrantWeapon(1),"Unlocking shotgun succeeds");
    require(game.WeaponIndex()==1,"New weapon is equipped");
    require(game.Weapon(1).owned,"Granted weapon is owned");
    require(game.RoomId()=="tutorial","New game starts in tutorial");
    Input input;input.right=true;
    const float x=game.Player().position.x;
    for(int frame=0;frame<5;++frame)game.Tick(0.02f,input);
    require(game.Player().position.x>x,"Right movement advances the hero");
    Input fire;fire.fire=true;
    game.Tick(0.02f,fire);
    require(!game.Shots().empty(),"Weapon spawns a projectile");
    require(game.Save("native_smoke.save"),"Native save writes to disk");
    Game reload;
    require(reload.Load("native_smoke.save"),"Save reload succeeds");
    require(reload.RoomId()==game.RoomId(),"Save restores the room");
    require(reload.Player().coins==game.Player().coins,"Save restores coin count");
    require(reload.Weapon(1).owned&&reload.WeaponIndex()==1,"Save restores unlocked weapon and selection");
    std::remove("native_smoke.save");
    std::puts("Native core: 55 rooms, 65 links, physics, shooting and save/load OK.");
    return 0;
}
