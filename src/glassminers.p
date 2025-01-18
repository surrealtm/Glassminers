CLIENT :: true;
SERVER :: false;

SERVER_PORT :: 9876;

#load "basic.p";
#load "threads.p";
#load "virtual_connection.p";

#if CLIENT #load "client.p";
#if SERVER #load "server.p";

WORLD_HEIGHT :: 5;
WORLD_WIDTH  :: 64;

MAX_ENTITIES :: 1024;

PID :: s64;
INVALID_ENTITY: PID : -1;

Physical_Position :: struct { x, y: s32; }

Entity_Kind :: enum {
    Inanimate :: 0;
    Player    :: 1;
    Crystal   :: 2;
    Bedrock   :: 3;
}

Entity :: struct {
    id: PID;
    kind: Entity_Kind;
    physical_position: Physical_Position;
    
#if CLIENT {
    visual_position: GE_Vector2;
    visual_size: GE_Vector2;
}
}

Glassminers :: struct {
    entities: [..]Entity;
    entity_indirection: [MAX_ENTITIES]PID;
}

create_glassminers :: (gm: *Glassminers, allocator: *Allocator) {
    ~gm = .{};
    gm.entities.allocator = allocator;
    gm.entity_indirection = .[ INVALID_ENTITY ];
}

create_entity :: (gm: *Glassminers, kind: Entity_Kind, physical_position: Physical_Position) -> PID, *Entity {
    id := find_unused_entity_id(gm);
    assert(id != -1, "Game ran out of available entities.");
    
    gm.entity_indirection[id] = gm.entities.count;
    
    entity := array_push(*gm.entities);
    entity.id   = id;
    entity.kind = kind;
    entity.physical_position = physical_position;
    
#if CLIENT {
    entity.visual_position   = .{ xx entity.physical_position.x, xx entity.physical_position.y };
    entity.visual_size       = .{ 1, 1 };
}
    
    return id, entity;
}

get_entity :: (gm: *Glassminers, id: PID) -> *Entity {
    assert(gm.entity_indirection[id] != INVALID_ENTITY, "Entity ID is invalid.");
    return array_get_pointer(*gm.entities, gm.entity_indirection[id]);
}

get_entity_at_position :: (gm: *Glassminers, physical_position: Physical_Position, filter: Entity_Kind) -> *Entity {
    for i := 0; i < gm.entities.count; ++i {
        entity := array_get_pointer(*gm.entities, i);
        if entity.physical_position.x == physical_position.x && entity.physical_position.y == physical_position.y && entity.kind == filter {
            return entity;
        }
    }
    
    return null;
}

create_random_entities :: (gm: *Glassminers, kind: Entity_Kind, count: s64) {
    // @Cleanup: Don't generate an entity if there already exists one at that position
    for i := 0; i < count; ++i {
        x := rand() % WORLD_WIDTH;
        y := rand() % WORLD_HEIGHT;
        create_entity(gm, kind, .{ x, y });
    }
}

create_world :: (gm: *Glassminers, allocator: *Allocator) -> PID {
    create_glassminers(gm, allocator);

    create_random_entities(gm, .Crystal, 4);
    create_random_entities(gm, .Bedrock, 64);

    id, ptr := create_entity(gm, .Player, .{ 4, 2 });
    return id;
}

can_move_to_tile :: (gm: *Glassminers, physical_position: Physical_Position) -> bool {
    if physical_position.x < 0 || physical_position.x >= WORLD_WIDTH || physical_position.y < 0 || physical_position.y >= WORLD_HEIGHT return false;
    
    if get_entity_at_position(gm, physical_position, .Bedrock) return false;
    
    return true;
}

main :: () -> s32 {
    os_enable_high_resolution_timer();
    set_working_directory_to_executable_path();

    #if CLIENT && SERVER {
        server_thread: Thread = create_thread(server_entry_point, null, false);
        client_entry_point(null);
        join_thread(*server_thread);
    } #else #if CLIENT {
        client_entry_point(null);
    } #else #if SERVER {
        server_entry_point(null);
    }

    return 0;
}



#file_scope

find_unused_entity_id :: (gm: *Glassminers) -> PID {
    for i := 0; i < gm.entity_indirection.Capacity; ++i {
        if gm.entity_indirection[i] == INVALID_ENTITY return i;
    }

    return -1;
}
