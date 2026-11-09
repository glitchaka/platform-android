#pragma once
#include "Types.hpp"
#include <set>
#include <string>
namespace meridian {
struct PostQuest { const char *name; int reward,roomCount; const char *const *rooms; };
class Postgame {
public:
    static const PostQuest &Quest(int stage);
    static int Stage(const std::set<std::string> &collected);
    static int Recovered(int stage,const std::set<std::string> &collected);
    static bool IsTarget(int stage,const std::string &room);
    static std::string Token(int stage,const std::string &room);
    static std::string SwitchToken(int stage,const std::string &room);
    static std::string GuardToken(int stage,const std::string &room,int index);
    static bool Complete(const std::set<std::string> &collected);
    static void EnterRoom(Room &room,bool completed,const std::set<std::string> &collected);
};
}
