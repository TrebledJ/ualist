module Components.Internal.Table exposing (..)

-- import Html exposing (..)
-- import Attributes exposing (..)
-- import Events exposing (onInput)
-- import FontAwesome.Attributes as Icon
-- import FontAwesome.Brands as Icon
-- import FontAwesome.Layering as Icon
-- import FontAwesome.Styles as Icon
-- import FontAwesome.Transforms as IconT
--

import Array
import Components.Internal.Column exposing (..)
import Components.Internal.Config exposing (..)
import Components.Internal.Data exposing (..)
import Components.Internal.Pagination exposing (..)
import Components.Internal.Selection exposing (..)
import Components.Internal.State exposing (..)
import Components.Internal.Toolbar
import Components.Internal.Util exposing (..)
import Components.Table.Types exposing (..)
import Components.UaDropdown as UaDropdown
import Components.UaDropdownMultiSelect as UaDropdownMS
import Css
import FontAwesome as Icon
import FontAwesome.Solid as Icon
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (on, onClick, onInput)
import Json.Decode as Decode exposing (Decoder)
import Svg.Attributes as SvgA
import Svg.Styled
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw
import TwUtil



--
-- Initialize
--


init : Config a b tbstate msg -> Model a
init (Config cfg) =
    let
        fnVisible =
            \(Column { name, default }) -> iff default (Just name) Nothing

        visibleColumns =
            List.filterMap fnVisible cfg.table.columns

        visibleSubColumns =
            Maybe.map
                (\(SubTable _ c) -> List.filterMap fnVisible c.columns)
                cfg.subtable
                |> Maybe.withDefault []

        fnNameSelected =
            \(Column { name, default }) -> ( name, default )

        ( colNames, colSelecteds ) =
            cfg.table.columns |> List.map fnNameSelected |> List.unzip

        ( ddPaginationOptions, ddPaginationInitial ) =
            case cfg.pagination of
                ByPage { capabilities, initial } ->
                    ( capabilities |> List.map String.fromInt, String.fromInt initial )

                Limit { capabilities, initial } ->
                    ( capabilities, initial )

                _ ->
                    ( [], "" )
    in
    Model
        { state =
            { orderBy = Nothing
            , order = Ascending
            , page = 0
            , search = ""
            , ddPagination =
                UaDropdown.init ddPaginationOptions
                    |> UaDropdown.withDefault ddPaginationInitial
            , ddColumns = UaDropdownMS.init2 colNames colSelecteds
            , ddSubColumns = UaDropdownMS.init visibleSubColumns -- TODO: list all columns, and mark visible columns as selected
            , table = StateTable {- visibleColumns -} [] [] []
            , subtable = StateTable {- visibleSubColumns -} [] [] []
            }
        , rows = Rows (Status "")
        }


getFiltered : Config a b tbstate msg -> Model a -> List a
getFiltered config (Model { state, rows }) =
    case rows of
        Rows (Loaded lrows) ->
            filterRows config state lrows.rows |> List.map (\(Row x) -> x)

        _ ->
            []



-- View


view : Config a b tbstate msg -> tbstate -> Model a -> Html msg
view config toolbarState ((Model m) as model) =
    let
        pipeInt =
            pipeInternal config model

        pipeExt =
            pipeExternal config model

        bigText str =
            div [ css [ Tw.flex, Tw.justify_center, Tw.items_center, Tw.h_32 ] ]
                [ span [ css [ Tw.text_2xl ] ] [ text str ] ]
    in
    div [ css [] ] <|
        case m.rows of
            Rows (Status msg) ->
                [ tableHeader config toolbarState pipeExt pipeInt m.state
                , bigText msg
                ]

            Rows (Loaded { total, rows }) ->
                [ tableHeader config toolbarState pipeExt pipeInt m.state
                , tableContent config toolbarState pipeExt pipeInt m.state rows
                , tableFooter config pipeExt pipeInt m.state total
                ]

            Rows (Failed msg) ->
                [ tableHeader config toolbarState pipeExt pipeInt m.state
                , bigText msg
                ]



-- Header


