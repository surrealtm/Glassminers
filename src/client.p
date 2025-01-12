#load "basic.p";
#load "window.p";
#load "graphics_engine/graphics_engine.p";
#load "os_specific.p";

Client :: struct {
    // Engine structure
    window: Window;
    ge: Graphics_Engine;
    
    pool: Memory_Pool;
    allocator: Allocator;
}

client: Client;

client_entry_point :: () {
    os_enable_high_resolution_timer();
    set_working_directory_to_executable_path();

    create_memory_pool(*client.pool, 128 * Memory_Unit.Megabytes, 128 * Memory_Unit.Kilobytes);
    client.allocator = allocator_from_memory_pool(*client.pool);
    
    create_window(*client.window, "Glassminers", WINDOW_DONT_CARE, WINDOW_DONT_CARE, WINDOW_DONT_CARE, WINDOW_DONT_CARE, .Default);
    ge_create(*client.ge, *client.window, *client.allocator);
    
    while !client.window.should_close {
        frame_start := os_get_hardware_time();

        //
        // Simulate one frame
        //
        {     
            update_window(*client.window);
        }
        
        //
        // Draw one frame
        //
        {
            ge_clear_screen(*client.ge, .{ 100, 200, 255, 255 });
            ge_swap_buffers(*client.ge);
        }
        
        frame_end := os_get_hardware_time();
        window_ensure_frame_time(frame_start, frame_end, 144);
    }

    ge_destroy(*client.ge);    
    destroy_window(*client.window);
    return;
}