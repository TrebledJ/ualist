module View exposing (main)

import Browser
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode exposing (Decoder, Value)
import UaTable
import Task



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
      , Cmd.batch [ UaTable.fetchData |> Cmd.map TableMsg, UaTable.fetchUserAgent "curl/1.0.0" ]
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
subscriptions _ =
    -- Sub.none
    Sub.batch
        [ UaTable.recvUserAgent UaTable.RecvUserAgent |> Sub.map TableMsg
        , UaTable.recvUserAgentBatch UaTable.RecvUserAgentBatch |> Sub.map TableMsg
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div [] [ viewSelectors model, viewMain model ]



-- div []
--     [ button [ onClick Decrement ] [ text "-" ]
--     , div [] [ text (String.fromInt model) ]
--     , button [ onClick Increment ] [ text "+" ]
--     ]


viewSelectors : Model -> Html Msg
viewSelectors model =
    div []
        [ div []
            [ div [] [ text "Browser" ]
            , input [ placeholder "firefox", value model.filterBrowser, onInput <| ChangeFilter << Browser ] []
            ]
        , div []
            [ div [] [ text "OS/Device" ]
            , input [ placeholder "linux", value model.filterOsDevice, onInput <| ChangeFilter << OSDevice ] []
            ]
        , div []
            [ div [] [ text "Limit" ]
            , input [ placeholder "10", value (String.fromInt model.filterLimit), onInput <| ChangeFilter << Limit ] []
            ]
        ]


viewMain : Model -> Html Msg
viewMain model =
    UaTable.view model.tableModel |> Html.map TableMsg
