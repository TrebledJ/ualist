module Main exposing (main)

import Browser
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode exposing (Decoder, Value)
import MyTable
import Table
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
    , tableModel : MyTable.Model
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { filterBrowser = "firefox"
      , filterOsDevice = "linux"
      , filterHost = ""
      , filterLimit = 10
      , tableModel = Table.init MyTable.config
      }
      -- , Cmd.none
    , Cmd.batch [MyTable.get 1 |> Cmd.map TableMsg, MyTable.fetchUaDeets ["curl/1.0.0"]]
    -- , Cmd.batch [fetchUaDeets "test ua"]
    )



-- UPDATE


type FilterType
    = Browser String
    | OSDevice String
    | Host String
    | Limit String


type Msg
    = ChangeFilter FilterType
    | TableMsg MyTable.Msg
    -- | RecvUaDeets String



-- type alias UaParsedData =
--     { browserName : String
--     , deviceModel : String
--     , deviceVendor : String
--     , osName : String
--     }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeFilter (Browser s) ->
            ( { model | filterBrowser = Debug.log "log: " s }, Cmd.none )

        ChangeFilter _ ->
            ( model, Cmd.none )

        TableMsg m ->
            let
                _ = Debug.log "TableMsg called" ""
                ( newTableModel, cmd ) =
                    MyTable.update m model.tableModel
            in
            ( { model | tableModel = newTableModel }, Cmd.map TableMsg cmd )

        -- RecvUaDeets val ->
        --     let
        --         _ =
        --             Debug.log "Received data from elm" <| Decode.decodeString dataDecoder val
        --     in
        --     ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    -- Sub.none
    MyTable.recvUaDeets MyTable.RecvUaDeets |> Sub.map TableMsg



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
    MyTable.view model.tableModel |> Html.map TableMsg
