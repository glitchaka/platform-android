#pragma once
#include "World.hpp"
#include "Weapons.hpp"
#include "Shop.hpp"
#include "Progression.hpp"
#include <set>
#include <string>
namespace meridian {
struct Hero {
    Vec2 position,velocity;
    int health,maxHealth,coins,keys,jumps;
    float facing,invulnerability,dashTimer,dashCooldown,shotCooldown;
    bool grounded,doubleJump,dashUnlocked;
    Hero():position(24,100),velocity(),health(3),maxHealth(3),coins(0),keys(0),jumps(0),
        facing(1),invulnerability(0),dashTimer(0),dashCooldown(0),shotCooldown(0),
        grounded(false),doubleJump(false),dashUnlocked(false){}
};
class Game {
public:
    Game();
    void NewGame();
    bool Load(const std::string &path);
    bool Save(const std::string &path) const;
    void Tick(float dt,const Input &input);
    bool IsStarted() const {return started;}
    bool IsPaused() const {return paused;}
    const Room &CurrentRoom()const{return room;}
    const Hero &Player()const{return hero;}
    const std::vector<Bullet> &Shots()const{return shots;}
    const std::string &RoomId()const{return roomId;}
    const std::string &Notice()const{return notice;}
    bool HasVisited(const std::string &id)const{return visited.count(id)!=0;}
    bool HasDefeated(const std::string &id)const{return defeated.count(id)!=0;}
    bool IsCompleted()const{return completed;}
    bool IsPostgame()const{return postgame;}
    int WeaponIndex()const{return weaponIndex;}
    const WeaponState &Weapon(int index)const{return weapons[index>=0&&index<kWeaponCount?index:0];}
    const WeaponInfo &EquippedWeapon()const{return Arsenal::Info(weaponIndex);}
    bool IsShopOpen()const{return shopOpen;}
    int ShopCursor()const{return shopCursor;}
    const ShopState &Purchases()const{return shop;}
    int TonicCount()const{return shop.tonics;}
    ShopAccess AvailableShop()const;
    bool GrantWeapon(int index);
    void NextWeapon();
private:
    void EnterRoom(const std::string &id,const std::string &from);
    void Move(float dt,const Input &input);
    void Fire();
    void Attack(float dt);
    void Interact();
    bool BuySelected();
    void Heal();
    void Collect();
    void UpdateEnemies(float dt);
    bool GateOpen(const Door &door)const;
    void OnBossDefeated();
    void DamageHero(int amount=1);
    bool started,paused,completed,postgame;
    int weaponIndex;
    WeaponState weapons[kWeaponCount];
    ShopState shop;
    bool shopOpen;
    int shopCursor;
    std::string roomId,notice;
    Room room;
    Hero hero;
    std::vector<Bullet> shots;
    std::set<std::string> visited,collected,defeated;
    Input previous;
    float enemyTime,noticeTime;
};
}
