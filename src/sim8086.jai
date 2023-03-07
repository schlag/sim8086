Operation :: struct {
  code             : Operation_Code;
  direction        : bool;
  size             : u8;
  mode             : u8;
  displacement     : u8;
  operand_one      : u8;
  operand_one_code : string;
  operand_two      : u8;
  operand_two_code : string;
  data             : s16;
  byte             : u8;
  bytes            : []u8;
}

disassemble :: (filename: string, show_address := false, show_bytes := false) -> string  {
  builder: String_Builder;
  file_contents := read_entire_file(filename);
  
  print_to_builder(*builder, "; %\n\n", filename);
  if !show_address && !show_bytes print_to_builder(*builder, "bits 16\n\n");
  bytes: []u8 = xx file_contents;
  for bytes {
    operation, operation_disassembly := decode_operation(*bytes[it_index]);
    defer free(operation_disassembly);
    if show_address print_to_builder(*builder, "0x% ", formatInt(it_index, base=16, minimum_digits=4));
    if show_bytes {
      print_to_builder(*builder, "| ");
      for decoded_byte_index: 0..MAX_INSTRUCTION_BYTES-1 {
        if decoded_byte_index < operation.bytes.count {
          print_to_builder(*builder, "%", formatInt(operation.bytes[decoded_byte_index], base=16, minimum_digits=2));
        } else {
          print_to_builder(*builder, "--");
        }
        print_to_builder(*builder, " ");
      }
      print_to_builder(*builder, "| ");
    }
    print_to_builder(*builder, "%\n", operation_disassembly);
    it_index += operation.bytes.count - 1;
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

OPERATION_CODE_MASK        :: 0b11111100;
OPERATION_DIRECTION_MASK   :: 0b00000010;
OPERATION_SIZE_MASK        :: 0b00000001;
OPERATION_OPERAND_ONE_MASK :: 0b00111000;

Operation_Code :: enum u8 {
  MOV_REG_MEM_TO_REG_MEM   :: 0b10001000;
  MOV_IMM_TO_REG_MEM       :: 0b11000100;
  MOV_IMM_TO_REG_LOW_LOW   :: 0b10110000;
  MOV_IMM_TO_REG_LOW_HIGH  :: 0b10110100;
  MOV_IMM_TO_REG_HIGH_LOW  :: 0b10111000;
  MOV_IMM_TO_REG_HIGH_HIGH :: 0b10111100;
  MOV_MEM_TO_ACC           :: 0b10100000;
  MOV_REG_MEM_TO_SEG       :: 0b10001100;
}

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

decode_operation :: (first_byte: *u8) -> Operation, string {
  builder: String_Builder;
  using operation: Operation;

  next_byte();
  decode_operation_code();
  decode_direction();
  decode_size();

  if #complete code == {
    case .MOV_REG_MEM_TO_REG_MEM; #through;
    case .MOV_IMM_TO_REG_MEM;
      next_byte();
      decode_mode();
      operand_one = decode_operand_one();
      operand_one_code = Register_Table[operand_one];
      operand_two = byte & 0b000111;
      operand_two_code = Memory_Table[operand_two];

      direct := false;

      if mode == {
        case 0b00;
          if operand_two == 0b110 {
            direct = true;
            operand_two_code = "[%]";
            displacement = 1;
            decode_data();
          }
        case 0b01;
          decode_data();
        case 0b10;
          displacement = 1;
          decode_data();
        case 0b11;
          operand_two = decode_operand_two();
          operand_two_code = Register_Table[operand_two];
      }

      offset := "";
      if direct {
        offset = tprint("%", cast,no_check(u16) data);
      } else {
        if data < 0 {
          offset = tprint(" - %", abs(data));
        } else if data > 0 {
          offset = tprint(" + %", data);
        }
      }
      operand_two_code = tprint(operand_two_code, offset);

      if code == .MOV_IMM_TO_REG_MEM {
        direction = false;
        decode_data();
        operand_one_code = tprint("% %", ifx size then "word" else "byte", cast,no_check(u16) data);
      }

      print_to_builder(*builder, ifx direction then "mov %2, %1" else "mov %1, %2", operand_two_code,  operand_one_code);
    case .MOV_IMM_TO_REG_LOW_LOW; #through;
    case .MOV_IMM_TO_REG_LOW_HIGH; #through;
    case .MOV_IMM_TO_REG_HIGH_LOW; #through;
    case .MOV_IMM_TO_REG_HIGH_HIGH;
      displacement = (byte >> 3) & 0b000001;
      size = displacement;
      operand_one = decode_operand_two();
      decode_data();
      print_to_builder(*builder, "mov %, %", Register_Table[operand_one], data);
    case .MOV_MEM_TO_ACC;
      displacement = size;
      operand_one_code = "ax";
      decode_data();
      operand_two_code = tprint("[%]", cast,no_check(u16) data);
      print_to_builder(*builder, ifx direction then "mov %1, %2" else "mov %2, %1", operand_two_code,  operand_one_code);
    case .MOV_REG_MEM_TO_SEG;
      print_to_builder(*builder, "nyi");
    case;
      print_to_builder(*builder, "unk");
  }

  next_byte :: () #expand {
    if `bytes.count == 0 `bytes.data = first_byte;
    `bytes.count += 1;
    `byte = bytes[bytes.count-1];
  }

  decode_operation_code :: () #expand {
    `code = xx `byte & 0b11111100;
  }

  decode_direction :: () #expand {
    `direction = (`byte & 0b00000010) != 0;
  }

  decode_size :: () #expand {
    `size = `byte & 0b00000001;
  }

  decode_mode :: () #expand {
    `mode = `byte >> 6;
  }

  decode_operand_one :: () -> u8 #expand {
    return ((`byte >> 3) & 0b000111) | (`size << 3);
  }

  decode_operand_two :: () -> u8 #expand {
    return (`byte & 0b000111) | (`size << 3);
  }

  decode_data :: () #expand {
    next_byte();
    low := `byte;
    if `displacement {
      next_byte();
      high := cast,no_check(s16) `byte;
      `data = (high << 8) | low;
    } else {
      `data = cast,no_check(s8) low;
    }
  }

  return operation, builder_to_string(*builder);
}