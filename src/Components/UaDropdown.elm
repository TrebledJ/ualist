module Components.UaDropdown exposing (..)

import Components.Dropdown as Dropdown exposing (dropdown)
import Css
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw
import TwUtil


init : List a -> a -> State a
init items selected =
    { items = items
    , selected = selected
    , isOpen = False
    }


type alias State a =
    { items : List a
    , selected : a
    , isOpen : Dropdown.State
    }



-- nth : Int -> List a -> Maybe a
-- nth n xs =
--     xs |> List.drop n |> List.head
-- zip : List a -> List b -> List ( a, b )
-- zip =
--     List.map2 Tuple.pair


type Msg a
    = MsgToggle Bool
    | MsgSelectItem a


-- update : Msg a -> State a -> State a
-- update msg st =
--     case msg of
--         MsgToggle on ->
--             { st | isOpen = on }

--         MsgSelectItem x ->
--             { st | selected = x }

toggle : Bool -> State a -> State a
toggle on st = { st | isOpen = on }

select : a -> State a -> State a
select x st = { st | selected = x }


type alias ViewOptions a msg =
    { render : a -> Html msg
    , onSelect : a -> msg
    , onToggle : Bool -> msg
    , icon : Html msg
    , align : TwUtil.Align
    }


view :
    ViewOptions a msg
    -> State a
    -> Html msg
view { render, onSelect, onToggle, icon, align } { items, selected, isOpen } =
    dropdown
        { identifier = ""
        , toggleEvent = Dropdown.OnClick
        , drawerVisibleAttribute = class ""
        , onToggle = onToggle
        , layout =
            \{ toDropdown, toToggle, toDrawer } ->
                toDropdown div
                    []
                    [ dropdownToggle toToggle icon
                    , dropdownMenu toDrawer align render onSelect items selected
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


dropdownMenu : (HtmlBuilder msg -> HtmlBuilder msg) -> TwUtil.Align -> (a -> Html msg) -> (a -> msg) -> List a -> a -> Html msg
dropdownMenu toDrawer align render fClick items selected =
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
        (items |> List.map (dropdownItem render fClick selected))


dropdownItem : (a -> Html msg) -> (a -> msg) -> a -> a -> Html msg
dropdownItem render clickMsg selected obj =
    div
        [ css
            [ Tw.relative
            , Tw.cursor_pointer
            , Css.hover [ Tw.bg_color Tw.gray_100 ]
            ]
        , onClick (clickMsg obj)
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
        , if obj == selected then
            span [ css [ Tw.absolute, Tw.top_1, Tw.right_2 ] ] [ text "✓" ]

          else
            text ""
        ]
