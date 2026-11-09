#pragma once
#include "Types.hpp"
#include <set>
#include <string>
namespace meridian {
// Explicit postgame combat challenges from the original Scripts/postgame.gd.
class Trials {
public:
    Trials();
    void Reset();
    void Tick(float seconds);
    void OnHit();
    void OnHeal();
    bool Start(Room &room,const std::string &id);
    bool Advance(Room &room,std::set<std::string> &collected,int &coins,std::string &notice);
    bool Active() const{return active;}
    int Round()const{return round;}
    float Elapsed()const{return elapsed;}
    const std::string &Location()const{return location;}
    static bool HasThreeClean(const std::set<std::string> &collected);
    static bool HasThreeFast(const std::set<std::string> &collected);
    static bool HasMarathon(const std::set<std::string> &collected);
    static bool IsTrialRoom(const std::string &id);
private:
    void Spawn(Room &room);
    std::string location;
    float elapsed;
    int hits,round;
    bool healed,active;
};
}
