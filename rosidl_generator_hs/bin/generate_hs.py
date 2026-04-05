#!/usr/bin/env python3
import argparse
import pathlib
import jinja2

from rosidl_parser.parser import parse_idl_file, IdlContent, IdlLocator
from rosidl_parser.definition import Service, Message, BasicType
from rosidl_pycommon import convert_camel_case_to_lower_case_underscore

print("Generating Haskell Types with rosidl_generator_hs!")

# IDL type -> Haskell Type
# Types should directly be bytecompatible with their C counterparts
# Derived from the type map in the rosidl_generator_c source code
TYPE_MAP = {
    'boolean':  'CBool',
    'octet':    'Word8',
    'int8':     'Int8',
    'uint8':    'Word8',
    'int16':    'Int16',
    'uint16':   'Word16',
    'int32':    'Int32',
    'uint32':   'Word32',
    'int64':    'Int64',
    'uint64':   'Word64',
    'float':    'CFloat',
    'double':   'CDouble',
    'char':     'Char'
}


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--package-name', required=True)
    parser.add_argument('--output-dir', required=True)
    parser.add_argument('--template-dir', required=True)
    parser.add_argument('--idl-files', nargs='+', default=[])
    return parser.parse_args()


def main():
    args = parse_args()
    output_path = pathlib.Path(args.output_dir)
    template_path = pathlib.Path(args.template_dir)

    package_name_pascal = snake_to_pascal(args.package_name)
    package_name_haskell = "".join(
        [('-' if c == '_' else c) for c in args.package_name])

    template_env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(template_path))

    cabal_template = template_env.get_template("cabal.j2")
    cabal_template_args = {
        "package_name": args.package_name,
        "package_name_pascal": package_name_pascal,
        "package_name_hyphen": package_name_haskell,
        "messages": []}

    for idl_file in args.idl_files:
        locator: IdlLocator = IdlLocator(
            pathlib.Path("/"), pathlib.Path(idl_file))
        ast: IdlContent = parse_idl_file(locator, None).content

        for msg in ast.get_elements_of_type(Message):
            gen_msg(template_env, output_path,
                    msg, args.package_name)
            cabal_template_args["messages"].append(
                msg.structure.namespaced_type.name)

        for srv in ast.get_elements_of_type(Service):
            gen_srv(srv)

        with open(idl_file) as f:
            print(idl_file)
            print(f.read())

    cabal_content = cabal_template.render(cabal_template_args)

    with open(output_path /
              pathlib.Path(f"{package_name_haskell}-hs.cabal"), 'w') as f:
        f.write(cabal_content)


def snake_to_pascal(text):
    return "".join(word.capitalize() for word in text.split("_"))


def gen_msg(template_env: jinja2.Environment,
            output_path: pathlib.Path,
            msg: Message,
            package_name: str):
    msg_template = template_env.get_template("msg.hsc.j2")

    msg_name = msg.structure.namespaced_type.name
    package_name_pascal = snake_to_pascal(package_name)

    fields = []
    for member in msg.structure.members:
        if isinstance(member.type, BasicType):
            fields.append({"name": member.name,
                           "type": TYPE_MAP[member.type.typename]})

    template_args = {
        "package_name": package_name,
        "package_name_pascal": package_name_pascal,
        "msg_name": msg_name,
        "msg_name_snake":
            convert_camel_case_to_lower_case_underscore(msg_name),
        "fields": fields
    }

    messages_output_path = (
        output_path / pathlib.Path(f"src/RclHs/{package_name_pascal}/Msg"))
    messages_output_path.mkdir(parents=True, exist_ok=True)

    output_file_path = messages_output_path / pathlib.Path(f"{msg_name}.hsc")

    with open(output_file_path, "w") as f:
        f.write(msg_template.render(template_args))


def gen_srv(srv: Service):
    # TODO: Implement codegen for Services
    print("gen_srv")


if __name__ == '__main__':
    main()
