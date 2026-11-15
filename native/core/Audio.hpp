#pragma once
// Audio routing is gameplay data; idTech's sound backend performs playback.
#include "Game.hpp"
#include <string>
namespace meridian {
class Audio {
public:
    static const char *Track(const Game &game){
        const Room &room=game.CurrentRoom();
        if(!room.record)return "title";
        const std::string id=room.record->id;
        const std::string zone=room.record->zone;
        if(id=="nest")return "nest";
        if(std::string(room.record->reward)=="boss"&&!game.HasDefeated(id))
            return "boss";
        if(zone=="aurora")return "palace";
        if(zone=="tutorial"||zone=="town"||zone=="cross"||zone=="fungus"||
           zone=="bone"||zone=="city"||zone=="palace"||zone=="deep")return room.record->zone;
        return "cross";
    }
    static const char *EffectFromNotice(const std::string &notice){
        if(notice.find("COFRE")!=std::string::npos)return "chest";
        if(notice.find("COMPRA")!=std::string::npos)return "buy";
        if(notice.find("MONEDA")!=std::string::npos)return "coin";
        if(notice.find("LLAVE")!=std::string::npos)return "key";
        if(notice.find("GUARDIAN DERROTADO")!=std::string::npos)return "boss_down";
        if(notice.find("REAPARECES")!=std::string::npos)return "death";
        if(notice.find("CURATIV")!=std::string::npos||notice.find("TONICO")!=std::string::npos)return "heal";
        if(notice.find("DANO")!=std::string::npos||notice.find("GOLPE")!=std::string::npos)return "hurt";
        if(notice.find("MECANISMO")!=std::string::npos)return "switch";
        if(notice.find("TIENDA CERRADA")!=std::string::npos)return "menu";
        if(notice.find("ACCESO BLOQUEADO")!=std::string::npos)return "error";
        if(notice.find("DESBLOQUEADO")!=std::string::npos)return "achievement";
        return nullptr;
    }
};
} // namespace meridian
