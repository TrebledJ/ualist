module Components.Internal.Data exposing (..)

import Components.Internal.State exposing (Pagination, RowID, State)
import Components.Table.Types exposing (..)
import Monocle.Lens exposing (Lens)


type alias Statable p =
    Model { p | state : State }


type Model a
    = Model
        { state : State
        , rows : Rows a
        }


type Row a
    = Row a


type Rows a
    = Rows
        (Status
            { total : Int
            , rows : List (Row a)
            }
        )


get : Model a -> List a
get (Model model) =
    case model.rows of
        Rows (Loaded { rows }) ->
            rows |> List.map (\(Row x) -> x)

        _ ->
            []


loaded : Model a -> List a -> Int -> Model a
loaded (Model model) rows n =
    Model { model | rows = Rows <| Loaded { total = n, rows = List.map Row rows } }


withStatus : String -> Model a -> Model a
withStatus msg (Model model) =
    Model { model | rows = Rows <| Status msg }


failed : Model a -> String -> Model a
failed (Model model) msg =
    Model { model | rows = Rows <| Failed msg }


pagination : Model a -> Pagination
pagination (Model { state }) =
    Components.Internal.State.pagination state


getState : Model a -> State
getState (Model { state }) =
    state


getRows : Model a -> Rows a
getRows (Model { rows }) =
    rows


stateLens : Lens (Model a) State
stateLens =
    Lens getState (\b (Model { rows }) -> Model { state = b, rows = rows })


rowsLens : Lens (Model a) (Rows a)
rowsLens =
    Lens getRows (\b (Model { state }) -> Model { state = state, rows = b })


selected : Model a -> List RowID
selected (Model { state }) =
    Components.Internal.State.selected state


subSelected : Model a -> List RowID
subSelected (Model { state }) =
    Components.Internal.State.subSelected state
