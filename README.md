# RclHs

Haskell bindings for [rcl](https://github.com/ros2/rcl) (Ros2).

## Limitations

### Rosidl Generator HS

RclHs relies on code generation to generate the Haskell types
for user defined [interfaces](https://docs.ros.org/en/kilted/Concepts/Basic/About-Interfaces.html).

Unfortunately to keep their implementation relatively simple
types cannot be generated for all valid interfaces.

Specifically only sequences and arrays of basic types are supported.

```python
# The basic types supported in sequences and arrays.
['boolean', 'octet',
 'int8', 'uint8',
 'int16', 'uint16',
 'int32', 'uint32',
 'int64','uint64',
 'float', 'double',
 'char']
```

The length of bounded strings and sequences are
not enforced.

Finally nesting custom types is not supported.
