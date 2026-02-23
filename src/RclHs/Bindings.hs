module RclHs.Bindings (c_hello) where

foreign import capi "wrap.h hello_world" c_hello :: IO ()
