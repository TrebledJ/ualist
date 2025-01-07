module TwUtil exposing (..)

import Css
import FontAwesome as Icon
import FontAwesome.Solid as Icon
import Svg.Attributes as SvgA
import Svg.Styled
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw


border : List Css.Style
border =
    [ Tw.border_solid, Tw.border, Tw.border_color Tw.gray_300, Tw.rounded ]


type Align
    = Left
    | Right


fix_left_right : Align -> List Css.Style
fix_left_right align =
    if align == Left then
        [ Tw.left_0, Tw.right_auto ]

    else
        [ Tw.left_auto, Tw.right_0 ]


icon : Icon.Icon Icon.WithoutId -> Svg.Styled.Svg msg
icon =
    iconWithSize 20 20


iconWithSize : Int -> Int -> Icon.Icon Icon.WithoutId -> Svg.Styled.Svg msg
iconWithSize width height base =
    base
        |> Icon.styled [ SvgA.width <| String.fromInt width, SvgA.height <| String.fromInt height ]
        |> Icon.view
        |> Svg.Styled.fromUnstyled
