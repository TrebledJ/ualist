module Components.Table exposing
    ( Model, Row, Rows, RowID, get, getFiltered, getItemsPerPage, init, loaded, loadedDynamic, loadedStatic, withStatus, failed
    , Pipe, State, Pagination, pagination, selected, subSelected
    , Config, Column, static, dynamic
    , view, subscriptions
    )

{-| Full featured table.


# Data

@docs Model, Row, Rows, RowID, get, init, loaded, loadedDynamic, loadedStatic, loading, failed


# State

@docs Pipe, State, Pagination, pagination, selected, subSelected


# Configuration

@docs Config, Column, static, dynamic


# View

@docs view, subscriptions

-}

import Html.Styled exposing (Html)
import Components.Internal.Column
import Components.Internal.Config
import Components.Internal.Data
import Components.Internal.State
import Components.Internal.Subscription
import Components.Internal.Table
import Components.Table.Types exposing (..)


{-| Model of component (opaque).
-}
type alias Model a =
    Components.Internal.Data.Model a


{-| Pipe for the table's messages to change the state.
-}
type alias Pipe msg =
    Components.Internal.Column.Pipe msg


{-| Internal table's state.
-}
type alias State =
    Components.Internal.State.State


{-| Table's configuration (opaque).
-}
type alias Config a b tbstate msg =
    Components.Internal.Config.Config a b tbstate msg


{-| Column's configuration (opaque).
-}
type alias Column a msg =
    Components.Internal.Column.Column a msg


{-| Table's row (opaque).
-}
type alias Row a =
    Components.Internal.Data.Row a


{-| List of table's rows (opaque).
-}
type alias Rows a =
    Components.Internal.Data.Rows a


{-| Unique ID of one row.
-}
type alias RowID =
    Components.Internal.State.RowID


{-| Pagination values.
-}
type alias Pagination =
    Components.Internal.State.Pagination


{-| Table's view.
-}
view : Config a b tbstate msg -> tbstate -> Model a -> Html msg
view =
    Components.Internal.Table.view


{-| Initialize the table's model.
-}
init : Config a b tbstate msg -> Model a
init =
    Components.Internal.Table.init


{-| Get the loaded data.
-}
get : Model a -> List a
get =
    Components.Internal.Data.get

{-| Get the loaded data with search filters applied.
-}
getFiltered : Config a b tbstate msg -> Model a -> List a
getFiltered =
    Components.Internal.Table.getFiltered

{-| Get the allowed number of items per page. Returns 0 if pagination isn't used or no limit is specified.
-}
getItemsPerPage : Model a -> Int
getItemsPerPage (Components.Internal.Data.Model { state }) = Components.Internal.State.getItemsPerPage state

{-| Load the data in the model with the total number of rows if the data are
incomplete.
-}
loaded : Model a -> List a -> Int -> Model a
loaded =
    Components.Internal.Data.loaded


{-| Similar to `loaded`. Load partial data in the model and specified the total
number of rows.
-}
loadedDynamic : List a -> Int -> Model a -> Model a
loadedDynamic rows total model =
    Components.Internal.Data.loaded model rows total


{-| Similar to `loaded` with all data so `List.length rows == total`.
-}
loadedStatic : List a -> Model a -> Model a
loadedStatic rows model =
    Components.Internal.Data.loaded model rows (List.length rows)


{-| Display a status.
-}
withStatus : String -> Model a -> Model a
withStatus =
    Components.Internal.Data.withStatus


{-| Data loading has failed.
-}
failed : Model a -> String -> Model a
failed =
    Components.Internal.Data.failed


{-| Get the pagination values from model.
-}
pagination : Model a -> Pagination
pagination =
    Components.Internal.Data.pagination


{-| Table's subscriptions.
-}
subscriptions : Config a b tbstate msg -> Model a -> Sub msg
subscriptions =
    Components.Internal.Subscription.subscriptions


{-| Define a configuration for a table with static data (i.e. with all loaded
data at once).
-}
static : (Model a -> msg) -> (a -> String) -> List (Column a msg) -> Config a () tbstate msg
static =
    Components.Internal.Config.static


{-| Define a configuration for a table with dynamic data (i.e. with paginated
loaded data).
-}
dynamic : (Model a -> msg) -> (Model a -> msg) -> (a -> String) -> List (Column a msg) -> Config a () tbstate msg
dynamic =
    Components.Internal.Config.dynamic


{-| Return the list of selected rows.
-}
selected : Model a -> List RowID
selected =
    Components.Internal.Data.selected


{-| Return the list of selected rows in the sub tables.
-}
subSelected : Model a -> List RowID
subSelected =
    Components.Internal.Data.subSelected
