module Components.Internal.State exposing (..)

import Monocle.Lens exposing (Lens, compose)
import Components.Table.Types exposing (Sort(..))
import Components.UaDropdownMultiSelect as UaDropdown exposing (State)


type alias RowID =
    String


type alias ColumnName =
    String


type alias Pagination =
    { search : String
    , orderBy : String
    , order : Sort
    , page : Int
    , byPage : Int
    }


type alias State =
    { orderBy : Maybe String
    , order : Sort
    , page : Int
    , byPage : Int
    , search : String
    , ddPagination : UaDropdown.State
    , ddColumns : UaDropdown.State
    , ddSubColumns : UaDropdown.State
    , table : StateTable
    , subtable : StateTable
    }


type alias StateTable =
    { {- visible : List ColumnName
    ,  -}selected : List RowID
    , expanded : List RowID
    , subtable : List RowID
    }


selected : State -> List RowID
selected state =
    (compose lensTable lensSelected).get state


subSelected : State -> List RowID
subSelected state =
    (compose lensSubTable lensSelected).get state


lensSelected : Lens StateTable (List RowID)
lensSelected =
    Lens .selected (\b a -> { a | selected = b })


lensTable : Lens State StateTable
lensTable =
    Lens .table (\b a -> { a | table = b })


lensSubTable : Lens State StateTable
lensSubTable =
    Lens .subtable (\b a -> { a | subtable = b })


next : Sort -> Sort
next status =
    case status of
        StandBy ->
            Descending

        Descending ->
            Ascending

        Ascending ->
            Descending


pagination : State -> Pagination
pagination state =
    Pagination state.search
        (Maybe.withDefault "" state.orderBy)
        state.order
        state.page
        state.byPage
