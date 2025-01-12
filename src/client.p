#load "basic.p";
#load "window.p";
#load "graphics_engine/graphics_engine.p";
#load "os_specific.p";

#load "draw.p";

TILES_IN_CAMERA :: 5;

Camera :: struct {
    world_position: GE_Vector2;
    world_space_width: f32;
    world_space_height: f32;
    world_space_to_pixels: f32;
}

Client :: struct {
    // Engine structure
    window: Window;
    ge: Graphics_Engine;
    
    pool: Memory_Pool;
    allocator: Allocator;

    sprite_atlas: *GE_Texture;
    
    // Game
    #using gm: Glassminers;
    camera: Camera;
    player_id: PID;
}

update_camera :: (client: *Client) {
    if client.window.w > client.window.h {
        client.camera.world_space_to_pixels = cast(f32) client.window.h / cast(f32) TILES_IN_CAMERA;
    } else {
        client.camera.world_space_to_pixels = cast(f32) client.window.w / cast(f32) TILES_IN_CAMERA;    
    }
    
    client.camera.world_space_width  = cast(f32) client.window.w / client.camera.world_space_to_pixels;
    client.camera.world_space_height = cast(f32) client.window.h / client.camera.world_space_to_pixels;
    client.camera.world_position     = .{ 0, 0 };
}

simulate_one_frame :: (client: *Client) {
    //
    // Player movement
    //
    player := get_entity(*client.gm, client.player_id);
    
    if client.window.keys[.W] & .Repeated player.physical_position.y -= 1;
    if client.window.keys[.S] & .Repeated player.physical_position.y += 1;
    if client.window.keys[.A] & .Repeated player.physical_position.x -= 1;
    if client.window.keys[.D] & .Repeated player.physical_position.x += 1;

    player.visual_position = .{ xx player.physical_position.x, xx player.physical_position.y };    
}

client_entry_point :: () {
    //
    // Start up the engine
    //
    client: Client;
    
    create_memory_pool(*client.pool, 128 * Memory_Unit.Megabytes, 128 * Memory_Unit.Kilobytes);
    client.allocator = allocator_from_memory_pool(*client.pool);
    
    create_window(*client.window, "Glassminers", WINDOW_DONT_CARE, WINDOW_DONT_CARE, WINDOW_DONT_CARE, WINDOW_DONT_CARE, .Default);
    ge_create(*client.ge, *client.window, *client.allocator);
    client.sprite_atlas = ge_create_texture_from_file(*client.ge, "data/sprite_atlas.png");

    //
    // Create the world
    //    
    client.player_id = create_world(*client.gm, *client.allocator);
    
    while !client.window.should_close {
        frame_start := os_get_hardware_time();

        //
        // Simulate one frame
        //
        {     
            update_window(*client.window);
            update_camera(*client);
            simulate_one_frame(*client);
        }
        
        //
        // Draw one frame
        //
        draw_one_frame(*client);
                
        frame_end := os_get_hardware_time();
        window_ensure_frame_time(frame_start, frame_end, 144);
    }
    
    ge_destroy_texture(*client.ge, client.sprite_atlas);
    ge_destroy(*client.ge);    
    destroy_window(*client.window);
    return;
}