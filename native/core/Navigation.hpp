#pragma once
// Native C++ input state machine; does not load Godot or BFG's proprietary SWF menu.
namespace meridian {
enum class Screen { Title, Game, Pause, Atlas, Journal };
enum class MenuAction { None, NewGame, LoadGame, SaveAndTitle, Quit };
struct MenuKeys {
    bool up,down,accept,back,atlas,journal;
    MenuKeys():up(false),down(false),accept(false),back(false),atlas(false),journal(false){}
};
class Navigation {
public:
    Navigation():page_(Screen::Title),selection_(0),hasSave_(false){}
    void Boot(bool hasSave){page_=Screen::Title;selection_=0;hasSave_=hasSave;previous_=MenuKeys();}
    void Playing(){page_=Screen::Game;selection_=0;previous_=MenuKeys();}
    Screen Page()const{return page_;}
    int Selection()const{return selection_;}
    bool HasSave()const{return hasSave_;}
    void SetHasSave(bool value){hasSave_=value;}
    MenuAction Step(const MenuKeys &keys){
        const bool up=keys.up&&!previous_.up;
        const bool down=keys.down&&!previous_.down;
        const bool ok=keys.accept&&!previous_.accept;
        const bool back=keys.back&&!previous_.back;
        const bool atlas=keys.atlas&&!previous_.atlas;
        const bool journal=keys.journal&&!previous_.journal;
        previous_=keys;
        if(page_==Screen::Game){
            if(back){page_=Screen::Pause;selection_=0;}
            else if(atlas)page_=Screen::Atlas;
            else if(journal)page_=Screen::Journal;
            return MenuAction::None;
        }
        if(page_==Screen::Atlas||page_==Screen::Journal){
            if(back||ok||(page_==Screen::Atlas&&atlas)||(page_==Screen::Journal&&journal))
                page_=Screen::Game;
            return MenuAction::None;
        }
        if(back&&page_==Screen::Pause){page_=Screen::Game;return MenuAction::None;}
        if(up)selection_=(selection_+2)%3;
        if(down)selection_=(selection_+1)%3;
        if(!ok)return MenuAction::None;
        if(page_==Screen::Title){
            if(selection_==0)return MenuAction::NewGame;
            if(selection_==1&&hasSave_)return MenuAction::LoadGame;
            return selection_==2?MenuAction::Quit:MenuAction::None;
        }
        if(selection_==0){page_=Screen::Game;return MenuAction::None;}
        if(selection_==1){page_=Screen::Title;selection_=0;return MenuAction::SaveAndTitle;}
        return MenuAction::Quit;
    }
private:
    Screen page_;
    int selection_;
    bool hasSave_;
    MenuKeys previous_;
};
} // namespace meridian
