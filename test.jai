#run test(workspace, success);

#scope_file

#import "Print_Color";
#import "File";
#import "File_Utilities";
#import "String";
#import "Process";

#load "build.jai";

test :: (workspace: Workspace, success: bool) {
  if !success return;

  options := get_build_options(workspace);
  if options.output_type == .EXECUTABLE {
    command := tprint("%/%", options.output_path, options.output_executable_name);

    test_files: [..]string;
    visit_files("test", recursive=true, *test_files, visitor);

    longest_filename := 0;
    for test_files {
      if it.count > longest_filename longest_filename = it.count;
    }

    print("\nTesting all asm files in test directory:\n");
    failed_count := 0;
    for test_files {
      passed := validate_output(command, it, path_strip_extension(it));
      print("  %...", it);
      for it.count..longest_filename {
        print(".");
      }
      if passed {
        print_color("%\n", "Passed!", color=.GREEN);
      } else {
        failed_count += 1;
        print_color("%\n", "Failed!", color=.RED);
      }
    }
    print("Total: %, Passed: %, Failed: %\n", test_files.count, test_files.count-failed_count, failed_count);
  }

  visitor :: (info: *File_Visit_Info, files: *[..] string) {
    extension := path_extension(info.full_name);
    if extension == "asm" {
      array_add(files, copy_string(info.full_name));
    }
  }
}

validate_output :: (command: string, source_file: string, test_file: string) -> bool {
  result, output, error := run_command(command, test_file, capture_and_return_output=true);
  test_lines := split_clean_lines(output);

  source_content := read_entire_file(source_file);
  source_lines := split_clean_lines(source_content);

  if source_lines.count != test_lines.count return false;

  for source_lines {
    if !equal_nocase(it, test_lines[it_index]) return false;
  }

  return true;
}

split_clean_lines :: (contents: string) -> []string {
  lines := split(contents, "\n");
  cleaned_lines: [..]string;
  for lines {
    trimmed := trim(it, " \t\r\n");
    if trimmed.count == 0 continue;
    if begins_with(trimmed, ";") continue;

    array_add(*cleaned_lines, trimmed);
  }

  return cleaned_lines;
}