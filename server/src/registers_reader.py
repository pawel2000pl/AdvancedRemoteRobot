import re
from collections import defaultdict

REGISTERS_FILENAME = '../../arduino/registers.h'

REGISTERS_ADDRESSES = dict()
REGISTERS_LIST = list()
READ_REGISTERS = list()
WRITE_REGISTERS = list()

with open(REGISTERS_FILENAME) as f:

    lines = f.read().split('\n')
    get_line = lambda: lines.pop(0).strip()
    peek_line = lambda: lines[0].strip()

    def check_section(header, footer, pattern, append_to=None):
        if append_to is None:
            append_to = list()
        if peek_line() == header:
            line = get_line()
            counts = defaultdict(lambda: 0)
            new_ones = []
            while line != footer and len(lines):
                match = re.match(pattern, line)
                if match is not None:
                    value = str(match[1])
                    counts[value] += 1
                    new_ones.append(value)
                line = get_line()
            
            indexed_entries = []
            i = 0
            indexed_value = None
            for value in new_ones:                
                if counts[value] <= 1:
                    indexed_entries.append(value)
                else:
                    if value != indexed_value:
                        i = 0
                        indexed_value = value
                    indexed_entries.append('%s[%d]'%(value, i))
                    i += 1

            append_to.extend(indexed_entries)
            return append_to
            
        return append_to


    while len(lines):
        check_section('// BEGIN REGISTERS DEFINITION', '// END REGISTERS DEFINITION', '^[\s]*int16[\s]*([a-zA-Z0-9]+).*;$', REGISTERS_LIST)
        check_section('// BEGIN LIST OF READ REGISTERS', '// END LIST OF READ REGISTERS', '^[\s]*offsetOf\(\&Registers\:\:([a-zA-Z0-9]+)\)\/[^,]*,$', READ_REGISTERS)
        check_section('// BEGIN LIST OF WRITE REGISTERS', '// END LIST OF WRITE REGISTERS', '^[\s]*offsetOf\(\&Registers\:\:([a-zA-Z0-9]+)\)\/[^,]*,$', WRITE_REGISTERS)
        get_line()

    REGISTERS_ADDRESSES = {reg: i for i, reg in enumerate(REGISTERS_LIST)}


if __name__ == '__main__':
    print(REGISTERS_ADDRESSES)
    print(REGISTERS_LIST)
    print(READ_REGISTERS)
    print(WRITE_REGISTERS)
    
