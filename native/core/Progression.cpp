#include "Progression.hpp"
#include "Postgame.hpp"
#include <algorithm>
namespace meridian {
namespace {
const RelicEntry kCampaign[] = {
    {"path_medal","MEDALLA DEL SENDERO",1,1},
    {"nest_amulet","AMULETO DEL NIDO",1,1},
    {"living_sprout","BROTE VITAL",1,1},
    {"bone_key","LLAVE DE HUESOS",1,1},
    {"royal_crest","INSIGNIA REAL",1,1}
};
}
const RelicEntry &Progression::Campaign(int rank){
    return kCampaign[std::max(0,std::min(4,rank))];
}
bool Progression::Has(int rank,const std::set<std::string> &collected,
                      const std::set<std::string> &defeated,bool doubleJump,bool dash){
    switch(rank){
        case 0:return collected.count("tutorial:chest")!=0;
        case 1:return collected.count("quest:paid")!=0;
        case 2:return doubleJump;
        case 3:return defeated.count("bone_lord")!=0;
        case 4:return dash&&defeated.count("royal_spire")!=0;
        default:return false;
    }
}
int Progression::AttackBonus(const std::set<std::string> &collected,
                             const std::set<std::string> &defeated,bool dj,bool dash){
    int bonus=0;for(int i=0;i<5;++i)if(Has(i,collected,defeated,dj,dash))bonus+=kCampaign[i].attack;
    return bonus+2*Postgame::Stage(collected);
}
int Progression::ArmorBonus(const std::set<std::string> &collected,
                            const std::set<std::string> &defeated,bool dj,bool dash){
    int bonus=0;for(int i=0;i<5;++i)if(Has(i,collected,defeated,dj,dash))bonus+=kCampaign[i].armor;
    return bonus+Postgame::Stage(collected);
}
bool Progression::CanEnter(int rank,const std::set<std::string> &collected,
                           const std::set<std::string> &defeated,bool dj,bool dash,bool finalZoneUnlocked){
    if(rank<=0)return true;
    if(rank>=6)return finalZoneUnlocked;
    return Has(rank-1,collected,defeated,dj,dash);
}
}
