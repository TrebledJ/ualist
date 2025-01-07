module TwUtil exposing (..)

import Css
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw

border =
    [ Tw.border_solid, Tw.border, Tw.border_color Tw.gray_300, Tw.rounded ]


type Align
    = Left
    | Right

fix_left_right : Align -> List (Css.Style)
fix_left_right align =
    if align == Left then
        [ Tw.left_0, Tw.right_auto ]

    else
        [ Tw.left_auto, Tw.right_0 ]

