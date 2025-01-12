CLIENT :: true;
SERVER :: true;

#if CLIENT #load "client.p";

MAX_ENTITIES :: 1024;

PID :: s64;
INVALID_ENTITY: PID : -1;

Physical_Position :: struct { x, y: s32; }

Entity_Kind :: enum {
    Inanimate :: 0;
    Player    :: 1;
}

Entity :: struct {
    id: PID;
    kind: Entity_Kind;
    physical_position: Physical_Position;
    visual_position: GE_Vector2;
    visual_size: GE_Vector2;
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
    entity.visual_position   = .{ xx entity.physical_position.x, xx entity.physical_position.y };
    entity.visual_size       = .{ 1, 1 };
    
    return id, entity;
}

get_entity :: (gm: *Glassminers, id: PID) -> *Entity {
    assert(gm.entity_indirection[id] != INVALID_ENTITY, "Entity ID is invalid.");
    return array_get_pointer(*gm.entities, gm.entity_indirection[id]);
}

create_world :: (gm: *Glassminers, allocator: *Allocator) -> PID {
    create_glassminers(gm, allocator);
    
    for x := -8; x <= 8; ++x {
        for y := -2; y <= 2; ++y {
            create_entity(gm, .Inanimate, .{ x, y });
        }
    }    

    id, ptr := create_entity(gm, .Player, .{ 0, 0 });
    return id;
}

main :: () -> s32 {
    os_enable_high_resolution_timer();
    set_working_directory_to_executable_path();

    #if CLIENT client_entry_point();

    return 0;
}



#file_scope

find_unused_entity_id :: (gm: *Glassminers) -> PID {
    for i := 0; i < gm.entity_indirection.Capacity; ++i {
        if gm.entity_indirection[i] == INVALID_ENTITY return i;
    }

    return -1;
}
