module DropdownTest exposing (..)

import Browser
import FontAwesome.Solid as Icon
import FontAwesome.Svg as SvgIcon
import Svg.Styled
import Svg.Styled.Attributes as SvgA
import UaDropdownMultiSelect exposing (..)
import Html
import Html.Styled exposing (toUnstyled)

faTableColumnsIcon =
    Svg.Styled.svg [ SvgA.viewBox "0 0 512 512", SvgA.style "width: 20px; height: 20px;" ]
        [ Svg.Styled.fromUnstyled <| SvgIcon.view Icon.tableColumns ]


main =
    Browser.sandbox
        { init = init [ "A", "B", "C", "oasdlf ajd fklaj sdklfa lkdjf alkjdf klaj dfklajd lfkja dklf" ]
        , update = update
        , view = toUnstyled << view faTableColumnsIcon
        }
