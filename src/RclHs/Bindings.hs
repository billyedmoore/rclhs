{-# LANGUAGE ForeignFunctionInterface #-}

module RclHs.Bindings (hello) where


foreign import ccall unsafe "hello_world"
    hello :: IO ()
