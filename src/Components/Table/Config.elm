module Components.Table.Config exposing
    ( Config
    , static, dynamic
    , withExpand, withSelection, withSelectionFree, withSelectionLinked
    , withSelectionLinkedStrict, withSelectionExclusive
    , withSelectionExclusiveStrict, withPagination, withProgressiveLoading
    , withToolbar, withErrorView, withSubtable
    , withStickyHeader
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
import Components.Internal.Data exposing (Model)
import Components.Table.Column exposing (..)
import Components.Table.Types exposing (..)
import Html.Styled exposing (Html)


{-| Table's configuration (opaque).
-}
type alias Config a b msg =
    Components.Internal.Config.Config a b msg


{-| Define a configuration for a table with static data (i.e. with all loaded
data at once).
-}
static : (Model a -> msg) -> (a -> String) -> List (Column a msg) -> Config a () msg
static =
    Components.Internal.Config.static


{-| Define a configuration for a table with dynamic data (i.e. with paginated
loaded data).
-}
dynamic : (Model a -> msg) -> (Model a -> msg) -> (a -> String) -> List (Column a msg) -> Config a () msg
dynamic =
    Components.Internal.Config.dynamic


{-| Add an full-width expandable row.
-}
withExpand : Column a msg -> Config a b msg -> Config a b msg
withExpand =
    Components.Internal.Config.withExpand


{-| Enable the selection (see `Selection` type for the different logics).
-}
withSelection : Selection -> Config a b msg -> Config a b msg
withSelection =
    Components.Internal.Config.withSelection


{-| Enable the selection with the _free_ logic (see `Selection` for more details).
-}
withSelectionFree : Config a b msg -> Config a b msg
withSelectionFree =
    Components.Internal.Config.withSelectionFree


{-| Enable the selection with the _linked_ logic (see `Selection` for more details).
-}
withSelectionLinked : Config a b msg -> Config a b msg
withSelectionLinked =
    Components.Internal.Config.withSelectionLinked


{-| Enable the selection with the _linked_ logic (see `Selection` for more details).
-}
withSelectionLinkedStrict : Config a b msg -> Config a b msg
withSelectionLinkedStrict =
    Components.Internal.Config.withSelectionLinkedStrict


{-| Enable the selection with the _exclusive_ logic (see `Selection` for more details).
-}
withSelectionExclusive : Config a b msg -> Config a b msg
withSelectionExclusive =
    Components.Internal.Config.withSelectionExclusive


{-| Enable the selection with the _strict excluive_ logic (see `Selection` for more details).
-}
withSelectionExclusiveStrict : Config a b msg -> Config a b msg
withSelectionExclusiveStrict =
    Components.Internal.Config.withSelectionExclusiveStrict


{-| Enable the pagination and define the page sizes and the detault page size.
-}
withPagination : List Int -> Int -> Config a b msg -> Config a b msg
withPagination =
    Components.Internal.Config.withPagination


{-| Enable the progressive loading pagination (not implemented).
-}
withProgressiveLoading : Int -> Int -> Config a b msg -> Config a b msg
withProgressiveLoading =
    Components.Internal.Config.withProgressiveLoading


{-| Add a custom toolbar.
-}
withToolbar : List (Html msg) -> Config a b msg -> Config a b msg
withToolbar =
    Components.Internal.Config.withToolbar


{-| Define a specific error message.
-}
withErrorView : (String -> Html msg) -> Config a b msg -> Config a b msg
withErrorView =
    Components.Internal.Config.withErrorView


{-| Define a subtable.
-}
withSubtable : (a -> List b) -> (b -> String) -> List (Column b msg) -> Maybe (Column b msg) -> Config a () msg -> Config a b msg
withSubtable =
    Components.Internal.Config.withSubtable


{-| Enable sticky headers.
-}
withStickyHeader : Config a b msg -> Config a b msg
withStickyHeader =
    Components.Internal.Config.withStickyHeader
