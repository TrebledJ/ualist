port module Components.UaTable exposing (..)

import Components.CopyToClipboardButton as CopyToClipboardButton
import Components.Table
import Components.Table.Column as Column
import Components.Table.Config as Config
import Css
import FontAwesome as Icon
import FontAwesome.Solid as Icon
import FontAwesome.Styles as Icon
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, Value)
import Svg.Attributes as Svg
import Svg.Styled
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw
import TwUtil
import Task



-- INIT


init : Model
init =
    { table = Components.Table.init config
    , toolbarState = {
        copyToClipboardViewState = CopyToClipboardButton.Idle }
    }

type alias ToolbarState = 
    {
        copyToClipboardViewState : CopyToClipboardButton.ButtonViewState
    }

config : Components.Table.Config UserAgent () ToolbarState Msg
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
        |> Config.withToolbar
            [ copyAllButton
            ]



-- PORTS


port fetchUserAgent : String -> Cmd msg


port fetchUserAgentBatch : List String -> Cmd msg


port recvUserAgent : (String -> msg) -> Sub msg


port recvUserAgentBatch : (String -> msg) -> Sub msg


type alias TableModel = Components.Table.Model UserAgent

type alias Model =
    { table : TableModel
    , toolbarState : ToolbarState
    }


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
    = OnTable TableModel
    | OnData (Result Error String)
    | RecvUserAgent String
    | RecvUserAgentBatch String
    | CopyToClipboardMsg (CopyToClipboardButton.Msg TableModel)


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
    div [] [ Components.Table.view config model.toolbarState model.table ]

buildString : TableModel -> String
buildString table = Components.Table.getFiltered config table |> List.map .ua |> String.join "\n"

copyAllButton : ToolbarState -> Html Msg
copyAllButton { copyToClipboardViewState } =
    let
        icon =
            if copyToClipboardViewState == CopyToClipboardButton.Idle then
                Icon.clipboard

            else
                Icon.clipboardCheck

    in
    button
        [ -- onClick (CopyAction onCopy)
          Html.Styled.Attributes.map CopyToClipboardMsg <| onClick <| CopyToClipboardButton.makeCopyAction buildString
        , css <|
            [ Tw.flex
            , Tw.justify_center
            , Tw.items_center
            , Tw.w_10
            , Tw.h_10
            , Tw.bg_color Tw.white
            , Css.hover
                [ Tw.bg_color Tw.gray_100
                ]
            ]
                ++ TwUtil.border
        ]
        [ icon
            |> Icon.styled [ Svg.width "20", Svg.height "20" ]
            |> Icon.view
            |> Svg.Styled.fromUnstyled
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnTable m ->
            -- Set model to whatever is passed in parameter.
            ( {model | table = m} , Cmd.none )

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

        CopyToClipboardMsg m ->
            let ( state, cmd ) = CopyToClipboardButton.update m model.table model.toolbarState.copyToClipboardViewState
                toolbarState = model.toolbarState
                newToolbarState = { toolbarState | copyToClipboardViewState = state }
            in
            ( { model | toolbarState = newToolbarState }, Cmd.map CopyToClipboardMsg cmd )


appendRowsToModel : Result Decode.Error (List UserAgent) -> Model -> Model
appendRowsToModel x model =
    case x of
        Ok res ->
            let table = model.table |> Components.Table.loadedDynamic ((model.table |> Components.Table.get) ++ res) (List.length res)
            in { model | table = table }

        Err err ->
            let
                _ =
                    Debug.log "failed to get rows" err
            in
            model


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Components.Table.subscriptions config model.table
        , recvUserAgent RecvUserAgent
        , recvUserAgentBatch RecvUserAgentBatch
        , Sub.map CopyToClipboardMsg <| CopyToClipboardButton.subscriptions ()
        ]
