module Components.Internal.Toolbar exposing (view)

import Components.Internal.Column exposing (..)
import Components.Internal.Config exposing (..)
import Components.Internal.Data exposing (..)
import Components.Internal.State exposing (..)
import Components.Internal.Util exposing (..)
import Components.UaDropdown as UaDropdown
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
        ByPage _ ->
            toolbarMenuPagination pipeExt pipeInt state

        Limit _ ->
            toolbarMenuPagination pipeExt pipeInt state

        _ ->
            text ""
    , toolbarMenuColumns cfg.table.columns pipeInt state
    , case cfg.subtable of
        Just (SubTable _ conf) ->
            toolbarMenuSubColumns conf.columns pipeInt state

        Nothing ->
            text ""
    ]


toolbarMenuPagination : Pipe msg -> Pipe msg -> State -> Html msg
toolbarMenuPagination pipeExt pipeInt state =
    UaDropdown.view
        { identifier = "dd-limit-rows"
        , render = text
        , onSelect = \item -> pipeInt <| \s -> { s | ddPagination = s.ddPagination |> UaDropdown.select item }
        , onToggle = \on -> pipeInt <| \s -> { s | ddPagination = s.ddPagination |> UaDropdown.toggle on }
        , icon = TwUtil.icon Icon.hashtag
        , align = TwUtil.Right
        }
        state.ddPagination


toolbarMenuColumns : List (Column a msg) -> Pipe msg -> State -> Html msg
toolbarMenuColumns columns pipeInt state =
    UaDropdownMS.view
        { identifier = "dd-column"
        , onClick = \idx -> pipeInt <| \s -> { s | ddColumns = UaDropdownMS.clickDropdown idx s.ddColumns }
        , onToggle = \on -> pipeInt <| \s -> { s | ddColumns = UaDropdownMS.toggleDropdown on s.ddColumns }
        , icon = TwUtil.icon Icon.tableColumns
        , align = TwUtil.Right
        }
        state.ddColumns


toolbarMenuSubColumns : List (Column a msg) -> Pipe msg -> State -> Html msg
toolbarMenuSubColumns columns pipeInt state =
    -- TODO
    UaDropdownMS.view
        -- "Columns of subtable"
        { identifier = "dd-subcolumn"
        , onClick = \idx -> pipeInt <| \s -> { s | ddSubColumns = UaDropdownMS.clickDropdown idx s.ddSubColumns }
        , onToggle = \on -> pipeInt <| \s -> { s | ddSubColumns = UaDropdownMS.toggleDropdown on s.ddSubColumns }
        , icon = TwUtil.icon Icon.tableColumns
        , align = TwUtil.Right
        }
        state.ddSubColumns
