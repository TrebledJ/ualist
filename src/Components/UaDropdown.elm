module Components.UaDropdown exposing (State, ViewOptions, init, withDefault, withHint, toggle, select, view)

import Components.Dropdown as Dropdown exposing (dropdown)
import Css
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw
import TwUtil
import Util exposing (..)


init : List a -> State a
init items =
    { items = items
    , selected = Nothing
    , hint = ""
    , isOpen = False
    }


withDefault : a -> State a -> State a
withDefault item ({ items } as s) =
    if List.member item items then
        { s | selected = Just item }

    else
        s


withHint : String -> State a -> State a
withHint hint s =
    { s | hint = hint }


type alias State a =
    { items : List a
    , selected : Maybe a
    , hint : String
    , isOpen : Dropdown.State
    }


toggle : Bool -> State a -> State a
toggle on st =
    { st | isOpen = on }



select : a -> State a -> State a
select = withDefault


type alias ViewOptions a msg =
    { identifier : String -- An unique identifier to handle focusing mechanics.
    , render :
        a
        -> Html msg -- How each item should be rendered to Html.
    , onSelect :
        a
        -> msg -- What message to fire when an item is selected.
    , onToggle :
        Bool
        -> msg -- What message to fire when an item is toggled.
    , showSelectedInTopLevel : Bool -- Display the currently selected item in toggle button.
    , icon : Html msg -- An icon to display on the button.
    , align : TwUtil.Align -- Whether the dropdown menu is aligned left or right.
    }


view :
    ViewOptions a msg
    -> State a
    -> Html msg
view { identifier, render, onSelect, onToggle, showSelectedInTopLevel, icon, align } { items, selected, hint, isOpen } =
    dropdown
        { identifier = identifier
        , toggleEvent = Dropdown.OnClick
        , drawerVisibleAttribute = class ""
        , onToggle = onToggle
        , layout =
            \{ toDropdown, toToggle, toDrawer } ->
                toDropdown div
                    []
                    [ dropdownToggle toToggle <|
                        ([ i
                            [ css [ Tw.block, Tw.relative, Tw.m_auto ] ]
                            [ icon ]
                         ]
                            |> appendIfT showSelectedInTopLevel
                                [ span [ css [ Tw.ml_2, Tw.text_lg ] ]
                                    [ case selected of
                                        Just item ->
                                            render item

                                        Nothing ->
                                            text hint
                                    ]
                                ]
                        )
                    , dropdownMenu toDrawer align render onSelect items selected
                    ]
        , isToggled = isOpen
        }


dropdownToggle : (HtmlBuilder msg -> HtmlBuilder msg) -> List (Html msg) -> Html msg
dropdownToggle toToggle children =
    toToggle button
        [ css <|
            [ Tw.flex
            , Tw.justify_center
            , Tw.items_center
            , Css.property "width" "max-content"
            , Css.property "min-width" "2.5rem"
            , Tw.h_10
            , Tw.p_2
            , Tw.cursor_pointer
            , Tw.bg_color Tw.white
            , Css.hover
                [ Tw.bg_color Tw.gray_100
                ]
            ]
                ++ TwUtil.border
        ]
        children


type alias HtmlBuilder msg =
    List (Attribute msg) -> List (Html msg) -> Html msg


dropdownMenu : (HtmlBuilder msg -> HtmlBuilder msg) -> TwUtil.Align -> (a -> Html msg) -> (a -> msg) -> List a -> Maybe a -> Html msg
dropdownMenu toDrawer align render fSelect items selected =
    toDrawer div
        [ css <|
            [ Tw.absolute
            , Tw.mt_1
            , Tw.bg_color Tw.white
            , Tw.shadow_md
            , Tw.z_10

            -- , Tw.w_24
            , Tw.py_2
            ]
                ++ TwUtil.border
                ++ TwUtil.fix_left_right align
        ]
        (items |> List.map (dropdownItem render fSelect selected))


dropdownItem : (a -> Html msg) -> (a -> msg) -> Maybe a -> a -> Html msg
dropdownItem render fSelect selected obj =
    div
        [ css
            [ Tw.relative
            , Tw.cursor_pointer
            , Css.hover [ Tw.bg_color Tw.gray_100 ]
            ]
        , onClick (fSelect obj)
        ]
        [ div
            [ css
                [ Tw.inline_block
                , Tw.box_border

                -- , Tw.w_full
                , Css.property "width" "max-content"
                , Tw.pl_3
                , Tw.pr_7
                , Tw.py_1
                , Tw.whitespace_nowrap
                , Tw.overflow_hidden
                , Tw.text_ellipsis
                ]
            ]
            [ render obj
            ]
        , if Just obj == selected then
            span [ css [ Tw.absolute, Tw.top_1, Tw.right_2 ] ] [ text "✓" ]

          else
            text ""
        ]