tableHeader : Config a b tbstate msg -> tbstate -> Pipe msg -> Pipe msg -> State -> Html msg
tableHeader ((Config cfg) as config) toolbarState pipeExt pipeInt state =
    let
        stickyStyles =
            case cfg.stickyHeader of
                Just _ ->
                    [ Tw.sticky
                    , Tw.top_0
                    , Tw.z_10 -- In case thead is sticky, we want the extra header to be on top.
                    ]
                Nothing -> []

        toolbarContainerStyles =
            [ {- Tw.h_16, -} Tw.p_4, Tw.bg_color Tw.gray_100 ]
    in
    div [ css <| [ Tw.flex, Tw.flex_col ] ++ stickyStyles ]
        ([ div
            [ css <|
                [ Tw.flex
                , Tw.flex_wrap
                , Tw.gap_2
                ]
                    ++ toolbarContainerStyles
            ]
            [ div [ css [ Tw.relative, Tw.flex, Tw.items_center, Tw.justify_between, Tw.grow ] ] <| headerSearch pipeExt pipeInt
            , div [ css [ Tw.flex, Tw.gap_2, Tw.items_center ] ] <| List.map (\f -> f toolbarState) <| cfg.toolbar
            , div [ css [ Tw.flex, Tw.gap_2, Tw.items_center ] ] <| Components.Internal.Toolbar.view config pipeExt pipeInt state
            ]
         ]
            ++ (List.map (\f -> f toolbarContainerStyles toolbarState) <| cfg.toolbarContainer)
        )


headerSearch : Pipe msg -> Pipe msg -> List (Html msg)
headerSearch pipeExt pipeInt =
    [ input
        [ css <|
            [ Tw.relative
            , Tw.inline_flex
            , Tw.text_base
            , Tw.pl_2
            , Tw.pr_20
            , Tw.w_full
            , Tw.h_10
            ]
                ++ TwUtil.border
        , type_ "text"
        , placeholder "Search..."
        , onInput
            (\s ->
                pipeInt <|
                    \state -> { state | search = s }
            )
        , onKeyDown
            (\i ->
                iff (i == 13)
                    (pipeExt <| \state -> { state | search = state.search })
                    (pipeExt <| \state -> state)
            )
        ]
        []
    , span
        [ css
            [ Tw.absolute
            , Tw.right_2
            , Tw.z_10
            , Tw.pointer_events_none
            , Tw.text_color Tw.gray_300
            ]
        ]
        [ i []
            [ Icon.magnifyingGlass
                |> Icon.styled [ SvgA.width "20", SvgA.height "20" ]
                |> Icon.view
                |> Svg.Styled.fromUnstyled
            ]
        ]
    ]



-- Content


filterRows : Config a b tbstate msg -> State -> List (Row a) -> List (Row a)
filterRows ((Config cfg) as config) state rows =
    let
        -- filter by search
        filter =
            \rs ->
                iff (String.isEmpty state.search)
                    rs
                    (List.filter
                        (\(Row a) ->
                            List.any
                                (\(Column c) ->
                                    case c.searchable of
                                        Nothing ->
                                            False

                                        Just fn ->
                                            String.contains state.search (fn a)
                                )
                                cfg.table.columns
                        )
                        rs
                    )

        frows =
            iff (cfg.type_ == Static) (filter rows) rows

        -- sort by columns
        srows =
            iff (cfg.type_ == Static) (sort cfg.table.columns state frows) frows

        -- cut the results for the pagination
        cut =
            \rs pg count ->
                rs
                    |> Array.fromList
                    |> Array.slice (pg * count) ((pg + 1) * count)
                    |> Array.toList

        ipp =
            getItemsPerPage state

        prows =
            iff (cfg.type_ == Static && cfg.pagination /= None && ipp /= 0) (cut srows state.page ipp) srows
    in
    prows


