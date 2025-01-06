module Internal.Toolbar exposing (view)

import FontAwesome.Solid as Icon
import FontAwesome.Svg as SvgIcon
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onCheck, onClick)
import Internal.Column exposing (..)
import Internal.Config exposing (..)
import Internal.Data exposing (..)
import Internal.State exposing (..)
import Internal.Util exposing (..)
import Monocle.Lens exposing (Lens)
import Svg.Styled
import Svg.Styled.Attributes as SvgA
import UaDropdownMultiSelect as Dropdown


view : Config a b msg -> Pipe msg -> Pipe msg -> State -> List (Html msg)
view (Config cfg) pipeExt pipeInt state =
    [ case cfg.pagination of
        ByPage { capabilities } ->
            toolbarMenuPagination pipeExt pipeInt state capabilities

        _ ->
            text ""
    , toolbarMenuColumns cfg.table.columns pipeInt state
    , case cfg.subtable of
        Just (SubTable _ conf) ->
            toolbarMenuSubColumns conf.columns pipeInt state

        Nothing ->
            text ""
    ]


faBarsIcon =
    Svg.Styled.svg [ SvgA.viewBox "0 0 512 512", SvgA.style "width: 20px; height: 20px;" ]
        [ Svg.Styled.fromUnstyled <| SvgIcon.view Icon.bars ]


faTableColumnsIcon =
    Svg.Styled.svg [ SvgA.viewBox "0 0 512 512", SvgA.style "width: 20px; height: 20px;" ]
        [ Svg.Styled.fromUnstyled <| SvgIcon.view Icon.tableColumns ]


toolbarMenuPagination : Pipe msg -> Pipe msg -> State -> List Int -> Html msg
toolbarMenuPagination pipeExt pipeInt state capabilities =
    Dropdown.view
        --     "Pagination"
        { onClick = \idx -> pipeInt <| \s -> { s | ddPagination = Dropdown.clickDropdown idx s.ddPagination }
        , onToggle =
            \btnState ->
                pipeInt <|
                    \s ->
                        { s
                            | ddPagination = Dropdown.toggleDropdown btnState s.ddPagination
                            , ddColumns = Dropdown.toggleDropdown False s.ddColumns
                            , ddSubColumns = Dropdown.toggleDropdown False s.ddSubColumns
                        }
        , icon = faBarsIcon
        , align = Dropdown.Right
        }
        state.ddPagination


toolbarMenuColumns : List (Column a msg) -> Pipe msg -> State -> Html msg
toolbarMenuColumns columns pipeInt state =
    Dropdown.view
        --     "Columns"
        { onClick = \idx -> pipeInt <| \s -> { s | ddColumns = Dropdown.clickDropdown idx s.ddColumns }
        , onToggle =
            \btnState ->
                pipeInt <|
                    \s ->
                        { s
                            | ddColumns = Dropdown.toggleDropdown btnState s.ddColumns
                            , ddPagination = Dropdown.toggleDropdown False s.ddPagination
                            , ddSubColumns = Dropdown.toggleDropdown False s.ddSubColumns
                        }
        , icon = faTableColumnsIcon
        , align = Dropdown.Right
        }
        state.ddColumns


toolbarMenuSubColumns : List (Column a msg) -> Pipe msg -> State -> Html msg
toolbarMenuSubColumns columns pipeInt state =
    Dropdown.view
        -- "Columns of subtable"
        { onClick = \idx -> pipeInt <| \s -> { s | ddSubColumns = Dropdown.clickDropdown idx s.ddSubColumns }
        , onToggle =
            \btnState ->
                pipeInt <|
                    \s ->
                        { s
                            | ddSubColumns = Dropdown.toggleDropdown btnState s.ddSubColumns
                            , ddPagination = Dropdown.toggleDropdown False s.ddPagination
                            , ddColumns = Dropdown.toggleDropdown False s.ddColumns
                        }
        , icon = faTableColumnsIcon
        , align = Dropdown.Right
        }
        state.ddSubColumns


