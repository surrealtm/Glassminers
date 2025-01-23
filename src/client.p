#load "window.p";
#load "graphics_engine/graphics_engine.p";
#load "ui.p";
#load "os_specific.p";

#load "draw.p";

TILES_IN_CAMERA :: 5;

Camera :: struct {
    world_position: GE_Vector2;
    world_space_width: f32;
    world_space_height: f32;
    world_space_to_pixels: f32;
}

Client_State :: enum {
    Main_Menu;
    Lobby;
    Ingame;
}

Client :: struct {
    // Engine structure
    window: Window;
    ge: Graphics_Engine;
    ui: UI;
    
    pool: Memory_Pool;
    allocator: Allocator;

    title_font: Font;
    ui_font: Font;
    sprite_atlas: *GE_Texture;

    state: Client_State;

    // Client
    connection: Virtual_Connection;

    // Server
    server_thread: Thread;
    shared_server_data: Shared_Server_Data;
    
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
    update_camera(client);

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

host_server :: (client: *Client, name: string) {
    client.server_thread = create_thread(server_entry_point, *client.shared_server_data, false);
    while client.shared_server_data.state == .Starting {}
}

join_server :: (client: *Client, address: string, name: string) {
    success := create_client_connection(*client.connection, .UDP, address, SERVER_PORT);
    
    if success {
        client.state = .Lobby;
    }
}

do_main_menu :: (client: *Client) {
    //
    // Do the host window
    //
    {
        ui_push_width(*client.ui, .Pixels, 256, 1);
        state, position := ui_push_window(*client.ui, "Host", .Default, .{ 0.33, 0.33 });
        
        ui_label(*client.ui, false, "Name");
        name := ui_text_input(*client.ui, "Enter your name", .Everything);
        ui_divider(*client.ui, true);
        
        if ui_button(*client.ui, "Host!") && name._string {
            host_server(client, name._string);
            join_server(client, "localhost", name._string);
        }
        
        ui_pop_window(*client.ui);
        ui_pop_width(*client.ui);
    }
    
    //
    // Do the join window
    //
    {
        ui_push_width(*client.ui, .Pixels, 256, 1);
        state, position := ui_push_window(*client.ui, "Join", .Default, .{ 0.66, 0.33 });
        
        ui_label(*client.ui, false, "Name");
        name := ui_text_input(*client.ui, "Enter your name", .Everything);
        ui_divider(*client.ui, true);
        
        ui_label(*client.ui, false, "Host");
        address := ui_text_input(*client.ui, "Enter an address", .Everything);
        ui_divider(*client.ui, true);
        
        if ui_button(*client.ui, "Join!") && address._string && name._string {
            join_server(client, address._string, name._string);
        }
        
        ui_pop_window(*client.ui);
        ui_pop_width(*client.ui);
    }
}

do_lobby_menu :: (client: *Client) {
    ui_push_width(*client.ui, .Pixels, 256, 1);
    state, position := ui_push_window(*client.ui, "Lobby...", .Default, .{ .5, .5 });
    
    ui_label(*client.ui, false, "Waiting for start...");
    ui_divider(*client.ui, true);
    
    if ui_button(*client.ui, "Start!") {
        print("Starting game!\n");
    }
    
    if ui_button(*client.ui, "Disconnect") {
        print("Disconnecting from lobby.\n");
    }
    
    ui_pop_window(*client.ui);
    ui_pop_width(*client.ui);
}

client_entry_point :: () -> u32 {
    //
    // Start up the engine
    //
    client: Client;
    print("Starting the client...\n");
    
    create_memory_pool(*client.pool, 128 * Memory_Unit.Megabytes, 128 * Memory_Unit.Kilobytes);
    client.allocator = allocator_from_memory_pool(*client.pool);
    
    create_window(*client.window, "Glassminers", WINDOW_DONT_CARE, WINDOW_DONT_CARE, WINDOW_DONT_CARE, WINDOW_DONT_CARE, .Default);
    ge_create(*client.ge, *client.window, *client.allocator);
    ge_create_font_from_file(*client.ge, *client.title_font, "data/font.ttf", 35, .Extended_Ascii);
    ge_create_font_from_file(*client.ge, *client.ui_font, "data/font.ttf", 13, .Extended_Ascii);
    client.sprite_atlas = ge_create_texture_from_file(*client.ge, "data/sprite_atlas.png");

    create_ui(*client.ui, .{ *client, draw_ui_text, draw_ui_rect, set_ui_scissors, clear_ui_scissors }, UI_Dark_Theme, *client.window, *client.ui_font);

    print("Successfully started the client.\n");
    
    while !client.window.should_close {
        frame_start := os_get_hardware_time();

        //
        // Simulate one frame
        //
        {     
            update_window(*client.window);
            begin_ui_frame(*client.ui, .{ 128, 26 });
            
            if #complete client.state == {
            case .Main_Menu; do_main_menu(*client);
            case .Lobby;     do_lobby_menu(*client);
            case .Ingame;    simulate_one_frame(*client);
            }
        }
        
        //
        // Draw one frame
        //
        draw_one_frame(*client);
                
        frame_end := os_get_hardware_time();
        os_sleep_to_tick_rate(frame_start, frame_end, 144);
    }

    print("Stopping the client...\n");
    
    destroy_ui(*client.ui);
    ge_destroy_texture(*client.ge, client.sprite_atlas);
    ge_destroy_font(*client.ge, *client.title_font);
    ge_destroy_font(*client.ge, *client.ui_font);
    ge_destroy(*client.ge);    
    destroy_window(*client.window);
    destroy_memory_pool(*client.pool);

    print("Stopped the client.\n");
    
    return 0;
}