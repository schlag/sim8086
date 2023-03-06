disassemble :: (filename: string, show_address := false, show_bytes := false) -> string  {
  builder: String_Builder;
  file_contents := read_entire_file(filename);
  
  print_to_builder(*builder, "; %\n\n", filename);
  if !show_address && !show_bytes print_to_builder(*builder, "bits 16\n\n");
  bytes: []u8 = xx file_contents;
  for bytes {
    decoded_instruction, decoded_bytes := decode_instruction(*bytes[it_index]);
    if show_address print_to_builder(*builder, "0x% ", formatInt(it_index, base=16, minimum_digits=4));
    if show_bytes {
      print_to_builder(*builder, "| ");
      for decoded_byte_index: 0..MAX_INSTRUCTION_BYTES-1 {
        if decoded_byte_index < decoded_bytes.count {
          print_to_builder(*builder, "%", formatInt(decoded_bytes[decoded_byte_index], base=16, minimum_digits=2));
        } else {
          print_to_builder(*builder, "--");
        }
        print_to_builder(*builder, " ");
      }
      print_to_builder(*builder, "| ");
    }
    print_to_builder(*builder, "%\n", decoded_instruction);
    it_index += decoded_bytes.count - 1;
  }

  return builder_to_string(*builder);
}

#scope_module

#import "Basic";
#import "String";
#import "File";
#import "Math";
#import "Reflection";

MAX_INSTRUCTION_BYTES :: 6;

Register_Table :: string.[
  "al",
  "cl",
  "dl",
  "bl",
  "ah",
  "ch",
  "dh",
  "bh",

  "ax",
  "cx",
  "dx",
  "bx",
  "sp",
  "bp",
  "si",
  "di"
];

Memory_Table :: string.[
  "[bx + si%]",
  "[bx + di%]",
  "[bp + si%]",
  "[bp + di%]",
  "[si%]",
  "[di%]",
  "[bp%]",
  "[bx%]",
];

decode_instruction :: (instruction: *u8) -> string, []u8 {
  builder: String_Builder;
  byte:  u8;
  bytes: []u8;
  bytes.data = instruction;

  operation_code:              u8;
  operation_direction:         u8;
  operation_size:              u8;
  operation_mode:              u8;
  operation_register_one:      u8;
  operation_register_one_code: string;
  operation_register_two:      u8;
  operation_register_two_code: string;
  operation_displacement:      s16;

  chomp_byte();

  operation_code      =  byte >> 2;
  operation_direction = (byte >> 1) & 0b000001;
  operation_size      =  byte       & 0b000001;

  if operation_code == {
    case 0x22; #through;
    case 0x31;
      chomp_byte();
      operation_mode = byte >> 6;
      operation_register_one = ((byte >> 3) & 0b000111) | (operation_size << 3);
      operation_register_one_code = Register_Table[operation_register_one];
      operation_register_two = byte & 0b000111;
      operation_register_two_code = Memory_Table[operation_register_two];

      direct := false;
      offset := "";

      if operation_mode == {
        case 0;
          if operation_register_two == 6 {
            direct = true;
            operation_register_two_code = "[%]";
            operation_displacement = chomp_s16();
          }
        case 1;
          operation_displacement = chomp_s8();
        case 2;
          operation_displacement = chomp_s16();
        case 3;
          operation_register_two =  (byte & 0b000111) | (operation_size << 3);
          operation_register_two_code = Register_Table[operation_register_two];
      }

      if direct {
        offset = tprint("%", cast(u16) operation_displacement);
      } else {
        if operation_displacement < 0 {
          offset = tprint(" - %", abs(operation_displacement));
        } else if operation_displacement > 0 {
          offset = tprint(" + %", operation_displacement);
        }
      }
      operation_register_two_code = tprint(operation_register_two_code, offset);

      if operation_code == 0x31 {
        operation_direction = 0;
        if operation_size {
          operation_register_one_code = tprint("word %", cast,no_check(u16) chomp_s16());
        } else {
          operation_register_one_code = tprint("byte %", cast,no_check(u8) chomp_s8());
        }
      }

      if operation_direction {
        print_to_builder(*builder, "mov %, %", operation_register_one_code,  operation_register_two_code);
      } else {
        print_to_builder(*builder, "mov %, %", operation_register_two_code,  operation_register_one_code);
      }
    case 0x2c; #through;
    case 0x2e; #through;
    case 0x2d; #through;
    case 0x2f;
      operation_size = (byte >> 3) & 0b000001;
      operation_register_one = xx (byte & 0b000111) | (operation_size << 3);
      print_to_builder(*builder, "mov %, %", Register_Table[operation_register_one],  ifx operation_size then chomp_s16() else chomp_s8());
    case 0x28;
      operation_register_one_code = "ax";
      if operation_size {
        operation_register_two_code = tprint("[%]", cast,no_check(u16) chomp_s16());
      } else {
        operation_register_two_code = tprint("[%]", cast,no_check(u8) chomp_s8());
      }
      if operation_direction {
        print_to_builder(*builder, "mov %, %", operation_register_two_code,  operation_register_one_code);
      } else {
        print_to_builder(*builder, "mov %, %", operation_register_one_code,  operation_register_two_code);
      }
    case;
      print_to_builder(*builder, "unk");
  }


  chomp_byte :: () #expand {
    `bytes.count += 1;
    `byte = bytes[bytes.count-1];
  }

  chomp_s8 :: () -> s8 #expand {
    chomp_byte();
    return cast,no_check(s8) `byte;
  }

  chomp_s16 :: () -> s16 #expand {
    chomp_byte();
    low := `byte;
    chomp_byte();
    high := `byte;
    return ((cast,no_check(s16)(high)) << 8) | low;
  }

  return builder_to_string(*builder), bytes;
}