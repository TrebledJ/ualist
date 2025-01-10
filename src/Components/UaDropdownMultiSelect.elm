module Components.UaDropdownMultiSelect exposing (State, select, getSelected, init, init2, toggle, view)

import Components.Dropdown as Dropdown exposing (dropdown)
import Css
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw
import TwUtil


init : List String -> State
init items =
    init2 items (List.repeat (List.length items) False)


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


nth : Int -> List a -> Maybe a
nth n xs =
    xs |> List.drop n |> List.head


zip : List a -> List b -> List ( a, b )
zip =
    List.map2 Tuple.pair


getSelected : State -> List String
getSelected st =
    zip st.items st.selecteds
        |> List.filterMap
            (\( name, sel ) ->
                if sel then
                    Just name

                else
                    Nothing
            )


toggle : Bool -> State -> State
toggle new st =
    { st | isOpen = new }


select : Int -> State -> State
select idx st =
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


type alias ViewOptions msg =
    { identifier : String -- An unique identifier to handle focusing mechanics.
    , onSelect : Int -> msg -- What message to fire when an item is selected.
    , onToggle : Bool -> msg -- What message to fire when an item is toggled.
    , icon : Html msg -- An icon to display on the button.
    , align : TwUtil.Align -- Whether the dropdown menu is aligned left or right.
    }

view :
    ViewOptions msg
    -> State
    -> Html msg
view { identifier, onSelect, onToggle, icon, align } { items, selecteds, isOpen } =
    dropdown
        { identifier = identifier
        , toggleEvent = Dropdown.OnClick
        , drawerVisibleAttribute = class ""
        , onToggle = onToggle
        , layout =
            \{ toDropdown, toToggle, toDrawer } ->
                toDropdown div
                    []
                    [ dropdownToggle toToggle icon
                    , dropdownMenu toDrawer align onSelect items selecteds
                    ]
        , isToggled = isOpen
        }


dropdownToggle : (HtmlBuilder msg -> HtmlBuilder msg) -> Html msg -> Html msg
dropdownToggle toToggle icon =
    toToggle button
        [ css <|
            [ Tw.flex
            , Tw.justify_center
            , Tw.items_center
            , Tw.w_10
            , Tw.h_10
            , Tw.cursor_pointer
            , Tw.bg_color Tw.white
            , Css.hover
                [ Tw.bg_color Tw.gray_100
                ]
            ]
                ++ TwUtil.border
        ]
        [ i
            [ css [ Tw.block, Tw.relative, Tw.m_auto ] ]
            [ icon ]
        ]


type alias HtmlBuilder msg =
    List (Attribute msg) -> List (Html msg) -> Html msg


dropdownMenu : (HtmlBuilder msg -> HtmlBuilder msg) -> TwUtil.Align -> (Int -> msg) -> List String -> List Bool -> Html msg
dropdownMenu toDrawer align fSelect items selected =
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
                ++ TwUtil.border
                ++ TwUtil.fix_left_right align
        ]
        (items |> zip selected |> List.indexedMap (dropdownItem fSelect))


dropdownItem : (Int -> msg) -> Int -> ( Bool, String ) -> Html msg
dropdownItem fSelect idx ( selected, str ) =
    div
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
            , Css.hover [ Tw.bg_color Tw.gray_100 ]
            ]
        , onClick (fSelect idx)
        ]
        [ text str
        , input
            [ css [ Tw.float_right, Tw.align_baseline ]
            , type_ "checkbox"
            , checked selected
            ]
            []
        ]
