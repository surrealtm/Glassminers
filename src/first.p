#load "compiler.p";

build_debug :: () {
    options := compiler_default_workspace_options();
    options.workspace_name        = "Glassminers";
    options.output_folder_path    = "run_tree";
    options.executable_file_path  = "run_tree/glassminers.exe";
    options.object_file_path      = "run_tree/glassminers.obj";
    options.c_file_path           = "run_tree/glassminers.c";
    options.source_files          = .[ "src/glassminers.p" ];
    options.debug_information     = true;
    options.target_backend        = .X64;
    options.run_after_compilation = true;
    compiler_create_and_compile_workspace(*options);
}

#run build_debug();