tableContent : Config a b tbstate msg -> tbstate -> Pipe msg -> Pipe msg -> State -> List (Row a) -> Html msg
tableContent ((Config cfg) as config) toolbarState pipeExt pipeInt state rows =
    let
        expandColumn =
            ifMaybe (cfg.table.expand /= Nothing) (expand pipeInt lensTable cfg.table.getID)

        subtableColumn =
            case cfg.subtable of
                Just (SubTable get _) ->
                    Just <| subtable (get >> List.isEmpty) pipeInt lensTable cfg.table.getID

                _ ->
                    Nothing

        selectColumn =
            ifMaybe (cfg.selection /= Disable) (selectionParent pipeInt config rows)

        visibleColumns =
            List.filter
                (\(Column c) -> List.member c.name <| UaDropdownMS.getSelected state.ddColumns)
                cfg.table.columns

        columns =
            visibleColumns
                |> prependMaybe subtableColumn
                |> prependMaybe expandColumn
                |> prependMaybe selectColumn

        prows =
            filterRows config state rows
    in
    div []
        [ table [ css [ Tw.w_full, Tw.bg_color Tw.white, Tw.border_collapse ] ]
            [ tableContentHead cfg.stickyHeader toolbarState (cfg.selection /= Disable) pipeExt pipeInt columns state
            , tableContentBody config pipeExt pipeInt columns state prows
            ]
        ]


tableContentHead :
    Maybe (tbstate -> Css.Style)
    -> tbstate
    -> Bool
    -> Pipe msg
    -> Pipe msg
    -> List (Column a msg)
    -> State
    -> Html msg
tableContentHead stickyHeader toolbarState hasSelection pipeExt pipeInt columns state =
    thead
        [ css <|
            case stickyHeader of
                Just calc -> [ Tw.sticky, calc toolbarState ]
                Nothing -> []
        ]
        [ tr [] <|
            List.indexedMap
                (\i ((Column c) as col) ->
                    th [ css [ Tw.p_2, Tw.text_center, Tw.text_sm, Tw.uppercase, Tw.bg_color Tw.gray_200 ] ] <|
                        c.viewHeader col
                            ( state
                            , if i == 0 && hasSelection then
                                pipeInt

                              else
                                pipeExt
                            )
                )
                columns
        ]


tableContentBody :
    Config a b tbstate msg
    -> Pipe msg
    -> Pipe msg
    -> List (Column a msg)
    -> State
    -> List (Row a)
    -> Html msg
tableContentBody config pipeExt pipeInt columns state rows =
    tbody [] <| List.concat (List.map (tableContentBodyRow config pipeExt pipeInt columns state) rows)


mouseOverXYDecoder : ({ x : Int, y : Int } -> msg) -> Decoder msg
mouseOverXYDecoder f =
    Decode.map2 (\a b -> f { x = a, y = b })
        (Decode.field "clientX" Decode.int)
        (Decode.field "clientY" Decode.int)


onMouseOverXY : ({ x : Int, y : Int } -> msg) -> Attribute msg
onMouseOverXY m =
    on "mouseover" (mouseOverXYDecoder m)


tableContentBodyRow :
    Config a b tbstate msg
    -> Pipe msg
    -> Pipe msg
    -> List (Column a msg)
    -> State
    -> Row a
    -> List (Html msg)
tableContentBodyRow ((Config cfg) as config) pipeExt pipeInt columns state (Row r) =
    [ tr
        ([ css
            [ iff (cfg.onRowClick == Nothing) Tw.cursor_default Tw.cursor_pointer
            , Css.hover [ Tw.bg_color Tw.gray_100 ]
            ]
         , tabindex 0
         ]
            ++ (case cfg.onRowClick of
                    Nothing ->
                        []

                    Just func ->
                        [ onClick <| func r ]
               )
            ++ (case cfg.onRowHover of
                    Nothing ->
                        []

                    Just func ->
                        [ onMouseOverXY <| func r ]
               )
        )
      <|
        List.map
            (\(Column c) ->
                td [ css <| [ Tw.p_2, Tw.text_center, Tw.border_b, Tw.border_color Tw.gray_300 ] ++ c.css ] <|
                    case c.lineClamp of
                        Just nlines ->
                            [ p
                                [ css
                                    [ Css.property "-webkit-box-orient" "vertical"
                                    , Css.property "-webkit-line-clamp" (String.fromInt nlines)
                                    , Css.property "line-clamp" (String.fromInt nlines)
                                    , Tw.block
                                    , Css.property "display" "-webkit-box"
                                    , Tw.overflow_hidden
                                    , Tw.text_ellipsis
                                    ]
                                ]
                              <|
                                c.viewCell r ( state, pipeExt )
                            ]

                        Nothing ->
                            c.viewCell r ( state, pipeExt )
            )
            columns
    , case ( cfg.table.expand, List.member (cfg.table.getID r) state.table.expanded ) of
        ( Just (Column c), True ) ->
            tr []
                [ td [ colspan (List.length columns) ] <|
                    c.viewCell r ( state, pipeExt )
                ]

        _ ->
            text ""
    , case ( cfg.subtable, List.member (cfg.table.getID r) state.table.subtable ) of
        ( Just (SubTable getValue conf), True ) ->
            tr []
                [ td [ colspan (List.length columns) ]
                    [ subtableContent config
                        pipeExt
                        pipeInt
                        (cfg.table.getID r)
                        conf
                        state
                        (getValue r)
                    ]
                ]

        _ ->
            text ""
    ]


