SPRITE_ATLAS_COLUMNS :: 8; // How many sprites are in the atlas
SPRITE_ATLAS_ROWS    :: 8; // How many sprites are in the atlas

draw_world_space_rect :: (ge: *Graphics_Engine, camera: *Camera, texture: *GE_Texture, atlas_index: s64, visual_position: GE_Vector2, visual_size: GE_Vector2) {
    screen_space := screen_space_from_world_position(camera, visual_position);
    screen_size  := screen_space_from_world_size(camera, visual_size);

    vertices: [12]f32 = .[ screen_space.x - screen_size.x / 2, screen_space.y - screen_size.y / 2,
                           screen_space.x + screen_size.x / 2, screen_space.y - screen_size.y / 2,
                           screen_space.x - screen_size.x / 2, screen_space.y + screen_size.y / 2,
                           screen_space.x - screen_size.x / 2, screen_space.y + screen_size.y / 2,
                           screen_space.x + screen_size.x / 2, screen_space.y - screen_size.y / 2,
                           screen_space.x + screen_size.x / 2, screen_space.y + screen_size.y / 2 ];

    uv_coordinates := uv_coordinates_from_sprite_index(atlas_index);

    uvs: [12]f32 = .[ uv_coordinates[0], uv_coordinates[1],
                      uv_coordinates[2], uv_coordinates[1],
                      uv_coordinates[0], uv_coordinates[3],
                      uv_coordinates[0], uv_coordinates[3],
                      uv_coordinates[2], uv_coordinates[1],
                      uv_coordinates[2], uv_coordinates[3] ];

    for i := 0; i < 6; ++i {
        ge_imm2d_textured_vertex(ge, vertices[i * 2 + 0], vertices[i * 2 + 1], uvs[i * 2 + 0], uvs[i * 2 + 1], texture, .{ 255, 255, 255, 255 });
    }
}

draw_entity :: (ge: *Graphics_Engine, camera: *Camera, texture: *GE_Texture, entity: *Entity) {
    draw_world_space_rect(ge, camera, texture, entity.kind, entity.visual_position, entity.visual_size);
}

draw_one_frame :: (client: *Client) {
    ge_clear_screen(*client.ge, .{ 100, 100, 100, 255 });
    
    // Draw the background
    {
        for x := 0; x < WORLD_WIDTH; ++x {
            for y := 0; y < WORLD_HEIGHT; ++y {
                draw_world_space_rect(*client.ge, *client.camera, client.sprite_atlas, Entity_Kind.Inanimate, .{ xx x, xx y }, .{ 1, 1 });
            }
        }
    }

    // Draw all entities
    {    
        ge_imm2d_blend_mode(*client.ge, .Default);
        
        for i := 0; i < client.entities.count; ++i {
            draw_entity(*client.ge, *client.camera, client.sprite_atlas, array_get_pointer(*client.entities, i));
        }
    }
    
    ge_imm2d_flush(*client.ge);
    ge_swap_buffers(*client.ge);
}



#file_scope

screen_space_from_world_position :: (camera: *Camera, world_space: GE_Vector2) -> GE_Vector2 {
    return .{ (world_space.x - camera.world_position.x + camera.world_space_width / 2) * camera.world_space_to_pixels,
              (world_space.y - camera.world_position.y + camera.world_space_height / 2) * camera.world_space_to_pixels };
}

screen_space_from_world_size :: (camera: *Camera, world_space: GE_Vector2) -> GE_Vector2 {
    return .{ world_space.x * camera.world_space_to_pixels, world_space.y * camera.world_space_to_pixels };
}

uv_coordinates_from_sprite_index :: (index: s64) -> [4]f32 {
    row    := index / SPRITE_ATLAS_COLUMNS;
    column := index % SPRITE_ATLAS_COLUMNS;

    COLUMN_WIDTH: f32 : 1 / cast(f32) SPRITE_ATLAS_COLUMNS;
    ROW_HEIGHT:   f32 : 1 / cast(f32) SPRITE_ATLAS_ROWS;

    x0 := cast(f32) column * COLUMN_WIDTH;
    y0 := cast(f32) row    * ROW_HEIGHT;
    x1 := cast(f32) (column + 1) * COLUMN_WIDTH;
    y1 := cast(f32) (row    + 1) * ROW_HEIGHT;
    
    return .[ x0, y0, x1, y1 ];
}