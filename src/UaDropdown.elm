module UaDropdown exposing (..)

import Css
import Dropdown exposing (dropdown)
import FontAwesome as Icon exposing (Icon)
import FontAwesome.Solid as Icon
import FontAwesome.Svg as SvgIcon
import Html as Html1
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Svg.Styled
import Svg.Styled.Attributes as SvgA
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw


init : List String -> Model
init items =
    { items = items
    , myDropdownIsOpen = False
    }


type alias Model =
    { items : List String
    , myDropdownIsOpen : Dropdown.State
    }


type Msg
    = ToggleDropdown Bool
    | Clicked String


update : Msg -> Model -> Model
update msg model =
    case msg of
        ToggleDropdown newState ->
            { model | myDropdownIsOpen = newState }

        Clicked str ->
            let
                _ =
                    Debug.log "clicked" str
            in
            model


view : Model -> Html1.Html Msg
view { items, myDropdownIsOpen } =
    toUnstyled <|
        div []
            [ dropdown
                { identifier = "my-dropdown"
                , toggleEvent = Dropdown.OnClick
                , drawerVisibleAttribute = class "visible"
                , onToggle = ToggleDropdown
                , layout =
                    \{ toDropdown, toToggle, toDrawer } ->
                        toDropdown div
                            []
                            [ toToggle div [] [ dropdownToggle ]
                            , toDrawer div [] [ dropdownMenu items ]
                            ]
                , isToggled = myDropdownIsOpen
                }
            ]


border = [Tw.border_solid, Tw.border, Tw.border_color Tw.gray_300, Tw.rounded]


dropdownToggle : Html msg
dropdownToggle =
    a
        [ css <| [ Tw.inline_flex, Tw.w_10, Tw.h_10 ] ++ border
        ]
        [ i
            [ css [ Tw.block, Tw.relative, Tw.m_auto ]
            ]
            [ Svg.Styled.svg [ SvgA.viewBox "0 0 512 512", SvgA.style "width: 20px; height: 20px;" ]
                [ Svg.Styled.fromUnstyled <| SvgIcon.view Icon.tableColumns ]
            ]
        ]


dropdownMenu : List String -> Html Msg
dropdownMenu items =
    div
        [ css <|
            [ Tw.absolute
            , Tw.mt_1
            , Tw.bg_color Tw.white
            , Tw.shadow_lg
            , Tw.z_10
            , Tw.w_48
            , Tw.py_2
            ] ++ border
        ]
            -- (items |> List.indexedMap (dropdownItem m.selected))
            (items |> List.indexedMap (dropdownItem 0))

        -- [ text "10", span
        --     [ class "check"
        --     ]
        --     [ text "✓" ]
        -- ]


dropdownItem : Int -> Int -> String -> Html Msg
dropdownItem selectedIdx idx str =
    a
        [ css
            [ Tw.inline_block
            , Tw.box_border
            -- , Tw.bg_color
            --     (if selectedIdx == idx then
            --         Tw.blue_600

            --      else
            --         Tw.white
            --     )
            , Tw.w_full
            , Tw.px_3
            , Tw.py_1
            , Tw.whitespace_nowrap
            , Tw.overflow_hidden
            , Tw.text_ellipsis
            , Tw.cursor_pointer
            , Css.hover [ Tw.bg_color Tw.gray_200 ]
            ]
        , onClick (Clicked str)
        ]
        [ text str
        , input
            [ css [ Tw.float_right, Tw.align_baseline ]
            , type_ "checkbox"
            ]
            []
        ]
