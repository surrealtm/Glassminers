Remote_Client :: struct {
    connection: Virtual_Connection;    
}

Server :: struct {
    // Engine structure
    perm_pool: Memory_Pool;
    temp_arena: Memory_Arena;
    perm, temp: Allocator;
    
    // Connections
    connection: Virtual_Connection;
    clients: Linked_List(Remote_Client);
    
    // Game
    #using gm: Glassminers;
}

server_entry_point :: (shared_data: *Shared_Server_Data) -> u32 {
    shared_data.state = .Starting;

    //
    // Start up the engine
    //
    server: Server;
    print("Creating the server...\n");
    
    create_memory_pool(*server.perm_pool, 128 * Memory_Unit.Megabytes, 128 * Memory_Unit.Kilobytes);
    create_memory_arena(*server.temp_arena, 2 * Memory_Unit.Megabytes, 128 * Memory_Unit.Kilobytes, false);
    server.perm = allocator_from_memory_pool(*server.perm_pool);
    server.temp = allocator_from_memory_arena(*server.temp_arena);
    
    //
    // Start up the connection
    //
    success := create_server_connection(*server.connection, .UDP, SERVER_PORT);

    if success {
        print("Successfully started the server.\n");
        shared_data.state = .Closing;
    } else {
        print("Failed to start the server!\n");
        shared_data.state = .Running;
    }
        
    while shared_data.state == .Running {
        tick_start := os_get_hardware_time();

        //
        // Accept incoming clients
        //
    
        //
        // Read all incoming messages
        //
        
        //
        // Update the game state
        //
        
        //
        // Send out all messages
        //
        
        //
        // Sync to tick rate
        //

        tick_end := os_get_hardware_time();
        os_sleep_to_tick_rate(tick_start, tick_end, 20);
    }

    print("Stopping the server...\n");

    for it := server.clients.head; it != null; it = it.next destroy_connection(*it.data.connection);
    destroy_connection(*server.connection);
    destroy_memory_pool(*server.perm_pool);
    destroy_memory_arena(*server.temp_arena);
 
    print("Stopped the server.\n");

    shared_data.state = .Closed;
           
    return 0;
}