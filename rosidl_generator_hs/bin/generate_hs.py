#!/usr/bin/env python3
import argparse
import pathlib

from rosidl_parser.parser import parse_idl_file, IdlFile, IdlLocator

# IDL type -> (Hs -> Haskell Type, C -> C Type)
# C versions of types are used
TYPE_MAPPING = {
    'boolean':  {'hs': 'Bool', 'c': 'bool'},
    'octet':    {'hs': 'Word8', 'c': 'uint8_t'},
    'int8':     {'hs': 'Int8', 'c': 'int8_t'},
    'uint8':    {'hs': 'Word8', 'c': 'uint8_t'},
    'int16':    {'hs': 'Int16', 'c': 'int16_t'},
    'uint16':   {'hs': 'Word16', 'c': 'uint16_t'},
    'int32':    {'hs': 'Int32', 'c': 'int32_t'},
    'uint32':   {'hs': 'Word32', 'c': 'uint32_t'},
    'int64':    {'hs': 'Int64', 'c': 'int64_t'},
    'uint64':   {'hs': 'Word64', 'c': 'uint64_t'},
    'float':    {'hs': 'CFloat', 'c': 'float'},
    'double':   {'hs': 'CDouble', 'c': 'double'},
    'char':     {'hs': 'Char', 'c': 'signed char'}
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--package-name', required=True)
    parser.add_argument('--output-dir', required=True)
    parser.add_argument('--idl-files', nargs='+', default=[])
    args = parser.parse_args()

    output_path = pathlib.Path(args.output_dir)

    for idl_file in args.idl_files:
        locator: IdlLocator = IdlLocator(
            pathlib.Path("/"), pathlib.Path(idl_file))
        ast: IdlFile = parse_idl_file(locator, None)

        print(ast)

        with open(idl_file) as f:
            print(f.read())

    cabal_content = "CABAL FILE"

    with open(output_path /
        pathlib.Path(f"{args.package_name}_hs.cabal"), 'w') as f:
        f.write(cabal_content)


if __name__ == '__main__':
    main()
