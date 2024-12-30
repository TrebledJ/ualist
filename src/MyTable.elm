port module MyTable exposing (..)

-- import Json.Decode as Decode exposing (Decoder)
-- import Json.Decode.Pipeline exposing (required)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class, src)
import Http exposing (Error)
import Table
import Table.Column as Column
import Table.Config as Config
import Task
import Json.Decode as Decode exposing (Decoder, Value)



-- import Url.Builder as Builder

-- PORTS


port fetchUaDeets : List String -> Cmd msg


port recvUaDeets : (String -> msg) -> Sub msg


type alias Model =
    Table.Model UaParsedData


type alias UaParsedData =
    { ua : String
    , browserName : String
    , deviceModel : String
    , deviceVendor : String
    , osName : String
    }

dataDecoder : Decoder UaParsedData
dataDecoder =
    Decode.map5 UaParsedData 
        (Decode.field "ua" Decode.string)
        (Decode.field "browserName" Decode.string)
        -- (Decode.field "browserVer" Decode.string)
        (Decode.field "deviceModel" Decode.string)
        (Decode.field "deviceVendor" Decode.string)
        (Decode.field "osName" Decode.string)

-- type alias Payload =
--     { page : Int
--     , perPage : Int
--     , totalPages : Int
--     , data : List User
--     }


type Msg
    = OnTableInternal Model
    | OnTableRefresh Model
    | OnData (Result Error String)
    | RecvUaDeets String


get : Int -> Cmd Msg
get page =
    let
        _ = Debug.log "fetching data.txt" ""
    in
    
    -- run <| OnData (Ok { page = page, perPage = 1, totalPages = 1, data = [ { id = 1, firstname = "John", lastname = "Doe", email = "a@example.com", avatar = "none" } ] })
    Http.get
        { url = "../data/data.txt"
        , expect = Http.expectString OnData
        }


run : msg -> Cmd msg
run m =
    Task.perform (always m) (Task.succeed ())



-- Http.get
--     { url = Builder.relative [ "api", "users" ] [ Builder.int "page" page ]
--     , expect = Http.expectJson OnData decoder
--     }


config : Table.Config UaParsedData () Msg
config =
    Table.dynamic
        OnTableRefresh
        OnTableInternal
        .ua
        -- [Column.string (\x -> x) "Agent" ""]
        -- (String.fromInt << .id)
        [ Column.string .ua "User Agent" "" -- |> Column.withWidth "10px"
        , Column.string .browserName "Browser" ""
        , Column.string .deviceModel "Model" ""
        , Column.string .deviceVendor "Vendor" ""
        , Column.string .osName "OS" ""
        ]
        -- |> Config.withSelectionExclusive
        -- |> Config.withPagination [ 5, 10, 20, 50 ] 10


-- main : Program () Model Msg
-- main =
--     Browser.element
--         { init = init
--         , view = view
--         , update = update
--         , subscriptions = Table.subscriptions config
--         }


-- init : () -> ( Model, Cmd Msg )
-- init _ =
--     ( Table.init config, get 1 )


view : Model -> Html Msg
view model =
    div [ class "example-dynamic" ] [ Table.view config model ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnTableRefresh m ->
            let
                p =
                    Table.pagination m
            in
            ( m, get 1 )

        OnTableInternal m ->
            ( m, Cmd.none )

        OnData (Ok res) ->
            -- ( model |> Table.loadedDynamic res.data (res.totalPages * res.perPage), Cmd.none )
            let
                lines =
                    String.split "\n" res
                _ = Debug.log "fetch success" (String.join ", " <| List.take 5 lines)
            in
            -- ( model |> Table.loadedDynamic lines (lines |> List.length), Cmd.none )
            ( model, fetchUaDeets (List.take 10 lines) )
            -- ( model, fetchUaDeets ["curl/2.1.2"] )

        OnData (Err e) ->
            let
                _ =
                    Debug.log "fetch error" e
            in
            ( model, Cmd.none )

        RecvUaDeets val ->
            let
                decoded = Decode.decodeString (Decode.list dataDecoder) val
                _ =
                    Debug.log "Received data from elm" <| decoded
            in
            case decoded of
                Ok res -> ( model |> Table.loadedDynamic ((model |> Table.get) ++ res) (List.length res), Cmd.none )
                Err _ -> ( model, Cmd.none )
