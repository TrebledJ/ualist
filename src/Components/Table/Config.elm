module Components.Table.Config exposing
    ( Config
    , static, dynamic
    , withExpand, withSelection, withSelectionFree, withSelectionLinked
    , withSelectionLinkedStrict, withSelectionExclusive
    , withSelectionExclusiveStrict, withPagination, withRowLimits, withProgressiveLoading
    , withToolbar, withToolbarContainer, {- withErrorView, -} withSubtable
    , withStickyHeader, withRowClickHandler, withRowHoverHandler
    )

{-| Configuration of the table.

@docs Config


# Constructors

@docs static, dynamic


# Customizations

@docs withExpand, withSelection, withSelectionFree, withSelectionLinked
@docs withSelectionLinkedStrict, withSelectionExclusive
@docs withSelectionExclusiveStrict, withPagination, withProgressiveLoading
@docs withToolbar, withErrorView, withSubtable

-}

import Components.Internal.Config
import Components.Internal.Data exposing (Model, Row)
import Components.Table.Column exposing (..)
import Components.Table.Types exposing (..)
import Css
import Html.Styled exposing (Html)


{-| Table's configuration (opaque).
-}
type alias Config a b tbstate msg =
    Components.Internal.Config.Config a b tbstate msg


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


{-| Add an full-width expandable row.
-}
withExpand : Column a msg -> Config a b tbstate msg -> Config a b tbstate msg
withExpand =
    Components.Internal.Config.withExpand


{-| Enable the selection (see `Selection` type for the different logics).
-}
withSelection : Selection -> Config a b tbstate msg -> Config a b tbstate msg
withSelection =
    Components.Internal.Config.withSelection


{-| Enable the selection with the _free_ logic (see `Selection` for more details).
-}
withSelectionFree : Config a b tbstate msg -> Config a b tbstate msg
withSelectionFree =
    Components.Internal.Config.withSelectionFree


{-| Enable the selection with the _linked_ logic (see `Selection` for more details).
-}
withSelectionLinked : Config a b tbstate msg -> Config a b tbstate msg
withSelectionLinked =
    Components.Internal.Config.withSelectionLinked


{-| Enable the selection with the _linked_ logic (see `Selection` for more details).
-}
withSelectionLinkedStrict : Config a b tbstate msg -> Config a b tbstate msg
withSelectionLinkedStrict =
    Components.Internal.Config.withSelectionLinkedStrict


{-| Enable the selection with the _exclusive_ logic (see `Selection` for more details).
-}
withSelectionExclusive : Config a b tbstate msg -> Config a b tbstate msg
withSelectionExclusive =
    Components.Internal.Config.withSelectionExclusive


{-| Enable the selection with the _strict excluive_ logic (see `Selection` for more details).
-}
withSelectionExclusiveStrict : Config a b tbstate msg -> Config a b tbstate msg
withSelectionExclusiveStrict =
    Components.Internal.Config.withSelectionExclusiveStrict


{-| Enable the pagination and define the page sizes and the detault page size.
-}
withPagination : List Int -> Int -> Config a b tbstate msg -> Config a b tbstate msg
withPagination =
    Components.Internal.Config.withPagination


{-| Enable the pagination and define the page sizes and the detault page size.
-}
withRowLimits : List String -> String -> Config a b tbstate msg -> Config a b tbstate msg
withRowLimits =
    Components.Internal.Config.withRowLimits


{-| Enable the progressive loading pagination (not implemented).
-}
withProgressiveLoading : Int -> Int -> Config a b tbstate msg -> Config a b tbstate msg
withProgressiveLoading =
    Components.Internal.Config.withProgressiveLoading


{-| Add a custom toolbar.
-}
withToolbar : List (tbstate -> Html msg) -> Config a b tbstate msg -> Config a b tbstate msg
withToolbar =
    Components.Internal.Config.withToolbar


{-| Add a custom toolbar.
-}
withToolbarContainer : List (List Css.Style -> tbstate -> Html msg) -> Config a b tbstate msg -> Config a b tbstate msg
withToolbarContainer =
    Components.Internal.Config.withToolbarContainer


-- {-| Define a specific error message.
-- -}
-- withErrorView : (String -> Html msg) -> Config a b tbstate msg -> Config a b tbstate msg
-- withErrorView =
--     Components.Internal.Config.withErrorView


{-| Define a subtable.
-}
withSubtable : (a -> List b) -> (b -> String) -> List (Column b msg) -> Maybe (Column b msg) -> Config a () tbstate msg -> Config a b tbstate msg
withSubtable =
    Components.Internal.Config.withSubtable


{-| Enable sticky headers.
-}
withStickyHeader : (tbstate -> Css.Style) -> Config a b tbstate msg -> Config a b tbstate msg
withStickyHeader =
    Components.Internal.Config.withStickyHeader

{-| Handle clicks on individual rows.
-}
withRowClickHandler : (a -> msg) -> Config a b tbstate msg -> Config a b tbstate msg
withRowClickHandler =
    Components.Internal.Config.withRowClickHandler

{-| Handle hover events on individual rows.
-}
withRowHoverHandler : (a -> { x: Int, y: Int } -> msg) -> Config a b tbstate msg -> Config a b tbstate msg
withRowHoverHandler =
    Components.Internal.Config.withRowHoverHandler
