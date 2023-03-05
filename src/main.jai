#import "Basic";
#import "File";
#import "File_Utilities";
#import "Command_Line";
Sim8086 :: #import, file "sim8086.jai";

Arguments :: struct {
  show_address := false; @"?Show address in disassembly"
  #place show_address;
  a            := false; @"?Show address in disassembly"

  show_bytes   := false; @"?Show bytes in disassembly"
  #place show_bytes;
  b            := false; @"?Show bytes in disassembly"

  output_path  : string; @"?Output path for disassembly"
  #place output_path;
  o            : string; @"?Output path for disassembly"
}

main :: () {
  ok, args, is_set, free_args := parse_arguments(Arguments, Argument_Flags.FREE_ARGUMENTS_ALLOWED|.ALIGN_HELP);
  if !ok {
    return;
  }

  if free_args.count == 0 || (free_args.count > 0 && !file_exists(free_args[0])) {
    print("Target file not found.\n");
    return;
  }

  target_path := free_args[0];
  disassembly := Sim8086.disassemble(target_path, show_address=args.show_address, show_bytes=args.show_bytes);
  if args.output_path.count > 0 {
    write_entire_file(args.output_path, disassembly);
  } else {
    print(disassembly);
  }
}