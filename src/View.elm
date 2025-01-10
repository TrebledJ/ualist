module View exposing (main)

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
import Components.Internal.Data exposing (..)
import Components.Internal.State exposing (..)



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
    , Cmd.batch []
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

getState : Components.Internal.Data.Model a -> Components.Internal.State.State
getState (Components.Internal.Data.Model mod) = mod.state

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
                    Debug.log "called" "TableMsg"
                
                _ =
                    Debug.log "data" <| getState model.tableModel.table

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
            [ Attr.css [ Tw.w_screen, Tw.mx_auto ]
            ]
            [ viewMain model
            ]


viewMain : Model -> Html Msg
viewMain model =
    UaTable.view model.tableModel |> HtmlS.map TableMsg
