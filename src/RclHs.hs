module RclHs (someFunc) where

import RclHs.Bindings (c_hello)

someFunc :: IO ()
someFunc = c_hello
