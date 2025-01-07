port module Components.UaTable exposing (..)

import Components.Table
import Components.Table.Column as Column
import Components.Table.Config as Config
import Css
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, src)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, Value)
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw
import Task



-- INIT


init : Model
init =
    Components.Table.init config


config : Components.Table.Config UserAgent () Msg
config =
    Components.Table.static
        OnTable
        .ua
        [ Column.string .ua "User Agent" "" |> Column.withCss [ Css.property "word-break" "break-word" ] |> Column.withLineClamp (Just 3)
        , Column.string .browserName "Browser" ""
        , Column.string .deviceModel "Model" ""
        , Column.string .deviceVendor "Vendor" ""
        , Column.string .osName "OS" ""
        ]
        |> Config.withStickyHeader



-- PORTS


port fetchUserAgent : String -> Cmd msg


port fetchUserAgentBatch : List String -> Cmd msg


port recvUserAgent : (String -> msg) -> Sub msg


port recvUserAgentBatch : (String -> msg) -> Sub msg


type alias Model =
    Components.Table.Model UserAgent


type alias UserAgent =
    { ua : String
    , browserName : String
    , deviceModel : String
    , deviceVendor : String
    , osName : String
    }


uaDecoder : Decoder UserAgent
uaDecoder =
    Decode.map5 UserAgent
        (Decode.field "ua" Decode.string)
        (Decode.field "browser" Decode.string)
        (Decode.field "model" Decode.string)
        (Decode.field "vendor" Decode.string)
        (Decode.field "os" Decode.string)


type Msg
    = OnTable Model
    | OnData (Result Error String)
    | RecvUserAgent String
    | RecvUserAgentBatch String


fetchData : Cmd Msg
fetchData =
    -- run <| OnData (Ok { page = page, perPage = 1, totalPages = 1, data = [ { id = 1, firstname = "John", lastname = "Doe", email = "a@example.com", avatar = "none" } ] })
    Http.get
        { url = "data/data.txt"
        , expect = Http.expectString OnData
        }



-- TODO: modify table by updating css directly. Refer to designs elsewhere.
-- Reuse UaTable for Generate UA App


run : msg -> Cmd msg
run m =
    Task.perform (always m) (Task.succeed ())



-- Http.get
--     { url = Builder.relative [ "api", "users" ] [ Builder.int "page" page ]
--     , expect = Http.expectJson OnData decoder
--     }
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
    div [] [ Components.Table.view config model ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnTable m ->
            let
                _ =
                    Debug.log "OnTable" ""
            in
            ( m, Cmd.none )

        -- let
        --     p =
        --         Table.pagination m
        -- in
        -- ( m, get 1 )
        -- OnTableInternal m ->
        --     let _ = Debug.log "OnTableInternal" "" in
        --     ( m, Cmd.none )
        OnData (Ok res) ->
            let
                lines =
                    String.split "\n" res
            in
            ( model, fetchUserAgentBatch lines )

        OnData (Err e) ->
            let
                _ =
                    Debug.log "fetch error" e
            in
            ( model, Cmd.none )

        RecvUserAgent val ->
            let
                decoded =
                    Decode.decodeString uaDecoder val
            in
            ( appendRowsToModel (Result.map List.singleton decoded) model, Cmd.none )

        RecvUserAgentBatch val ->
            let
                decoded =
                    Decode.decodeString (Decode.list uaDecoder) val
            in
            ( appendRowsToModel decoded model, Cmd.none )


appendRowsToModel : Result Decode.Error (List UserAgent) -> Model -> Model
appendRowsToModel x model =
    case x of
        Ok res ->
            model |> Components.Table.loadedDynamic ((model |> Components.Table.get) ++ res) (List.length res)

        Err err ->
            let
                _ =
                    Debug.log "failed to get rows" err
            in
            model


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Components.Table.subscriptions config model
        , recvUserAgent RecvUserAgent
        , recvUserAgentBatch RecvUserAgentBatch
        ]
