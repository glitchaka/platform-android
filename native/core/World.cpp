#include "World.hpp"
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>

namespace meridian {
#include "../generated/RoomCatalog.inc"

const RoomRecord *FindRoom(const std::string &id) {
    for (size_t i = 0; i < kRoomCount; ++i) {
        if (id == kRooms[i].id) return &kRooms[i];
    }
    return NULL;
}

size_t RoomCount() { return kRoomCount; }
size_t LinkCount() { return kLinkCount; }

int RoomRank(const std::string &id) {
    const RoomRecord *room = FindRoom(id);
    if (!room) return 0;
    const std::string zone = room->zone;
    if (zone == "aurora") return 6;
    if (id == "deep_west") return 2;
    if (id == "deep_city") return 4;
    if (zone == "cross" || zone == "town") return 1;
    if (zone == "fungus") return 2;
    if (zone == "bone") return 3;
    if (zone == "city") return 4;
    if (zone == "palace") return 5;
    return 0;
}

static int roomVariant(const std::string &id) {
    // String.hash() uses a 32-bit DJB2 hash of the ASCII room identifier.
    // Keep the source's "absi(hash) % 3" platform layout selection.
    uint32_t hash = 5381u;
    for (size_t i = 0; i < id.size(); ++i) {
        hash = hash * 33u + static_cast<unsigned char>(id[i]);
    }
    const int64_t signedHash = static_cast<int32_t>(hash);
    const uint64_t magnitude = static_cast<uint64_t>(
        signedHash < 0 ? -signedHash : signedHash);
    return static_cast<int>(magnitude % 3u);
}

static void platform(Room &room, float x, float y, float w, float h) {
    room.platforms.push_back(Rect(x, y, w, h));
}

static void enemy(Room &room, float x, float y,
                  float left, float right, bool boss, bool flyer) {
    Enemy e;
    e.position = Vec2(x, y);
    e.patrolMin = left;
    e.patrolMax = right;
    e.boss = boss;
    e.flyer = flyer;
    const int rank = RoomRank(room.record->id);
    if (rank == 6) {
        e.hp = boss ? 288 : flyer ? 64 : 48;
        e.contactDamage = 11;
    } else {
        const int expected = 1 + rank;
        e.hp = expected * (boss ? 18 : flyer ? 4 : 3);
        e.contactDamage = rank + 1;
    }
    e.maxHp = e.hp;
    e.speed = boss ? 24.0f : flyer ? 33.0f : 24.0f;
    e.baseY = y;
    e.chargeDirection = -1.0f;
    room.enemies.push_back(e);
}

static void pickup(Room &room, const char *kind, const std::string &id,
                   float x, float y, const std::set<std::string> &collected) {
    Pickup p;
    p.kind = kind;
    p.id = id;
    p.position = Vec2(x, y);
    p.taken = collected.count(id) != 0;
    room.pickups.push_back(p);
}

static float distance(const Vec2 &a, const Vec2 &b) {
    const float dx = a.x - b.x;
    const float dy = a.y - b.y;
    return std::sqrt(dx * dx + dy * dy);
}

Room CreateRoom(const std::string &id,
                const std::set<std::string> &collected,
                const std::set<std::string> &defeated) {
    Room room;
    room.record = FindRoom(id);
    if (!room.record) return room;
    const float width = static_cast<float>(room.record->width);
    const float height = static_cast<float>(room.record->height);
    const std::string zone = room.record->zone;
    const std::string reward = room.record->reward;
    const bool town = zone == "town";
    const bool tutorial = id == "tutorial";
    const bool aurora = zone == "aurora";
    const int variant = roomVariant(id);

    room.floorY = height - 40.0f;
    platform(room, 0.0f, room.floorY, width, 40.0f);

    if (town) {
        const int roofs[] = { 64, 136, 208, 352, 448, 544 };
        for (size_t i = 0; i < 6; ++i) {
            platform(room, static_cast<float>(roofs[i]), room.floorY - 32, 56, 16);
        }
        platform(room, 280, room.floorY - 64, 56, 16);
        platform(room, 360, room.floorY - 96, 64, 16);
        room.rewardPosition = Vec2(388, room.floorY - 100);
    } else if (tutorial) {
        platform(room, 80, room.floorY - 32, 64, 16);
        platform(room, 144, room.floorY - 64, 64, 16);
        platform(room, 232, room.floorY - 64, 64, 16);
        room.rewardPosition = Vec2(264, room.floorY - 68);
    } else if (aurora) {
        for (int x = 64; x < static_cast<int>(width) - 80; x += 112) {
            platform(room, static_cast<float>(x), room.floorY - 32, 80, 16);
        }
        for (int x = 120; x < static_cast<int>(width) - 120; x += 112) {
            platform(room, static_cast<float>(x), room.floorY - 64, 64, 16);
        }
        if (id == "aurora_garden") {
            platform(room, 232, room.floorY - 96, 80, 16);
            platform(room, 288, room.floorY - 128, 64, 16);
            room.rewardPosition = Vec2(320, room.floorY - 132);
        } else {
            const Rect &ledge = room.platforms.back();
            room.rewardPosition = Vec2(ledge.x + 32, ledge.y - 4);
        }
    } else {
        const int steps = static_cast<int>((room.floorY - 40) / 32);
        for (int i = 0; i < steps; ++i) {
            const float x = 64.0f + static_cast<float>((i + variant) % 3) * 48.0f;
            platform(room, x, room.floorY - 32 - static_cast<float>(i * 32), 64, 16);
        }
        if (!room.platforms.empty()) {
            const Rect &ledge = room.platforms.back();
            room.rewardPosition = Vec2(ledge.x + 32, ledge.y - 4);
        }
        for (int x = 280; x < static_cast<int>(width) - 56; x += 96) {
            platform(room, static_cast<float>(x), room.floorY - 32, 64, 16);
            if ((x / 96) % 2 == 0) {
                platform(room, static_cast<float>(x - 32), room.floorY - 64, 56, 16);
            }
        }
    }

    // Keep original link order: door indices, return spawn and displayed
    // numbering all derive from the same 65-link catalogue.
    for (size_t i = 0; i < kLinkCount; ++i) {
        const LinkRecord &link = kLinks[i];
        const char *destination = NULL;
        if (id == link.a) destination = link.b;
        else if (id == link.b) destination = link.a;
        if (!destination) continue;
        Door door;
        door.target = destination;
        door.gate = link.gate;
        if (id == "bone_return" || door.target == "bone_return") {
            door.gate = "boss:bone_lord";
        } else if (id == "city_end" || door.target == "city_end") {
            door.gate = "boss:royal_spire";
        }
        door.number = static_cast<int>(room.doors.size()) + 1;
        room.doors.push_back(door);
    }
    for (size_t i = 0; i < room.doors.size(); ++i) {
        const float frac = tutorial ? 1.0f :
            (room.doors.size() == 1 ? 0.0f :
                static_cast<float>(i) / static_cast<float>(room.doors.size() - 1));
        room.doors[i].x = 20.0f + frac * (width - 40.0f);
        room.doors[i].y = room.floorY - 4.0f;
    }

    room.restPosition = Vec2(town ? 224.0f : width * 0.5f,
                             room.floorY - 4.0f);
    if (reward == "rest") {
        const float offsets[] = { 0, -32, 32, -64, 64 };
        for (size_t i = 0; i < 5; ++i) {
            const Vec2 candidate(std::max(48.0f,
                std::min(width - 48.0f, room.restPosition.x + offsets[i])),
                room.floorY - 4.0f);
            bool clear = true;
            for (size_t j = 0; j < room.doors.size(); ++j) {
                if (distance(candidate, Vec2(room.doors[j].x,
                                             room.doors[j].y)) < 30.0f) {
                    clear = false;
                    break;
                }
            }
            if (clear) {
                room.restPosition = candidate;
                break;
            }
        }
        pickup(room, "bench", id + ":bench", room.restPosition.x,
               room.restPosition.y, collected);
        if (!town) {
            for (int x = 48; x < static_cast<int>(width) - 40; x += 24) {
                const Vec2 candidate(static_cast<float>(x), room.floorY - 4.0f);
                if (distance(candidate, room.restPosition) < 40.0f) continue;
                bool clear = true;
                for (size_t j = 0; j < room.doors.size(); ++j) {
                    if (distance(candidate, Vec2(room.doors[j].x,
                                                 room.doors[j].y)) < 30.0f) {
                        clear = false;
                        break;
                    }
                }
                if (clear) {
                    pickup(room, "shop", id + ":merchant",
                           candidate.x, candidate.y, collected);
                    break;
                }
            }
        }
    }

    if (town) {
        pickup(room, "guide", id + ":guide", 92, room.floorY - 4, collected);
        pickup(room, "shop", id + ":merchant", 164, room.floorY - 4, collected);
        pickup(room, "sign", id + ":sign", 292, room.floorY - 4, collected);
        pickup(room, "chest", id + ":chest", room.rewardPosition.x,
               room.rewardPosition.y, collected);
    } else if (tutorial) {
        pickup(room, "sign", id + ":sign", 62, room.floorY - 4, collected);
        pickup(room, "lever", id + ":lever", 112, room.floorY - 4, collected);
        pickup(room, "chest", id + ":chest", room.rewardPosition.x,
               room.rewardPosition.y, collected);
        enemy(room, 312, room.floorY - 4, 240, 340, false, false);
    } else if (reward != "rest" && reward != "boss") {
        pickup(room, "chest", id + ":chest", room.rewardPosition.x,
               room.rewardPosition.y, collected);
        if (variant == 1 && room.platforms.size() > 1) {
            const Rect &p = room.platforms[1];
            pickup(room, "lever", id + ":lever", p.x + 24, p.y - 4, collected);
        }
    }

    if (reward == "boss") {
        pickup(room, "chest", id + ":chest", width * 0.72f,
               room.floorY - 4, collected);
        if (defeated.count(id) == 0) {
            enemy(room, width * 0.62f, room.floorY - 4,
                  72, width - 32, true, false);
        }
    } else if (!town && !tutorial && reward != "rest") {
        for (int x = 152; x < static_cast<int>(width) - 32; x += 128) {
            enemy(room, static_cast<float>(x), room.floorY - 4,
                  static_cast<float>(x - 36),
                  std::min(static_cast<float>(x + 44), width - 32),
                  false, false);
        }
        for (size_t i = 2; i < room.platforms.size(); i += 3) {
            const Rect &p = room.platforms[i];
            enemy(room, p.x + 32, p.y - 16, p.x, p.x + p.w, false, true);
        }
    }

    int placed = 0;
    for (size_t i = 1; i < room.platforms.size() && placed < 3; ++i) {
        const Rect &ledge = room.platforms[i];
        const Vec2 position(ledge.x + 16, ledge.y - 10);
        if ((tutorial || town) && placed >= 2) break;
        if (distance(position, room.rewardPosition) <= 18.0f) continue;
        char identifier[32];
        std::sprintf(identifier, "coin%u_0", static_cast<unsigned>(i));
        pickup(room, "coin", id + ":" + identifier, position.x,
               position.y, collected);
        ++placed;
    }
    for (int x = 128; x < static_cast<int>(width) - 40; x += 144) {
        if (town && x < 280) continue;
        char identifier[32];
        std::sprintf(identifier, "crate%d", x);
        pickup(room, "crate", id + ":" + identifier,
               static_cast<float>(x), room.floorY - 4, collected);
    }
    return room;
}
} // namespace meridian
