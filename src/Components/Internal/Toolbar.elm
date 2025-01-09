module Components.Internal.Toolbar exposing (view)

import Components.Internal.Column exposing (..)
import Components.Internal.Config exposing (..)
import Components.Internal.Data exposing (..)
import Components.Internal.State exposing (..)
import Components.Internal.Util exposing (..)
import Components.UaDropdownMultiSelect as UaDropdownMS
import FontAwesome.Solid as Icon
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onCheck, onClick)
import Monocle.Lens exposing (Lens)
import TwUtil


view : Config a b tbstate msg -> Pipe msg -> Pipe msg -> State -> List (Html msg)
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


toolbarMenuPagination : Pipe msg -> Pipe msg -> State -> List Int -> Html msg
toolbarMenuPagination pipeExt pipeInt state capabilities =
    UaDropdownMS.view
        --     "Pagination"
        { onClick = \idx -> pipeInt <| \s -> { s | ddPagination = UaDropdownMS.clickDropdown idx s.ddPagination }
        , onToggle =
            \btnState ->
                pipeInt <|
                    \s ->
                        { s
                            | ddPagination = UaDropdownMS.toggleDropdown btnState s.ddPagination
                            , ddColumns = UaDropdownMS.toggleDropdown False s.ddColumns
                            , ddSubColumns = UaDropdownMS.toggleDropdown False s.ddSubColumns
                        }
        , icon = TwUtil.icon Icon.bars
        , align = TwUtil.Right
        }
        state.ddPagination


toolbarMenuColumns : List (Column a msg) -> Pipe msg -> State -> Html msg
toolbarMenuColumns columns pipeInt state =
    UaDropdownMS.view
        --     "Columns"
        { onClick = \idx -> pipeInt <| \s -> { s | ddColumns = UaDropdownMS.clickDropdown idx s.ddColumns }
        , onToggle =
            \btnState ->
                pipeInt <|
                    \s ->
                        { s
                            | ddColumns = UaDropdownMS.toggleDropdown btnState s.ddColumns
                            , ddPagination = UaDropdownMS.toggleDropdown False s.ddPagination
                            , ddSubColumns = UaDropdownMS.toggleDropdown False s.ddSubColumns
                        }
        , icon = TwUtil.icon Icon.tableColumns
        , align = TwUtil.Right
        }
        state.ddColumns


toolbarMenuSubColumns : List (Column a msg) -> Pipe msg -> State -> Html msg
toolbarMenuSubColumns columns pipeInt state =
    UaDropdownMS.view
        -- "Columns of subtable"
        { onClick = \idx -> pipeInt <| \s -> { s | ddSubColumns = UaDropdownMS.clickDropdown idx s.ddSubColumns }
        , onToggle =
            \btnState ->
                pipeInt <|
                    \s ->
                        { s
                            | ddSubColumns = UaDropdownMS.toggleDropdown btnState s.ddSubColumns
                            , ddPagination = UaDropdownMS.toggleDropdown False s.ddPagination
                            , ddColumns = UaDropdownMS.toggleDropdown False s.ddColumns
                        }
        , icon = TwUtil.icon Icon.tableColumns
        , align = TwUtil.Right
        }
        state.ddSubColumns
