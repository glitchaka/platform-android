#pragma once
// Achievement catalogue ported from the original game; entirely native C++.
#include "Game.hpp"
#include <algorithm>
#include <cstring>
namespace meridian {
struct Achievement {
    const char *id,*name,*description;
    int target;
};
class Milestones {
public:
    static int Count(){return 20;}
    static const Achievement &At(int index){
        static const Achievement achievements[]={
            {"first_chest","CURIOSIDAD","Abre tu primer cofre.",1},
            {"nest","CAMINO LIBRE","Vence al guardian del Nido.",1},
            {"double","ENTRE LAS ESPORAS","Encuentra el doble salto.",1},
            {"explorer","EXPLORADOR","Visita 18 salas distintas.",18},
            {"bone","CAIDA DEL PRINCIPE","Vence al Principe de Huesos.",1},
            {"dash","SIN FRENOS","Encuentra el impulso.",1},
            {"royal","FIN DE LA GUARDIA","Vence al guardian real.",1},
            {"keys","DOS LLAVES","Recoge ambas llaves de guardianes.",2},
            {"treasure","BUSCATESOROS","Abre 15 cofres distintos.",15},
            {"hunter","PROTECTOR","Derrota a 40 enemigos distintos.",40},
            {"ending","NUEVO AMANECER","Restaura el Meridiano.",1},
            {"atlas","CADA RINCON","Visita las 52 salas originales.",52},
            {"post_1","CAMINOS SEGUROS","Finaliza la mision 1.",1},
            {"post_2","VIDA EN EL ABISMO","Finaliza la mision 2.",1},
            {"post_3","DEUDA SALDADA","Finaliza la mision 3.",1},
            {"post_4","FORJA RESTAURADA","Finaliza la mision 4.",1},
            {"post_5","CINCO JURAMENTOS","Finaliza las cinco misiones.",1},
            {"clean_trials","SIN UNA HERIDA","Vence tres ecos sin recibir golpes.",3},
            {"speed_trials","TRES RELAMPAGOS","Vence cada eco antes de 12s.",3},
            {"marathon","INQUEBRANTABLE","Vence tres ecos en el Trono sin curas.",1}
        };
        return achievements[index>=0&&index<Count()?index:0];
    }
    static int Progress(const Game &game,const Achievement &achievement){
        const char *id=achievement.id;
        if(!std::strcmp(id,"first_chest"))return game.ChestCount()>0?1:0;
        if(!std::strcmp(id,"nest"))return game.HasDefeated("nest")?1:0;
        if(!std::strcmp(id,"double"))return game.Player().doubleJump?1:0;
        if(!std::strcmp(id,"explorer"))return (int)game.VisitedCount();
        if(!std::strcmp(id,"bone"))return game.HasDefeated("bone_lord")?1:0;
        if(!std::strcmp(id,"dash"))return game.Player().dashUnlocked?1:0;
        if(!std::strcmp(id,"royal"))return game.HasDefeated("royal_spire")?1:0;
        if(!std::strcmp(id,"keys"))return game.Player().keys;
        if(!std::strcmp(id,"treasure"))return (int)game.ChestCount();
        if(!std::strcmp(id,"hunter"))return (int)game.EnemyKillCount();
        if(!std::strcmp(id,"ending"))return game.IsCompleted()?1:0;
        if(!std::strcmp(id,"atlas"))return (int)game.VisitedCount();
        if(!std::strncmp(id,"post_",5)){
            const int goal=std::atoi(id+5);
            return game.PostgameStage()>=goal?1:0;
        }
        if(!std::strcmp(id,"clean_trials")){
            int count=0;
            for(const char *room:{"nest","bone_lord","royal_spire"})
                if(game.HasCollected(std::string("trial:clean:")+room))++count;
            return count;
        }
        if(!std::strcmp(id,"speed_trials")){
            int count=0;
            for(const char *room:{"nest","bone_lord","royal_spire"})
                if(game.HasCollected(std::string("trial:speed:")+room))++count;
            return count;
        }
        if(!std::strcmp(id,"marathon"))return game.HasCollected("trial:marathon")?1:0;
        return 0;
    }
    static bool Unlocked(const Game &game,const Achievement &achievement){
        return Progress(game,achievement)>=achievement.target;
    }
    static int Completed(const Game &game){
        int count=0;
        for(int i=0;i<Count();++i)if(Unlocked(game,At(i)))++count;
        return count;
    }
};
} // namespace meridian
