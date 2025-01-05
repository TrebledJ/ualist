module UaDropdownMultiSelect exposing (..)

import Css
import Dropdown exposing (dropdown)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw


init : List String -> Model
init items =
    { items = items
    , selecteds = List.repeat (List.length items) False
    , myDropdownIsOpen = False
    }


type alias Model =
    { items : List String
    , selecteds : List Bool
    , myDropdownIsOpen : Dropdown.State
    }


type Msg
    = ToggleDropdown Bool
    | Clicked Int


nth : Int -> List a -> Maybe a
nth n xs =
    case n of
        0 ->
            List.head xs

        _ ->
            xs |> List.drop n |> List.head


zip : List a -> List b -> List ( a, b )
zip =
    List.map2 Tuple.pair


update : Msg -> Model -> Model
update msg model =
    case msg of
        ToggleDropdown newState ->
            { model | myDropdownIsOpen = newState }

        Clicked idx ->
            let
                isSelected =
                    model.selecteds |> nth idx

                front =
                    model.selecteds |> List.take idx

                back =
                    model.selecteds |> List.drop (idx + 1)
            in
            case isSelected of
                Nothing ->
                    model

                Just x ->
                    { model | selecteds = front ++ not x :: back }


view : Html Msg -> Model -> Html Msg
view icon { items, selecteds, myDropdownIsOpen } =
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
                        [ toToggle div [] [ dropdownToggle icon ]
                        , toDrawer div [] [ dropdownMenu items selecteds ]
                        ]
            , isToggled = myDropdownIsOpen
            }
        ]


border =
    [ Tw.border_solid, Tw.border, Tw.border_color Tw.gray_300, Tw.rounded ]


dropdownToggle : Html msg -> Html msg
dropdownToggle icon =
    a
        [ css <| [ Tw.inline_flex, Tw.w_10, Tw.h_10 ] ++ border
        ]
        [ i
            [ css [ Tw.block, Tw.relative, Tw.m_auto ] ]
            [ icon ]
        ]


dropdownMenu : List String -> List Bool -> Html Msg
dropdownMenu items selected =
    div
        [ css <|
            [ Tw.absolute
            , Tw.mt_1
            , Tw.bg_color Tw.white
            , Tw.shadow_md
            , Tw.z_10
            , Tw.w_56
            , Tw.py_2
            ]
                ++ border
        ]
        (items |> zip selected |> List.indexedMap dropdownItem)


dropdownItem : Int -> ( Bool, String ) -> Html Msg
dropdownItem idx ( selected, str ) =
    a
        [ css
            [ Tw.inline_block
            , Tw.box_border
            , Tw.w_full
            , Tw.px_3
            , Tw.py_1
            , Tw.whitespace_nowrap
            , Tw.overflow_hidden
            , Tw.text_ellipsis
            , Tw.cursor_pointer
            , Css.hover [ Tw.bg_color Tw.gray_200 ]
            ]
        , onClick (Clicked idx)
        ]
        [ text str
        , input
            [ css [ Tw.float_right, Tw.align_baseline ]
            , type_ "checkbox"
            , checked selected
            ]
            []
        ]
