# RclHs

Haskell bindings for [rcl](https://github.com/ros2/rcl) (Ros2).

## Limitations

### Rosidl Generator HS

RclHs relies on code generation to generate the Haskell types
for user defined [interfaces](https://docs.ros.org/en/kilted/Concepts/Basic/About-Interfaces.html).
This is not fully featured.

Only basic types, strings, arrays and sequences are supported as field values.

For arrays and sequences the value type must be a basic type.

Bounded strings and sequences are allowed but their length will 
not enforced by rclhs (this should be considered undefined behaviour).

```python
# For reference, the basic types:
['boolean', 'octet',
 'int8', 'uint8',
 'int16', 'uint16',
 'int32', 'uint32',
 'int64','uint64',
 'float', 'double',
 'char']
```

### Action Server

There is no support for action servers or action server clients.
