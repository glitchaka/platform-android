// Embedded into idTech 4's Game_local.cpp by native/tools/prepare_desktop.py.
// Runs in the engine's rendering context; not a separate graphics framework.
#include "core/World.cpp"
#include "core/Combat.cpp"
#include "core/Game.cpp"
#include "generated/AtlasDimensions.hpp"

namespace {
meridian::Game g_meridian;
bool g_meridianVisible=false;
int g_meridianLastMs=0;

bool MeridianKey(int key){return idKeyInput::IsDown(key);}
idVec4 MeridianColor(float r,float g,float b,float a=1.0f){return idVec4(r,g,b,a);}
void MeridianFill(float x,float y,float w,float h,const idVec4 &color){
    renderSystem->DrawFilled(color,x,y,w,h);
}
void MeridianText(int x,int y,const char *text,const idVec4 &color){
    renderSystem->DrawSmallStringExt(x,y,text,color,true);
}
const idMaterial *MeridianMaterial(const char *name){return declManager->FindMaterial(name);}
void MeridianAtlas(const char *material,float px,float py,float w,float h,float sx,float sy,float sw,float sh,float texW,float texH,const idVec4 &tint){
    renderSystem->SetColor(tint);
    renderSystem->DrawStretchPic(px,py,w,h,sx/texW,sy/texH,(sx+sw)/texW,(sy+sh)/texH,MeridianMaterial(material));
    renderSystem->SetColor(MeridianColor(1,1,1));
}
void MeridianStart_f(const idCmdArgs &args){
    g_meridianVisible=true;
    g_meridian.NewGame();
    g_meridianLastMs=Sys_Milliseconds();
    common->Printf("Ashen Meridian: new native session started.\\n");
}
void MeridianLoad_f(const idCmdArgs &args){
    g_meridianVisible=true;
    if(!g_meridian.Load("meridian-native.save"))g_meridian.NewGame();
    g_meridianLastMs=Sys_Milliseconds();
}
void MeridianStop_f(const idCmdArgs &args){g_meridianVisible=false;}
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
    in.dash=MeridianKey(K_SHIFT)||MeridianKey('k');
    in.pause=MeridianKey(K_ESCAPE);
    in.save=MeridianKey('p');
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
        MeridianFill(x,y,r.w*scale,3,MeridianColor(0.48f,0.58f,0.48f));
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
        if(p.kind=="coin")MeridianFill(x-3,y-3,6,6,MeridianColor(1,0.78f,0.22f));
        else if(p.kind=="chest")MeridianFill(x-7,y-8,15,11,MeridianColor(0.65f,0.39f,0.16f));
        else if(p.kind=="bench")MeridianFill(x-10,y,20,6,MeridianColor(0.45f,0.32f,0.28f));
        else MeridianFill(x-5,y-10,10,12,MeridianColor(0.66f,0.55f,0.34f));
    }
    for(size_t i=0;i<room.enemies.size();++i){
        const meridian::Enemy &e=room.enemies[i];
        if(!e.alive)continue;
        const float x=(e.position.x-cameraX)*scale,y=yOffset+(e.position.y-cameraY)*scale;
        const float side=e.boss?32.0f:16.0f;
        MeridianFill(x-side/2,y-side,side,side,e.boss?MeridianColor(0.77f,0.24f,0.23f):MeridianColor(0.64f,0.37f,0.60f));
    }
    for(size_t i=0;i<g_meridian.Shots().size();++i){
        const meridian::Bullet &b=g_meridian.Shots()[i];
        MeridianFill((b.position.x-cameraX)*scale,yOffset+(b.position.y-cameraY)*scale,5,3,MeridianColor(1,0.91f,0.58f));
    }
    const float px=(h.position.x-cameraX)*scale,py=yOffset+(h.position.y-cameraY)*scale;
    MeridianAtlas("meridian/player",px-8,py-8,16,16,0,64,8,8,MERIDIAN_PLAYER_W,MERIDIAN_PLAYER_H,MeridianColor(1,1,1));
    MeridianFill(0,0,640,50,MeridianColor(0.08f,0.08f,0.11f));
    MeridianText(12,12,va("ASHEN MERIDIAN | %s",room.record->name),MeridianColor(0.87f,0.98f,0.92f));
    MeridianText(12,29,va("VIDA %d/%d  MONEDAS %d  LLAVES %d",h.health,h.maxHealth,h.coins,h.keys),MeridianColor(0.98f,0.92f,0.73f));
    MeridianText(12,434,"A/D MOVER  ESPACIO SALTAR  J DISPARAR  E USAR  SHIFT IMPULSO  P GUARDAR",MeridianColor(0.75f,0.85f,0.81f));
    if(!g_meridian.Notice().empty())
        MeridianText(12,453,g_meridian.Notice().c_str(),MeridianColor(1,0.76f,0.43f));
    if(g_meridian.IsPaused())MeridianText(245,225,"EN PAUSA",MeridianColor(1,1,1));
    renderSystem->SetColor(MeridianColor(1,1,1));
}
} // namespace
