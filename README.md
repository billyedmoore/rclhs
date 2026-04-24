# RclHs

Haskell bindings for [rcl](https://github.com/ros2/rcl) (Ros2).

## A Very Quick Primer

This is a prototype developed for a dissertation as such 
documentation is limited, but here is the basic ideas.

The ROS2 session is managed by the `withContext` function,
when this `Context` object exists the ROS2 session is
active. This is equivalent to the `init` to `shutdown`
cycle used in typical `rcl` libraries.

In order to create a node you can call `withNode`, the same
goes for other entities for example `withPublisher`.

The component `rosidl_generator_hs` generates Haskell types
for message, these are native records that instantiate
the type class `RosMessage`. The type for services is 
similarly `RosService` which is made up of two messages.

In order for the `cabal` build to run a `cabal.project.local`
file is generated pulling in generated Haskell code, the 
`rclhs` library itself and the required C libraries.

To build the examples place this repo as the `src`
directory of a workspace (i.e. this file should be
`your_ws/src/README.md`) then run `colcon build`.

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
