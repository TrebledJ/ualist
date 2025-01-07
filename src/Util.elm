module Util exposing (..)

iff : Bool -> a -> a -> a
iff cond a b =
    if cond then
        a

    else
        b
        