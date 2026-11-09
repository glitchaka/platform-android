// Embedded into idTech 4's Game_local.cpp by native/tools/prepare_desktop.py.
// Runs in the engine's rendering context; not a separate graphics framework.
// idTech 4 defines NULL as idNullPtr. Modern std::once_flag and STL constexpr
// constructors cannot compile while that macro replaces null pointer constants.
#ifdef NULL
#pragma push_macro("NULL")
#undef NULL
#define NULL nullptr
#define MERIDIAN_ENGINE_NULL_RESTORE
#endif
// Force the current C++ library's constexpr/nullptr machinery to load before
// restoring idTech's user-defined NULL macro.
#include <mutex>
#include <functional>
#include <fstream>
#include <sstream>
#include "../core/World.cpp"
#include "../core/Combat.cpp"
#include "../core/Weapons.cpp"
#include "../core/Shop.cpp"
#include "../core/Game.cpp"
#include "../generated/AtlasDimensions.hpp"
#ifdef MERIDIAN_ENGINE_NULL_RESTORE
#pragma pop_macro("NULL")
#undef MERIDIAN_ENGINE_NULL_RESTORE
#endif

// Dedicated native mode: game state and UI come from Ashen Meridian,
// not from the DOOM campaign, SWF shell, or a loaded map.
idCVar meridian_native("meridian_native","1",CVAR_BOOL|CVAR_GAME,"run Ashen Meridian directly on idTech 4");

