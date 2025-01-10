module DropdownTest exposing (..)

import Browser
import FontAwesome.Solid as Icon
import FontAwesome.Svg as SvgIcon
import Html
import Html.Styled exposing (toUnstyled)
import Svg.Styled
import Svg.Styled.Attributes as SvgA
import Components.UaDropdownMultiSelect exposing (..)
import TwUtil


faTableColumnsIcon =
    Svg.Styled.svg [ SvgA.viewBox "0 0 512 512", SvgA.style "width: 20px; height: 20px;" ]
        [ Svg.Styled.fromUnstyled <| SvgIcon.view Icon.tableColumns ]


type Msg
    = ToggleDropdown Bool
    | Clicked Int


update : Msg -> State -> State
update msg st =
    case msg of
        ToggleDropdown new ->
            toggle new st

        Clicked idx ->
            select idx st


main =
    Browser.sandbox
        { init = init [ "A", "B", "C", "oasdlf ajd fklaj sdklfa lkdjf alkjdf klaj dfklajd lfkja dklf" ]
        , update = update
        , view =
            toUnstyled
                << view
                    { onToggle = ToggleDropdown
                    , onClick = Clicked
                    , icon = faTableColumnsIcon
                    , align = TwUtil.Left
                    }
        }
