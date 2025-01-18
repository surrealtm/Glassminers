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
    
    move_delta: Physical_Position = .{ 0, 0 };
    
    if client.window.keys[.W] & .Repeated move_delta.y -= 1;
    if client.window.keys[.S] & .Repeated move_delta.y += 1;
    if client.window.keys[.A] & .Repeated && move_delta.y == 0 move_delta.x -= 1;
    if client.window.keys[.D] & .Repeated && move_delta.y == 0 move_delta.x += 1;

    if can_move_to_tile(*client.gm, .{ player.physical_position.x + move_delta.x, player.physical_position.y + move_delta.y }) {
        player.physical_position.x += move_delta.x;
        player.physical_position.y += move_delta.y;
    }

    player.visual_position = .{ xx player.physical_position.x, xx player.physical_position.y };    

    client.camera.world_position.x = clamp(player.visual_position.x, floor(client.camera.world_space_width / 2), floor(xx WORLD_WIDTH - client.camera.world_space_width / 2));
    client.camera.world_position.y = floor(client.camera.world_space_height / 2);
}

client_entry_point :: (shared_data: *void) -> u32 {
    //
    // Start up the engine
    //
    client: Client;
    print("Starting the client...\n");
    
    create_memory_pool(*client.pool, 128 * Memory_Unit.Megabytes, 128 * Memory_Unit.Kilobytes);
    client.allocator = allocator_from_memory_pool(*client.pool);
    
    create_window(*client.window, "Glassminers", WINDOW_DONT_CARE, WINDOW_DONT_CARE, WINDOW_DONT_CARE, WINDOW_DONT_CARE, .Default);
    ge_create(*client.ge, *client.window, *client.allocator);
    client.sprite_atlas = ge_create_texture_from_file(*client.ge, "data/sprite_atlas.png");

    //
    // Create the world
    //    
    client.player_id = create_world(*client.gm, *client.allocator);

    print("Successfully started the client.\n");
    
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
        os_sleep_to_tick_rate(frame_start, frame_end, 144);
    }

    print("Stopping the client...\n");
    
    ge_destroy_texture(*client.ge, client.sprite_atlas);
    ge_destroy(*client.ge);    
    destroy_window(*client.window);
    destroy_memory_pool(*client.pool);

    print("Stopped the client.\n");
    
    return 0;
}