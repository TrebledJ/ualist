module Components.Internal.Config exposing (..)

import Css
import Html.Styled exposing (Html)
import Components.Internal.Column exposing (..)
import Components.Internal.Data exposing (..)
import Components.Internal.State exposing (..)
import Components.Table.Types exposing (..)


type Pagination
    = ByPage { capabilities : List Int, initial : Int }
    | Progressive { initial : Int, step : Int } -- TODO: no implemented
    | Limit { capabilities : List String, initial : String }
    | None


type SubTable a b msg
    = SubTable (a -> List b) (ConfTable b msg)


type Config a b tbstate msg
    = Config (ConfigInternal a b tbstate msg)


type alias ConfigInternal a b tbstate msg =
    { type_ : Type
    , selection : Selection
    , onChangeExt : Model a -> msg
    , onChangeInt : Model a -> msg
    , onRowClick : Maybe (a -> msg)
    , onRowHover : Maybe (a -> { x: Int, y: Int } -> msg)
    , table : ConfTable a msg
    , pagination : Pagination
    , subtable : Maybe (SubTable a b msg)
    -- , errorView : String -> Html msg
    , toolbar : List (tbstate -> Html msg)
    , toolbarContainer : List (List Css.Style -> tbstate -> Html msg)
    , stickyHeader : Maybe (tbstate -> Css.Style)
    }


type alias ConfTable a msg =
    { columns : List (Column a msg)
    , getID : a -> String
    , expand : Maybe (Column a msg)
    }


config : Type -> Selection -> (Model a -> msg) -> (Model a -> msg) -> ConfTable a msg -> Config a () tbstate msg
config t s oe oi c =
    Config
        { type_ = t
        , selection = s
        , onChangeExt = oe
        , onChangeInt = oi
        , onRowClick = Nothing
        , onRowHover = Nothing
        , table = c
        , pagination = None
        , subtable = Nothing
        -- , errorView = errorView
        , toolbar = []
        , toolbarContainer = []
        , stickyHeader = Nothing
        }


static : (Model a -> msg) -> (a -> String) -> List (Column a msg) -> Config a () tbstate msg
static onChange getID columns =
    Config
        { type_ = Static
        , selection = Disable
        , onChangeExt = onChange
        , onChangeInt = onChange
        , onRowClick = Nothing
        , onRowHover = Nothing
        , table = ConfTable columns getID Nothing
        , pagination = None
        , subtable = Nothing
        -- , errorView = errorView
        , toolbar = []
        , toolbarContainer = []
        , stickyHeader = Nothing
        }


dynamic : (Model a -> msg) -> (Model a -> msg) -> (a -> String) -> List (Column a msg) -> Config a () tbstate msg
dynamic onChangeExt onChangeInt getID columns =
    Config
        { type_ = Dynamic
        , selection = Disable
        , onChangeExt = onChangeExt
        , onChangeInt = onChangeInt
        , onRowClick = Nothing
        , onRowHover = Nothing
        , table = ConfTable columns getID Nothing
        , pagination = None
        , subtable = Nothing
        -- , errorView = errorView
        , toolbar = []
        , toolbarContainer = []
        , stickyHeader = Nothing
        }


withExpand : Column a msg -> Config a b tbstate msg -> Config a b tbstate msg
withExpand col (Config c) =
    let
        t =
            c.table
    in
    Config { c | table = { t | expand = Just col } }


withSelection : Selection -> Config a b tbstate msg -> Config a b tbstate msg
withSelection s (Config c) =
    Config { c | selection = s }


withSelectionFree : Config a b tbstate msg -> Config a b tbstate msg
withSelectionFree (Config c) =
    Config { c | selection = Free }


withSelectionLinked : Config a b tbstate msg -> Config a b tbstate msg
withSelectionLinked (Config c) =
    Config { c | selection = Linked }


withSelectionLinkedStrict : Config a b tbstate msg -> Config a b tbstate msg
withSelectionLinkedStrict (Config c) =
    Config { c | selection = LinkedStrict }


withSelectionExclusive : Config a b tbstate msg -> Config a b tbstate msg
withSelectionExclusive (Config c) =
    Config { c | selection = Exclusive }


withSelectionExclusiveStrict : Config a b tbstate msg -> Config a b tbstate msg
withSelectionExclusiveStrict (Config c) =
    Config { c | selection = ExclusiveStrict }


withPagination : List Int -> Int -> Config a b tbstate msg -> Config a b tbstate msg
withPagination capabilities initial (Config c) =
    Config { c | pagination = ByPage { capabilities = capabilities, initial = initial } }

withRowLimits : List String -> String -> Config a b tbstate msg -> Config a b tbstate msg
withRowLimits capabilities initial (Config c) =
    Config { c | pagination = Limit { capabilities = capabilities, initial = initial } }


withProgressiveLoading : Int -> Int -> Config a b tbstate msg -> Config a b tbstate msg
withProgressiveLoading initial step (Config c) =
    Config { c | pagination = Progressive { initial = initial, step = step } }


withToolbar : List (tbstate -> Html msg) -> Config a b tbstate msg -> Config a b tbstate msg
withToolbar t (Config c) =
    Config { c | toolbar = t }

withToolbarContainer : List (List Css.Style -> tbstate -> Html msg) -> Config a b tbstate msg -> Config a b tbstate msg
withToolbarContainer t (Config c) =
    Config { c | toolbarContainer = t }


-- withErrorView : (String -> Html msg) -> Config a b tbstate msg -> Config a b tbstate msg
-- withErrorView t (Config c) =
--     Config { c | errorView = t }


withSubtable :
    (a -> List b)
    -> (b -> String)
    -> List (Column b msg)
    -> Maybe (Column b msg)
    -> Config a () tbstate msg
    -> Config a b tbstate msg
withSubtable getValues getID columns expand (Config c) =
    Config
        { type_ = c.type_
        , selection = c.selection
        , onChangeExt = c.onChangeExt
        , onChangeInt = c.onChangeInt
        , onRowClick = Nothing
        , onRowHover = Nothing
        , table = c.table
        , pagination = c.pagination
        , subtable = Just <| SubTable getValues { columns = columns, getID = getID, expand = expand }
        -- , errorView = c.errorView
        , toolbar = c.toolbar
        , toolbarContainer = c.toolbarContainer
        , stickyHeader = Nothing
        }

withStickyHeader : (tbstate -> Css.Style) -> Config a b tbstate msg -> Config a b tbstate msg
withStickyHeader f (Config c) = Config { c | stickyHeader = Just f }

withRowClickHandler : (a -> msg) -> Config a b tbstate msg -> Config a b tbstate msg
withRowClickHandler h (Config c) = Config { c | onRowClick = Just h }

withRowHoverHandler : (a -> { x: Int, y: Int } -> msg) -> Config a b tbstate msg -> Config a b tbstate msg
withRowHoverHandler h (Config c) = Config { c | onRowHover = Just h }

-- errorView : String -> Html msg
-- errorView msg =
--     div [ class "table-data-error" ] [ text msg ]


pipeInternal : Config a b tbstate msg -> Model a -> Pipe msg
pipeInternal (Config { onChangeInt }) (Model { rows, state }) fn =
    onChangeInt <| Model { rows = rows, state = fn state }


pipeExternal : Config a b tbstate msg -> Model a -> Pipe msg
pipeExternal (Config { onChangeExt }) (Model { rows, state }) fn =
    onChangeExt <| Model { rows = rows, state = fn state }
