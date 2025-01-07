module Components.Internal.Toolbar exposing (view)

import Components.Internal.Column exposing (..)
import Components.Internal.Config exposing (..)
import Components.Internal.Data exposing (..)
import Components.Internal.State exposing (..)
import Components.Internal.Util exposing (..)
import Components.UaDropdownMultiSelect as UaDropdown
import FontAwesome.Solid as Icon
import FontAwesome.Svg as SvgIcon
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onCheck, onClick)
import Monocle.Lens exposing (Lens)
import Svg.Styled
import Svg.Styled.Attributes as SvgA
import TwUtil


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
    UaDropdown.view
        --     "Pagination"
        { onClick = \idx -> pipeInt <| \s -> { s | ddPagination = UaDropdown.clickDropdown idx s.ddPagination }
        , onToggle =
            \btnState ->
                pipeInt <|
                    \s ->
                        { s
                            | ddPagination = UaDropdown.toggleDropdown btnState s.ddPagination
                            , ddColumns = UaDropdown.toggleDropdown False s.ddColumns
                            , ddSubColumns = UaDropdown.toggleDropdown False s.ddSubColumns
                        }
        , icon = faBarsIcon
        , align = TwUtil.Right
        }
        state.ddPagination


toolbarMenuColumns : List (Column a msg) -> Pipe msg -> State -> Html msg
toolbarMenuColumns columns pipeInt state =
    UaDropdown.view
        --     "Columns"
        { onClick = \idx -> pipeInt <| \s -> { s | ddColumns = UaDropdown.clickDropdown idx s.ddColumns }
        , onToggle =
            \btnState ->
                pipeInt <|
                    \s ->
                        { s
                            | ddColumns = UaDropdown.toggleDropdown btnState s.ddColumns
                            , ddPagination = UaDropdown.toggleDropdown False s.ddPagination
                            , ddSubColumns = UaDropdown.toggleDropdown False s.ddSubColumns
                        }
        , icon = faTableColumnsIcon
        , align = TwUtil.Right
        }
        state.ddColumns


toolbarMenuSubColumns : List (Column a msg) -> Pipe msg -> State -> Html msg
toolbarMenuSubColumns columns pipeInt state =
    UaDropdown.view
        -- "Columns of subtable"
        { onClick = \idx -> pipeInt <| \s -> { s | ddSubColumns = UaDropdown.clickDropdown idx s.ddSubColumns }
        , onToggle =
            \btnState ->
                pipeInt <|
                    \s ->
                        { s
                            | ddSubColumns = UaDropdown.toggleDropdown btnState s.ddSubColumns
                            , ddPagination = UaDropdown.toggleDropdown False s.ddPagination
                            , ddColumns = UaDropdown.toggleDropdown False s.ddColumns
                        }
        , icon = faTableColumnsIcon
        , align = TwUtil.Right
        }
        state.ddSubColumns
