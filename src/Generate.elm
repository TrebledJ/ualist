module Generate exposing (main)

-- import Html.Attributes exposing (..)
-- import Html.Events exposing (..)

import Browser
import Css
import Css.Global
import Html
import Html.Styled as HtmlS exposing (..)
import Html.Styled.Attributes as Attr
import Html.Styled.Events as Events
import Http
import Tailwind.Breakpoints as Breakpoints
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw
import Task
import Components.UaTable as UaTable



-- MAIN


main =
    Browser.element { init = init, update = update, view = view, subscriptions = subscriptions }



-- MODEL


type alias Model =
    { filterBrowser : String
    , filterOsDevice : String
    , filterHost : String
    , filterLimit : Int
    , tableModel : UaTable.Model
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { filterBrowser = "firefox"
      , filterOsDevice = "linux"
      , filterHost = ""
      , filterLimit = 10
      , tableModel = UaTable.init
      }
    , Cmd.batch [ UaTable.fetchData |> Cmd.map TableMsg, UaTable.fetchUserAgent "curl/2.0.0" ]
    )



-- UPDATE


type FilterType
    = Browser String
    | OSDevice String
    | Host String
    | Limit String


type Msg
    = ChangeFilter FilterType
    | TableMsg UaTable.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeFilter (Browser s) ->
            ( { model | filterBrowser = Debug.log "log: " s }, Cmd.none )

        ChangeFilter _ ->
            ( model, Cmd.none )

        TableMsg m ->
            let
                _ =
                    Debug.log "TableMsg called" ""

                ( newTableModel, cmd ) =
                    UaTable.update m model.tableModel
            in
            ( { model | tableModel = newTableModel }, Cmd.map TableMsg cmd )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ UaTable.subscriptions model.tableModel |> Sub.map TableMsg
        ]



-- VIEW


view : Model -> Html.Html Msg
view model =
    HtmlS.toUnstyled <|
        div
            [ Attr.css [ Tw.container, Tw.mx_auto, Tw.p_4 ]
            ]
            [ viewSelectors model
            , viewMain model
            ]


viewSelectors : Model -> Html Msg
viewSelectors model =
    div [ Attr.css [ Tw.grid, Tw.grid_cols_1, Breakpoints.md [ Tw.grid_cols_3 ], Tw.gap_4, Tw.mb_4 ] ]
        [ viewSelector "Browser" model.filterBrowser (ChangeFilter << Browser)
        , viewSelector "OS/Device" model.filterOsDevice (ChangeFilter << OSDevice)
        , viewSelector "Limit" (String.fromInt model.filterLimit) (ChangeFilter << Limit)
        ]


viewSelector : String -> String -> (String -> Msg) -> Html Msg
viewSelector label value onChange =
    div [ Attr.css [ Tw.flex, Tw.flex_col ] ]
        [ div [ Attr.css [ Tw.font_semibold, Tw.mb_1 ] ] [ text label ]
        , input
            [ Attr.css [ Tw.border, Tw.rounded, Tw.p_2 ]
            , Attr.placeholder label
            , Attr.value value
            , Events.onInput onChange
            ]
            []
        ]


viewMain : Model -> Html Msg
viewMain model =
    UaTable.view model.tableModel |> HtmlS.map TableMsg
