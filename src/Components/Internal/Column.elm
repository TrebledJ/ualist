module Components.Internal.Column exposing (..)

import Components.Internal.Data exposing (..)
import Components.Internal.State exposing (..)
import Components.Internal.Util exposing (..)
import Components.Table.Types exposing (Sort(..))
import Css
import FontAwesome.Solid as Icon
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick)
import Monocle.Lens exposing (Lens)
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw
import TwUtil


type alias Pipe msg =
    (State -> State) -> msg


type alias ViewCell a msg =
    a -> ( State, Pipe msg ) -> List (Html msg)


type alias ViewHeader a msg =
    Column a msg -> ( State, Pipe msg ) -> List (Html msg)


type Column a msg
    = Column
        { name : String
        , abbrev : String
        , class : String
        , css : List Css.Style
        , lineClamp : Maybe Int
        , width : String
        , sortable : Maybe (a -> a -> Order)
        , hiddable : Bool
        , searchable : Maybe (a -> String)
        , visible : Bool
        , viewCell : ViewCell a msg
        , viewHeader : ViewHeader a msg
        , default : Bool
        }


withUnSortable : Column a msg -> Column a msg
withUnSortable (Column col) =
    Column { col | sortable = Nothing }


withSortable : Maybe (a -> a -> Order) -> Column a msg -> Column a msg
withSortable value (Column col) =
    Column { col | sortable = value }


withSearchable : Maybe (a -> String) -> Column a msg -> Column a msg
withSearchable value (Column col) =
    Column { col | searchable = value }


withHiddable : Bool -> Column a msg -> Column a msg
withHiddable value (Column col) =
    Column { col | hiddable = value }


withDefault : Bool -> Column a msg -> Column a msg
withDefault value (Column col) =
    Column { col | default = value }


withWidth : String -> Column a msg -> Column a msg
withWidth w (Column col) =
    Column { col | width = w }


withHidden : Column a msg -> Column a msg
withHidden (Column col) =
    Column { col | visible = False }


withView : ViewCell a msg -> Column a msg -> Column a msg
withView view (Column col) =
    Column { col | viewCell = view }


withHeaderView : ViewHeader a msg -> Column a msg -> Column a msg
withHeaderView view (Column col) =
    Column { col | viewHeader = view }


withClass : String -> Column a msg -> Column a msg
withClass name (Column col) =
    Column { col | class = name }


withCss : List Css.Style -> Column a msg -> Column a msg
withCss css (Column col) =
    Column { col | css = css }


withLineClamp : Maybe Int -> Column a msg -> Column a msg
withLineClamp clamp (Column col) =
    Column { col | lineClamp = clamp }


default : String -> String -> ViewCell a msg -> Column a msg
default name abbrev view =
    Column
        { name = name
        , abbrev = abbrev
        , width = ""
        , class = ""
        , css = []
        , lineClamp = Nothing
        , sortable = Nothing
        , hiddable = True
        , searchable = Nothing
        , visible = True
        , viewCell = view
        , viewHeader = viewHeader
        , default = True
        }


int : (a -> Int) -> String -> String -> Column a msg
int get name abbrev =
    Column
        { name = name
        , abbrev = abbrev
        , width = ""
        , class = ""
        , css = []
        , lineClamp = Nothing
        , sortable = Just <| \a b -> compare (get a) (get b)
        , searchable = Just (String.fromInt << get)
        , visible = True
        , hiddable = True
        , viewCell = \x _ -> [ text <| String.fromInt (get x) ]
        , viewHeader = viewHeader
        , default = True
        }


string : (a -> String) -> String -> String -> Column a msg
string get name abbrev =
    Column
        { name = name
        , abbrev = abbrev
        , width = ""
        , class = ""
        , css = []
        , lineClamp = Nothing
        , sortable = Just <| \a b -> compare (get a) (get b)
        , searchable = Just get
        , visible = True
        , hiddable = True
        , viewCell = \x _ -> [ text (get x) ]
        , viewHeader = viewHeader
        , default = True
        }


bool : (a -> Bool) -> String -> String -> Column a msg
bool get name abbrev =
    Column
        { name = name
        , abbrev = abbrev
        , width = ""
        , class = ""
        , css = []
        , lineClamp = Nothing
        , sortable = Nothing
        , searchable = Nothing
        , visible = True
        , hiddable = True
        , viewCell = \x _ -> [ text <| iff (get x) "☑" "☐" ]
        , viewHeader = viewHeader
        , default = True
        }


