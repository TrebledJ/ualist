module Components.UaDropdownMultiSelect exposing (Align(..), State, clickDropdown, init, init2, getSelected, toggleDropdown, view)

import Css
import Components.Dropdown as Dropdown exposing (dropdown)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw


init : List String -> State
init items = init2 items (List.repeat (List.length items) False)

init2 : List String -> List Bool -> State
init2 items selecteds =
    { items = items
    , selecteds = selecteds
    , isOpen = False
    }


type alias State =
    { items : List String
    , selecteds : List Bool
    , isOpen : Dropdown.State
    }


type Align
    = Left
    | Right



-- type Msg
--     = ToggleDropdown Bool
--     | Clicked Int


nth : Int -> List a -> Maybe a
nth n xs =
    xs |> List.drop n |> List.head


zip : List a -> List b -> List ( a, b )
zip =
    List.map2 Tuple.pair

getSelected : State -> List String
getSelected st = zip st.items st.selecteds |> List.filterMap (\(name, sel) -> if sel then Just name else Nothing)

toggleDropdown : Bool -> State -> State
toggleDropdown new st =
    { st | isOpen = new }


clickDropdown : Int -> State -> State
clickDropdown idx st =
    let
        isSelected =
            st.selecteds |> nth idx

        front =
            st.selecteds |> List.take idx

        back =
            st.selecteds |> List.drop (idx + 1)
    in
    case isSelected of
        Nothing ->
            st

        Just x ->
            { st | selecteds = front ++ not x :: back }



-- update : Msg -> State -> State
-- update msg model =
--     case msg of
--         ToggleDropdown newState ->
--             { model | myDropdownIsOpen = newState }
--         Clicked idx ->


view :
    { onClick : Int -> msg, onToggle : Bool -> msg, icon : Html msg, align : Align }
    -> State
    -> Html msg
view { onClick, onToggle, icon, align } { items, selecteds, isOpen } =
    div []
        [ dropdown
            { identifier = ""
            , toggleEvent = Dropdown.OnClick
            , drawerVisibleAttribute = class ""
            , onToggle = onToggle
            , layout =
                \{ toDropdown, toToggle, toDrawer } ->
                    toDropdown div
                        []
                        [ toToggle div [] [ dropdownToggle icon ]
                        , dropdownMenu toDrawer align onClick items selecteds
                        ]
            , isToggled = isOpen
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


type alias HtmlBuilder msg =
    List (Attribute msg) -> List (Html msg) -> Html msg

dropdownMenu : (HtmlBuilder msg -> HtmlBuilder msg) -> Align -> (Int -> msg) -> List String -> List Bool -> Html msg
dropdownMenu toDrawer align onClick items selected =
    toDrawer div
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
                ++ (if align == Left then
                        [ Tw.left_0, Tw.right_auto ]

                    else
                        [ Tw.left_auto, Tw.right_0 ]
                   )
        ]
        (items |> zip selected |> List.indexedMap (dropdownItem onClick))


dropdownItem : (Int -> msg) -> Int -> ( Bool, String ) -> Html msg
dropdownItem clickMsg idx ( selected, str ) =
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
        , onClick (clickMsg idx)
        ]
        [ text str
        , input
            [ css [ Tw.float_right, Tw.align_baseline ]
            , type_ "checkbox"
            , checked selected
            ]
            []
        ]
