#pragma once
#include "Types.hpp"
#include <set>
namespace meridian {
const RoomRecord *FindRoom(const std::string &id);
size_t RoomCount();
size_t LinkCount();
int RoomRank(const std::string &id);
Room CreateRoom(const std::string &id,const std::set<std::string> &collected,const std::set<std::string> &defeated);
}