namespace {
meridian::Game g_meridian;
bool g_meridianVisible=false;
int g_meridianLastMs=0;

bool MeridianKey(int key){return idKeyInput::IsDown(key);}
idVec4 MeridianColor(float r,float g,float b,float a=1.0f){return idVec4(r,g,b,a);}
void MeridianFill(float x,float y,float w,float h,const idVec4 &color){
    renderSystem->DrawFilled(color,x,y,w,h);
}
const idMaterial *MeridianMaterial(const char *name){return declManager->FindMaterial(name);}
void MeridianAtlas(const char *material,float px,float py,float w,float h,float sx,float sy,float sw,float sh,float texW,float texH,const idVec4 &tint){
    renderSystem->SetColor(tint);
    renderSystem->DrawStretchPic(px,py,w,h,sx/texW,sy/texH,(sx+sw)/texW,(sy+sh)/texH,MeridianMaterial(material));
    renderSystem->SetColor(MeridianColor(1,1,1));
}
// The UI uses the exact 8x8 bitmap alphabet from Resource/UI.png.
void MeridianText(int x,int y,const char *text,const idVec4 &color){
    int cursor=x;
    for(const unsigned char *p=(const unsigned char *)text;*p;++p){
        unsigned char c=*p;
        if(c==0xC3 && p[1]){
            // UTF-8 Spanish accents are normalized only for the pixel alphabet.
            const unsigned char n=*++p;
            switch(n){
                case 0x81:case 0xA1:c='A';break;
                case 0x89:case 0xA9:c='E';break;
                case 0x8D:case 0xAD:c='I';break;
                case 0x93:case 0xB3:c='O';break;
                case 0x9A:case 0xBA:c='U';break;
                case 0x91:case 0xB1:c='N';break;
                default:c=' ';break;
            }
        }
        if(c=='\\n'){cursor=x;y+=10;continue;}
        if(c>='a'&&c<='z')c=(unsigned char)(c-'a'+'A');
        int gx=-1,gy=0;
        if(c>='A'&&c<='Z'){
            int i=c-'A';gx=(i%13)*8;gy=88+(i/13)*8;
        }else if(c>='0'&&c<='9'){
            gx=(c-'0')*8;gy=64;
        }else{
            const char *punct=".!?,':;+-";
            for(int i=0;punct[i];++i)if(c==(unsigned char)punct[i]){gx=i*8;gy=80;break;}
        }
        if(gx>=0)MeridianAtlas("meridian/ui",(float)cursor,(float)y,8,8,(float)gx,(float)gy,8,8,MERIDIAN_UI_W,MERIDIAN_UI_H,color);
        cursor+=8;
    }
}
void MeridianStart_f(const idCmdArgs &args){
    g_meridianVisible=true;
    meridian_native.SetBool(true);
    g_meridian.NewGame();
    g_meridianLastMs=Sys_Milliseconds();
    common->Printf("Ashen Meridian: new native session started.\\n");
}
void MeridianLoad_f(const idCmdArgs &args){
    g_meridianVisible=true;
    meridian_native.SetBool(true);
    if(!g_meridian.Load("meridian-native.save"))g_meridian.NewGame();
    g_meridianLastMs=Sys_Milliseconds();
}
void MeridianStop_f(const idCmdArgs &args){g_meridianVisible=false;meridian_native.SetBool(false);}
void MeridianRegisterCommands(){
    cmdSystem->AddCommand("meridian_start",MeridianStart_f,CMD_FL_GAME,"starts the native Ashen Meridian game");
    cmdSystem->AddCommand("meridian_load",MeridianLoad_f,CMD_FL_GAME,"loads the last native Ashen Meridian save");
    cmdSystem->AddCommand("meridian_stop",MeridianStop_f,CMD_FL_GAME,"returns to DOOM's renderer");
}
bool Meridian_IsActive(){return g_meridianVisible;}
void Meridian_Tick(){
    if(!g_meridianVisible)return;
    const int now=Sys_Milliseconds();
    const float dt=g_meridianLastMs?float(now-g_meridianLastMs)/1000.0f:0.016f;
    g_meridianLastMs=now;
    meridian::Input in;
    in.left=MeridianKey(K_LEFTARROW)||MeridianKey('a');
    in.right=MeridianKey(K_RIGHTARROW)||MeridianKey('d');
    in.jump=MeridianKey(K_SPACE)||MeridianKey(K_UPARROW)||MeridianKey('w');
    in.fire=MeridianKey('j');
    in.interact=MeridianKey('e')||MeridianKey(K_DOWNARROW);
    in.dash=(MeridianKey(K_LSHIFT)||MeridianKey(K_RSHIFT))||MeridianKey('k');
    in.pause=MeridianKey(K_ESCAPE);
    in.save=MeridianKey('p');
    in.weaponNext=MeridianKey('q');
    in.heal=MeridianKey('f');
    g_meridian.Tick(dt,in);
}
void Meridian_Draw(){
    if(!g_meridianVisible)return;
    const meridian::Room &room=g_meridian.CurrentRoom();
    if(!room.record)return;
    const meridian::Hero &h=g_meridian.Player();
    const float scale=2.0f,yOffset=60.0f;
    const float cameraX=std::max(0.0f,std::min(h.position.x-160.0f,(float)room.record->width-320.0f));
    const float cameraY=std::max(0.0f,std::min(h.position.y-90.0f,(float)room.record->height-180.0f));
    MeridianFill(0,0,640,480,MeridianColor(0.07f,0.09f,0.11f));
    MeridianFill(0,yOffset,640,360,MeridianColor(0.12f,0.15f,0.16f));
    const idVec4 ground=MeridianColor(0.31f,0.36f,0.34f);
    for(size_t i=0;i<room.platforms.size();++i){
        const meridian::Rect &r=room.platforms[i];
        const float x=(r.x-cameraX)*scale,y=yOffset+(r.y-cameraY)*scale;
        MeridianFill(x,y,r.w*scale,r.h*scale,ground);
        const std::string biome=room.record->zone;
        const float sourceY=(biome=="fungus"||biome=="aurora")?0.0f:
                            biome=="bone"?160.0f:(biome=="city"||biome=="deep")?320.0f:520.0f;
        for(int tile=0;tile<(int)r.w;tile+=8){
            const float tw=std::min(8.0f,r.w-tile);
            MeridianAtlas("meridian/tiles",x+tile*scale,y,tw*scale,16,8,sourceY,tw,8,
                MERIDIAN_TILES_W,MERIDIAN_TILES_H,MeridianColor(1,1,1));
        }
    }
    for(size_t i=0;i<room.doors.size();++i){
        const meridian::Door &d=room.doors[i];
        const float x=(d.x-cameraX)*scale,y=yOffset+(d.y-cameraY-15)*scale;
        MeridianFill(x-7,y,14,30,MeridianColor(0.17f,0.37f,0.41f));
        const char *num=va("%d",d.number);
        MeridianText((int)x-3,(int)y+3,num,MeridianColor(1,1,1));
    }
    for(size_t i=0;i<room.pickups.size();++i){
        const meridian::Pickup &p=room.pickups[i];
        if(p.taken)continue;
        const float x=(p.position.x-cameraX)*scale,y=yOffset+(p.position.y-cameraY)*scale;
        if(p.kind=="coin")
            MeridianAtlas("meridian/collectables",x-8,y-8,16,16,8,0,8,8,MERIDIAN_COLLECTABLES_W,MERIDIAN_COLLECTABLES_H,MeridianColor(1,1,1));
        else if(p.kind=="chest")
            MeridianAtlas("meridian/tiles",x-8,y-8,16,16,16,792,8,8,MERIDIAN_TILES_W,MERIDIAN_TILES_H,MeridianColor(1,1,1));
        else if(p.kind=="crate")
            MeridianAtlas("meridian/tiles",x-8,y-8,16,16,0,792,8,8,MERIDIAN_TILES_W,MERIDIAN_TILES_H,MeridianColor(1,1,1));
        else if(p.kind=="bench")
            MeridianAtlas("meridian/tiles",x-16,y-8,32,16,0,784,8,8,MERIDIAN_TILES_W,MERIDIAN_TILES_H,MeridianColor(1,1,1));
        else if(p.kind=="lever")
            MeridianAtlas("meridian/tiles",x-8,y-24,16,32,0,768,8,16,MERIDIAN_TILES_W,MERIDIAN_TILES_H,MeridianColor(1,1,1));
        else
            MeridianAtlas("meridian/player",x-8,y-8,16,16,0,64,8,8,MERIDIAN_PLAYER_W,MERIDIAN_PLAYER_H,MeridianColor(0.9f,0.75f,0.6f));
    }
    for(size_t i=0;i<room.enemies.size();++i){
        const meridian::Enemy &e=room.enemies[i];
        if(!e.alive)continue;
        const float x=(e.position.x-cameraX)*scale,y=yOffset+(e.position.y-cameraY)*scale;
        const int frame=(Sys_Milliseconds()/180)%(e.boss?3:4);
        const float side=e.boss?32.0f:16.0f;
        MeridianAtlas("meridian/enemies",x-side/2,y-side,16,side,32+frame*8,
            e.boss?120.0f:e.flyer?56.0f:40.0f,8,e.boss?16.0f:8.0f,
            MERIDIAN_ENEMIES_W,MERIDIAN_ENEMIES_H,MeridianColor(1,1,1));
    }
    for(size_t i=0;i<g_meridian.Shots().size();++i){
        const meridian::Bullet &b=g_meridian.Shots()[i];
        MeridianFill((b.position.x-cameraX)*scale,yOffset+(b.position.y-cameraY)*scale,5,3,MeridianColor(1,0.91f,0.58f));
    }
    const float px=(h.position.x-cameraX)*scale,py=yOffset+(h.position.y-cameraY)*scale;
    const int frame=(Sys_Milliseconds()/125)%8;
    const float row=!h.grounded?88.0f:std::fabs(h.velocity.x)>3.0f?16.0f:64.0f;
    const int walk=(row==16.0f)?frame:(frame/2)%4;
    const float sourceX=(float)walk*8+(h.facing<0?8.0f:0.0f);
    MeridianAtlas("meridian/player",px-8,py-8,16,16,sourceX,row,h.facing<0?-8.0f:8.0f,8,
        MERIDIAN_PLAYER_W,MERIDIAN_PLAYER_H,MeridianColor(1,1,1));
    MeridianFill(0,0,640,50,MeridianColor(0.08f,0.08f,0.11f));
    MeridianText(12,12,va("ASHEN MERIDIAN | %s",room.record->name),MeridianColor(0.87f,0.98f,0.92f));
    MeridianText(12,29,va("VIDA %d/%d  MONEDAS %d  LLAVES %d  %s",h.health,h.maxHealth,h.coins,h.keys,g_meridian.EquippedWeapon().name),MeridianColor(0.98f,0.92f,0.73f));
    MeridianText(12,434,"A/D MOVER  ESPACIO SALTAR  J TIRO  E USAR  Q ARMA  F CURAR",MeridianColor(0.75f,0.85f,0.81f));
    if(!g_meridian.Notice().empty())
        MeridianText(12,453,g_meridian.Notice().c_str(),MeridianColor(1,0.76f,0.43f));
    if(g_meridian.IsShopOpen()){
        MeridianFill(50,75,540,342,MeridianColor(0.06f,0.08f,0.13f,0.95f));
        MeridianText(78,89,"TIENDA DEL PUEBLO",MeridianColor(1,0.87f,0.50f));
        const int current=g_meridian.ShopCursor();
        const int first=std::max(0,std::min(current-3,meridian::kShopItemCount-8));
        const meridian::ShopAccess access=g_meridian.AvailableShop();
        for(int n=0;n<8;++n){
            const int i=first+n;
            const meridian::ShopItem &item=meridian::ShopCatalog::Item(i);
            const int price=meridian::ShopCatalog::Price(item,g_meridian.Purchases(),
                              g_meridian.Weapon(g_meridian.WeaponIndex()),g_meridian.WeaponIndex());
            const bool unlocked=meridian::ShopCatalog::GateOpen(item,access);
            MeridianText(72,123+n*28,va("%c %-23s %3d %s",i==current?'>':' ',item.name,price,unlocked?"":"BLOQ"),
                         i==current?MeridianColor(1,0.94f,0.45f):MeridianColor(0.71f,0.87f,0.77f));
        }
        MeridianText(72,366,"A/D ELEGIR  E/ESPACIO COMPRAR  Q SALIR",MeridianColor(1,1,1));
    }
    if(g_meridian.IsPaused())MeridianText(245,225,"EN PAUSA",MeridianColor(1,1,1));
    renderSystem->SetColor(MeridianColor(1,1,1));
}
} // namespace
