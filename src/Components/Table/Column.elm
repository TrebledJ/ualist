module Components.Table.Column exposing
    ( Column, ViewCell, ViewHeader
    , bool, default, float, int, string
    , withClass, withCss, withLineClamp, withDefault, withHeaderView, withHiddable, withHidden
    , withSearchable, withSortable, withUnSortable, withView, withWidth
    )

{-| Configure the table's columns.

@docs Column, ViewCell, ViewHeader


# Constructors

@docs bool, default, float, int, string


# Customization

@docs withClass, withDefault, withHeaderView, withHiddable, withHidden
@docs withSearchable, withSortable, withUnSortable, withView, withWidth

-}

import Css
import Components.Internal.Column


{-| Column's configuration (opaque).
-}
type alias Column a msg =
    Components.Internal.Column.Column a msg


{-| Function to render a cell.
-}
type alias ViewCell a msg =
    Components.Internal.Column.ViewCell a msg


{-| Function to render the column's header.
-}
type alias ViewHeader a msg =
    Components.Internal.Column.ViewHeader a msg


{-| Define a function to sort the data (for the dynamic table, a fake function
should be defined here and capture the pagination in the `update` function to
load the sorted data).
-}
withSortable : Maybe (a -> a -> Order) -> Column a msg -> Column a msg
withSortable =
    Components.Internal.Column.withSortable


{-| Define an unsortable column.
-}
withUnSortable : Column a msg -> Column a msg
withUnSortable =
    Components.Internal.Column.withUnSortable


{-| Define a function to filter the data in the table (usefull only for the static table).
-}
withSearchable : Maybe (a -> String) -> Column a msg -> Column a msg
withSearchable =
    Components.Internal.Column.withSearchable


{-| Define a hiddable column.
-}
withHiddable : Bool -> Column a msg -> Column a msg
withHiddable =
    Components.Internal.Column.withHiddable


{-| Define a column visible by default.
-}
withDefault : Bool -> Column a msg -> Column a msg
withDefault =
    Components.Internal.Column.withDefault


{-| Define a static width (CSS value).
-}
withWidth : String -> Column a msg -> Column a msg
withWidth =
    Components.Internal.Column.withWidth


{-| Define a hidden column.
-}
withHidden : Column a msg -> Column a msg
withHidden =
    Components.Internal.Column.withHidden


{-| Define a specific function to render the value.
-}
withView : ViewCell a msg -> Column a msg -> Column a msg
withView =
    Components.Internal.Column.withView


{-| Define a specific function to render the header.
-}
withHeaderView : ViewHeader a msg -> Column a msg -> Column a msg
withHeaderView =
    Components.Internal.Column.withHeaderView


{-| Define a CSS class for the column.
-}
withClass : String -> Column a msg -> Column a msg
withClass =
    Components.Internal.Column.withClass

{-| Define CSS styles for the column.
-}
withCss : List Css.Style -> Column a msg -> Column a msg
withCss =
    Components.Internal.Column.withCss

{-| Define CSS styles for the column.
-}
withLineClamp : Maybe Int -> Column a msg -> Column a msg
withLineClamp =
    Components.Internal.Column.withLineClamp


{-| Create an agnostic column with a rendering function.
-}
default : String -> String -> ViewCell a msg -> Column a msg
default =
    Components.Internal.Column.default


{-| Create an column for integers.
-}
int : (a -> Int) -> String -> String -> Column a msg
int =
    Components.Internal.Column.int


{-| Create a column for strings.
-}
string : (a -> String) -> String -> String -> Column a msg
string =
    Components.Internal.Column.string


{-| Create a column for booleans.
-}
bool : (a -> Bool) -> String -> String -> Column a msg
bool =
    Components.Internal.Column.bool


{-| Create a column for floats.
-}
float : (a -> Float) -> String -> String -> Column a msg
float =
    Components.Internal.Column.float
