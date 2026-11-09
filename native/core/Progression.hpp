#pragma once
#include <set>
#include <string>
namespace meridian {
struct RelicEntry { const char *id,*name; int attack,armor; };
class Progression {
public:
    static const RelicEntry &Campaign(int rank);
    static bool Has(int rank,const std::set<std::string> &collected,
                    const std::set<std::string> &defeated,bool doubleJump,bool dash);
    static int AttackBonus(const std::set<std::string> &collected,
                           const std::set<std::string> &defeated,bool doubleJump,bool dash);
    static int ArmorBonus(const std::set<std::string> &collected,
                          const std::set<std::string> &defeated,bool doubleJump,bool dash);
    static bool CanEnter(int rank,const std::set<std::string> &collected,
                         const std::set<std::string> &defeated,bool doubleJump,bool dash,
                         bool finalZoneUnlocked);
};
}