float : (a -> Float) -> String -> String -> Column a msg
float get name abbrev =
    Column
        { name = name
        , abbrev = abbrev
        , width = ""
        , class = ""
        , css = []
        , lineClamp = Nothing
        , sortable = Just <| \a b -> compare (get a) (get b)
        , searchable = Just (String.fromFloat << get)
        , visible = True
        , hiddable = True
        , viewCell = \x _ -> [ text <| String.fromFloat (get x) ]
        , viewHeader = viewHeader
        , default = True
        }


clipboard : (a -> String) -> String -> String -> Column a msg
clipboard get name abbrev =
    Column
        { name = name
        , abbrev = abbrev
        , width = ""
        , class = ""
        , css = []
        , lineClamp = Nothing
        , sortable = Just <| \a b -> compare (get a) (get b)
        , searchable = Just get
        , visible = True
        , hiddable = True
        , viewCell = viewClipboard << get
        , viewHeader = viewHeader
        , default = True
        }


expand : Pipe msg -> Lens State StateTable -> (a -> String) -> Column a msg
expand pipe lens getID =
    Column
        { name = ""
        , abbrev = ""
        , width = "30px"
        , class = "col-btn-expand"
        , css = []
        , lineClamp = Nothing
        , sortable = Nothing
        , searchable = Nothing
        , visible = True
        , hiddable = False
        , viewCell = \v ( s, _ ) -> viewExpand lens getID v ( s, pipe )
        , viewHeader = viewHeader
        , default = True
        }


subtable : (a -> Bool) -> Pipe msg -> Lens State StateTable -> (a -> String) -> Column a msg
subtable isDisable pipe lens getID =
    Column
        { name = ""
        , abbrev = ""
        , width = "30px"
        , class = "col-btn-substable"
        , css = []
        , lineClamp = Nothing
        , sortable = Nothing
        , searchable = Nothing
        , visible = True
        , hiddable = False
        , viewCell = \v ( s, _ ) -> viewSubtable isDisable lens getID v ( s, pipe )
        , viewHeader = viewHeader
        , default = True
        }


viewExpand : Lens State StateTable -> (a -> String) -> a -> ( State, Pipe msg ) -> List (Html msg)
viewExpand lens getID v ( state, pipe ) =
    let
        id =
            getID v

        conf =
            lens.get state

        isExpanded =
            List.member id conf.expanded

        updatedExpand =
            iff isExpanded (List.filter ((/=) id) conf.expanded) (id :: conf.expanded)
    in
    [ a
        [ class "btn-expand"
        , onClick <| pipe <| \s -> lens.set { conf | expanded = updatedExpand } s
        ]
        [ span [ class <| iff isExpanded "gg-collapse" "gg-expand" ] [] ]
    ]


viewSubtable : (a -> Bool) -> Lens State StateTable -> (a -> String) -> a -> ( State, Pipe msg ) -> List (Html msg)
viewSubtable isDisable lens getID v ( state, pipe ) =
    if isDisable v then
        [ a [ class "btn-subtable is-disabled", disabled True ]
            [ span [ class "gg-plus" ] [] ]
        ]

    else
        let
            id =
                getID v

            conf =
                lens.get state

            isExpanded =
                List.member id conf.subtable

            updatedExpand =
                iff isExpanded (List.filter ((/=) id) conf.subtable) (id :: conf.subtable)
        in
        [ a
            [ class "btn-subtable"
            , onClick <| pipe <| \s -> lens.set { conf | subtable = updatedExpand } s
            ]
            [ span [ class <| iff isExpanded "gg-minus" "gg-plus" ] [] ]
        ]


viewHeader : Column a msg -> ( State, Pipe msg ) -> List (Html msg)
viewHeader (Column col) ( state, pipe ) =
    [ div
        [ css
            [ Tw.flex
            , Tw.justify_center
            , Tw.items_center
            , Tw.text_sm
            , Tw.uppercase
            ]
        ]
        [ iff (String.isEmpty col.abbrev)
            (span [] [ text col.name ])
            (abbr [ title col.name ] [ text col.abbrev ])
        , iff (col.sortable /= Nothing)
            (iff (state.orderBy == Just col.name)
                (a
                    [ class "sort"
                    , onClick <| pipe <| \s -> { s | order = next s.order }
                    ]
                    [ TwUtil.icon <|
                        case state.order of
                            Ascending ->
                                Icon.sortUp

                            Descending ->
                                Icon.sortDown

                            StandBy ->
                                Icon.sort
                    ]
                )
                (a
                    [ class "sort"
                    , onClick <| pipe <| \s -> { s | order = Ascending, orderBy = Just col.name }
                    ]
                    [ TwUtil.icon Icon.sort ]
                )
            )
            (text "")
        ]
    ]


viewClipboard : String -> ( State, Pipe msg ) -> List (Html msg)
viewClipboard _ _ =
    -- TODO
    [ div [] [ text "📋" ] ]
