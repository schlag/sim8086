disassemble :: (filename: string, show_address := false, show_bytes := false) -> string  {
  builder: String_Builder;
  file_contents := read_entire_file(filename);
  
  print_to_builder(*builder, "; %\n\n", filename);
  if !show_address && !show_bytes print_to_builder(*builder, "bits 16\n\n");
  bytes: []u8 = xx file_contents;
  for bytes {
    decoded_instruction, decoded_bytes := decode_instruction(*bytes[it_index]);
    to_lower_in_place(decoded_instruction);
    defer free(decoded_instruction);
    if show_address print_to_builder(*builder, "0x% ", formatInt(it_index, base=16, minimum_digits=4));
    if show_bytes {
      print_to_builder(*builder, "| ");
      for decoded_byte_index: 0..MAX_INSTRUCTION_BYTES-1 {
        if decoded_byte_index < decoded_bytes.count {
          print_to_builder(*builder, "%", formatInt(decoded_bytes[decoded_byte_index], base=16));
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
#import "Reflection";

DEBUG_PRINT :: false;
MAX_INSTRUCTION_BYTES :: 6;

Register :: enum u8 {
  AL :: 0b0000;
  CL :: 0b0001;
  DL :: 0b0010;
  BL :: 0b0011;
  AH :: 0b0100;
  CH :: 0b0101;
  DH :: 0b0110;
  BH :: 0b0111;

  AX :: 0b1000;
  CX :: 0b1001;
  DX :: 0b1010;
  BX :: 0b1011;

  SP :: 0b1100;
  BP :: 0b1101;
  SI :: 0b1110;
  DI :: 0b1111;
}

decode_instruction :: (instruction: *u8) -> string, []u8 {
  builder: String_Builder;
  bytes: []u8;
  bytes.data = instruction;
  bytes.count = 1;
  operation_code:      u8;
  operation_direction: u8;
  operation_size:      u8;
  operation_mode:      u8;
  operation_register1: Register;
  operation_register2: Register;
  for bytes {
    debug_print("; -------\n");
    debug_print("; byte = %\n", formatInt(it, base=16, minimum_digits=2));
    if it_index == {
      case 0;
        operation_code      =  it >> 2;
        operation_direction = (it >> 1) & 0b000001;
        operation_size      =  it       & 0b000001;
        debug_print("; operation_code      = %\n",   formatInt(operation_code, base=16, minimum_digits=2));
        debug_print("; operation_direction = %\n",   formatInt(operation_direction, base=16));
        debug_print("; operation_size      = %\n\n", formatInt(operation_size, base=16));

        if operation_code == {
          case 0x22;
            print_to_builder(*builder, "mov");
            bytes.count += 1;
          case;
            print_to_builder(*builder, "unk");
        }
      case 1;
        operation_mode      =      it >> 6;
        operation_register1 = xx ((it >> 3) & 0b000111) | (operation_size << 3);
        operation_register2 = xx  (it       & 0b000111) | (operation_size << 3);
        if operation_direction == 0 {
          operation_register1, operation_register2 = swap(operation_register1, operation_register2);
        }
        debug_print("; operation_mode      = %\n",   formatInt(operation_mode, base=2, minimum_digits=2));
        debug_print("; operation_register1 = %\n",   formatInt(cast(u8) operation_register1, base=2, minimum_digits=4));
        debug_print("; operation_register2 = %\n", formatInt(cast(u8) operation_register2, base=2, minimum_digits=4));
        print_to_builder(*builder, " %, %", enum_value_to_name(operation_register1),  enum_value_to_name(operation_register2));
    }
  }
  debug_print("; -------\n\n");
  return builder_to_string(*builder), bytes;
}

debug_print :: (format_string: string, args: .. Any, to_standard_error := false) {
  #if DEBUG_PRINT print(format_string, ..args, to_standard_error);
}