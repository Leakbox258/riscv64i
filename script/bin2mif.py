import sys
import os

def bin_to_mif(bin_file, mif_file, width, depth):
    try:
        with open(bin_file, 'rb') as f:
            bin_data = f.read()
    except FileNotFoundError:
        print(f"Error: 找不到文件 {bin_file}")
        return

    bytes_per_word = width // 8
    
    with open(mif_file, 'w') as f:
        f.write(f"DEPTH = {depth};\n")
        f.write(f"WIDTH = {width};\n")
        f.write("ADDRESS_RADIX = HEX;\n")
        f.write("DATA_RADIX = HEX;\n\n")
        f.write("CONTENT\n")
        f.write("BEGIN\n")

        data_len = len(bin_data)
        word_count = 0

        for i in range(0, data_len, bytes_per_word):
            if word_count >= depth:
                print("Warning: sizeof bin large than DEPTH, will be abandoned")
                break
            
            chunk = bin_data[i:i+bytes_per_word]
            
            if len(chunk) < bytes_per_word:
                chunk = chunk.ljust(bytes_per_word, b'\x00')
            
            val = int.from_bytes(chunk, byteorder='little')
            hex_val = format(val, f'0{width//4}X')
            
            f.write(f"    {format(word_count, '04X')} : {hex_val};\n")
            word_count += 1

        if word_count < depth:
            f.write(f"    [{format(word_count, '04X')}..{format(depth-1, '04X')}] : 0;\n")

        f.write("END;\n")
    
    print(f"Success: generate {mif_file}")
    print(f"Counter: write in {word_count} word, depth {depth}。")

if __name__ == "__main__":
    BIN_NAME = "app.bin"
    MIF_NAME = "app.mif"
    WIDTH = 64                 
    DEPTH = 8192               

    bin_to_mif(BIN_NAME, MIF_NAME, WIDTH, DEPTH)