subtableContent :
    Config a b tbstate msg
    -> Pipe msg
    -> Pipe msg
    -> RowID
    -> ConfTable b msg
    -> State
    -> List b
    -> Html msg
subtableContent ((Config cfg) as config) pipeExt pipeInt parent subConfig state data =
    let
        expandColumn =
            ifMaybe (subConfig.expand /= Nothing) (expand pipeInt lensTable subConfig.getID)

        rows =
            List.map Row data

        selectColumn =
            ifMaybe (cfg.selection /= Disable) (selectionChild pipeInt config rows parent)

        visibleColumns =
            List.filter
                (\(Column c) -> List.member c.name <| UaDropdownMS.getSelected state.ddSubColumns)
                subConfig.columns

        columns =
            visibleColumns
                |> prependMaybe expandColumn
                |> prependMaybe selectColumn
    in
    div [ class "subtable-content" ]
        [ {- table []
            [ tableContentHead Nothing (cfg.selection /= Disable) pipeInt pipeExt columns state
            , subtableContentBody pipeExt subConfig columns state rows
            ] -}
            text "Not Implemented"
        ]



-- Subtable Content


subtableContentBody :
    Pipe msg
    -> ConfTable a msg
    -> List (Column a msg)
    -> State
    -> List (Row a)
    -> Html msg
subtableContentBody pipeExt cfg columns state rows =
    tbody [] <| List.concat (List.map (subtableContentBodyRow pipeExt cfg columns state) rows)


subtableContentBodyRow :
    Pipe msg
    -> ConfTable a msg
    -> List (Column a msg)
    -> State
    -> Row a
    -> List (Html msg)
subtableContentBodyRow pipeExt cfg columns state (Row r) =
    [ tr [] <|
        List.map
            (\(Column c) ->
                td [ css [ Tw.p_2, Tw.border_b, Tw.border_color Tw.gray_300 ], class c.class, style "width" c.width ] <|
                    c.viewCell r ( state, pipeExt )
            )
            columns
    , case ( cfg.expand, List.member (cfg.getID r) state.subtable.expanded ) of
        ( Just (Column c), True ) ->
            tr []
                [ td [ css [ Tw.p_2, Tw.bg_color Tw.gray_50 ], colspan (List.length columns) ] <|
                    c.viewCell r ( state, pipeExt )
                ]

        _ ->
            text ""
    ]



-- Footer


tableFooter : Config a b tbstate msg -> Pipe msg -> Pipe msg -> State -> Int -> Html msg
tableFooter (Config cfg) pipeExt pipeInt state total =
    case cfg.pagination of
        None ->
            text ""

        Limit _ ->
            text ""

        _ ->
            tableFooterContent cfg.type_ pipeInt pipeExt (getItemsPerPage state) state.page total



--
-- SORT
--


sort : List (Column a msg) -> State -> List (Row a) -> List (Row a)
sort columns state rows =
    let
        compFn =
            Maybe.andThen (\(Column c) -> c.sortable) <|
                find (\(Column c) -> Just c.name == state.orderBy) columns
    in
    maybe rows (sortRowsFromStatus state.order rows) compFn


sortRowsFromStatus : Sort -> List (Row a) -> (a -> a -> Order) -> List (Row a)
sortRowsFromStatus order rows comp =
    case order of
        StandBy ->
            rows

        Descending ->
            sortRows comp rows

        Ascending ->
            List.reverse (sortRows comp rows)


sortRows : (a -> a -> Order) -> List (Row a) -> List (Row a)
sortRows comp rows =
    List.sortWith (\(Row a) (Row b) -> comp a b) rows
