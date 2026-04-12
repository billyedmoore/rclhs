#!/usr/bin/env python3
import argparse
import pathlib
import jinja2

from rosidl_parser.parser import parse_idl_file, IdlContent, IdlLocator
from rosidl_parser.definition import (
    Service,
    Message,
    BasicType,
    UnboundedString,
    BoundedString,
    UnboundedSequence,
    BoundedSequence,
    Array)
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
    'char':     'CChar'
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
        "messages": [],
        "services": []}

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
            gen_srv(srv, template_env,
                    output_path, args.package_name,
                    package_name_pascal)
            cabal_template_args["services"].append(
                srv.namespaced_type.name)

    cabal_content = cabal_template.render(cabal_template_args)

    with open(output_path /
              pathlib.Path(f"{package_name_haskell}-hs.cabal"), 'w') as f:
        f.write(cabal_content)


def snake_to_pascal(text):
    return "".join(word.capitalize() for word in text.split("_"))


def gen_msg(template_env: jinja2.Environment,
            output_path: pathlib.Path,
            msg: Message,
            package_name: str,
            is_service=False,
            service_name=""):

    def assert_type_is_basic_type(value_type):
        if not isinstance(value_type, BasicType):
            raise Exception(
                "Non-basic types in sequences and arrays ",
                "are not supported.")

    msg_template = template_env.get_template("msg.hsc.j2")

    msg_name = msg.structure.namespaced_type.name
    package_name_pascal = snake_to_pascal(package_name)

    fields = []

    for member in msg.structure.members:
        field_base = {
            "name": member.name,
            "is_basic_type": False,
            "is_string": False,
            "is_sequence": False,
            "is_array": False
        }
        if isinstance(member.type, BasicType):
            fields.append({
                **field_base,
                "is_basic_type": True,
                "type": TYPE_MAP[member.type.typename]
            })
        elif (isinstance(member.type, UnboundedString) or
                isinstance(member.type, BoundedString)):
            fields.append({
                **field_base,
                "is_string": True
            })
        elif (isinstance(member.type, Array)):
            print(member.type.value_type)
            assert_type_is_basic_type(member.type.value_type)
            fields.append({
                **field_base,
                "is_array": True,
                "capacity": member.type.size,
                "value_type": TYPE_MAP[member.type.value_type.typename]
            })
        elif (isinstance(member.type, UnboundedSequence) or
                isinstance(member.type, BoundedSequence)):
            assert_type_is_basic_type(member.type.value_type)
            fields.append({
                **field_base,
                "is_sequence": True,
                "value_type": TYPE_MAP[member.type.value_type.typename]
            })
        else:
            raise Exception(
                f"The type, {type(member.type)}, is not supported "
                "by `rosidl_generator_hs`.")

    if is_service:
        messages_output_path = (
            output_path /
            pathlib.Path(
                f"src/RclHs/{package_name_pascal}/Srv/{service_name}"))
    else:
        messages_output_path = (
            output_path / pathlib.Path(f"src/RclHs/{package_name_pascal}/Msg"))
    messages_output_path.mkdir(parents=True, exist_ok=True)

    msg_name_snake = convert_camel_case_to_lower_case_underscore(msg_name)
    template_args = {
        "package_name": package_name,
        "package_name_pascal": package_name_pascal,
        "msg_name": msg_name,
        "msg_name_snake": msg_name_snake,
        "fields": fields,
        "is_service": is_service,
        "service_name": service_name,
        "header_path": (package_name + "/msg/detail/" +
                        msg_name_snake + "__struct.h"),
        "c_prefix":  (package_name +
                      ("__msg__" if not is_service else "__srv__") + msg_name)
    }
    if is_service:
        service_name_snake = convert_camel_case_to_lower_case_underscore(
            service_name)
        template_args["header_path"] = (
            package_name + "/srv/detail/" + service_name_snake + "__struct.h")

    output_file_path = messages_output_path / pathlib.Path(f"{msg_name}.hsc")

    with open(output_file_path, "w") as f:
        f.write(msg_template.render(template_args))


def gen_srv(srv: Service,
            template_env: jinja2.Environment,
            output_path: pathlib.Path,
            package_name: str,
            package_name_pascal: str
            ):
    service_name = srv.namespaced_type.name

    gen_msg(template_env, output_path,
            srv.response_message,
            package_name,
            is_service=True,
            service_name=service_name)
    gen_msg(template_env, output_path,
            srv.request_message, package_name,
            is_service=True,
            service_name=service_name)

    srv_template = template_env.get_template("srv.hsc.j2")
    print("gen_srv")
    template_args = {
        "package_name": package_name,
        "service_name": service_name,
        "package_name_pascal": package_name_pascal,
        "service_name_snake":
            convert_camel_case_to_lower_case_underscore(service_name)
    }

    services_output_path = (
        output_path /
        pathlib.Path(
            f"src/RclHs/{package_name_pascal}/Srv/"))

    output_file_path = services_output_path / \
        pathlib.Path(f"{service_name}.hsc")

    with open(output_file_path, "w") as f:
        f.write(srv_template.render(template_args))


if __name__ == '__main__':
    main()
