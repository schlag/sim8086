workspace, success := #run build("sim8086", "src/main.jai", "run");

#scope_file

#import "Compiler";
#import "Basic";

build :: (application_name: string, source_path: string, output_path: string) -> Workspace, bool {
  workspace := compiler_create_workspace(application_name);
  options := get_build_options(workspace);
  options.output_path = output_path;
  options.output_executable_name = application_name;
  set_build_options(options, workspace);

  intercept_flags: Intercept_Flags;
  compiler_begin_intercept(workspace, intercept_flags);

  add_build_file(tprint("%/%", #filepath, source_path), workspace);

  success := message_loop(workspace);

  compiler_end_intercept(workspace);

  set_build_options_dc(.{do_output=false});

  return workspace, success;
}

message_loop :: (workspace: Workspace) -> bool {
  success := true;
  while true {
    message := compiler_wait_for_message();
    if message.kind == .COMPLETE {
      complete := cast(*Message_Complete) message;
      if complete.error_code != .NONE {
        success = false;
      };
      break;
    }
  }
  return success;
}