port module Components.UaTable exposing (..)

import Components.Clipboard as Clipboard
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
import Svg.Attributes as SvgA
import Svg.Styled
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw
import Task
import TwUtil
import Components.Clipboard as Clipboard



-- INIT


init : Model
init =
    { table = Components.Table.init config
    , toolbarState =
        { copyAllState = Clipboard.Idle
        }
    }


type alias ToolbarState =
    { copyAllState : Clipboard.ViewState
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
        |> Config.withRowClickHandler OnRowClick
        |> Config.withToolbar
            [ copyAllButton
            ]


-- PORTS


port fetchUserAgent : String -> Cmd msg


port fetchUserAgentBatch : List String -> Cmd msg


port recvUserAgentBatch : (String -> msg) -> Sub msg


type alias TableModel =
    Components.Table.Model UserAgent


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
    | OnRowClick UserAgent
    | RecvUserAgentBatch String
    | ClipboardMsg (Clipboard.Msg TableModel)
    | ClipboardRowMsg (Clipboard.Msg UserAgent)


fetchData : Cmd Msg
fetchData =
    Http.get
        { url = "data/data.txt"
        , expect = Http.expectString OnData
        }


-- run : msg -> Cmd msg
-- run m =
--     Task.perform (always m) (Task.succeed ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnTable m ->
            -- Set model to whatever is passed in parameter.
            ( { model | table = m }, Cmd.none )

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

        OnRowClick rec ->
            let
                _ = Debug.log "onrowclick" rec.ua
                (_, cmd) = Clipboard.update "recvCopyRowStatus" (Clipboard.CopyAction .ua) rec Clipboard.Idle
            in
            ( model, Cmd.map ClipboardRowMsg cmd )

        RecvUserAgentBatch val ->
            let
                decoded =
                    Decode.decodeString (Decode.list uaDecoder) val
            in
            ( appendRowsToModel decoded model, Cmd.none )

        ClipboardMsg m ->
            let
                _ = Debug.log "called" "ClipboardMsg"
                ( state, cmd ) =
                    Clipboard.update "recvCopyAllStatus" m model.table model.toolbarState.copyAllState

                toolbarState =
                    model.toolbarState

                newToolbarState =
                    { toolbarState | copyAllState = state }
            in
            ( { model | toolbarState = newToolbarState }, Cmd.map ClipboardMsg cmd )
    
        ClipboardRowMsg _ ->
            let _ = Debug.log "called" "ClipboardRowMsg" in
            ( model, Cmd.none )


appendRowsToModel : Result error (List UserAgent) -> Model -> Model
appendRowsToModel x model =
    case x of
        Ok newRows ->
            let
                rows =
                    model.table |> Components.Table.get

                table =
                    model.table |> Components.Table.loadedStatic (rows ++ newRows)
            in
            { model | table = table }

        Err err ->
            let
                _ =
                    Debug.log "failed to get rows" err
            in
            model


port recvCopyAllStatus : (Bool -> msg) -> Sub msg
port recvCopyRowStatus : (Bool -> msg) -> Sub msg

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Components.Table.subscriptions config model.table
        , recvUserAgentBatch RecvUserAgentBatch
        -- , Sub.map ClipboardMsg <| Clipboard.subscriptions ()
        , recvCopyAllStatus (ClipboardMsg << Clipboard.CopyStatus)
        , recvCopyRowStatus (ClipboardRowMsg << Clipboard.CopyStatus)
        ]

view : Model -> Html Msg
view model =
    Components.Table.view config model.toolbarState model.table


copyAllButton : ToolbarState -> Html Msg
copyAllButton { copyAllState } =
    let
        icon =
            if copyAllState == Clipboard.Idle then
                Icon.clipboardList

            else
                Icon.clipboardCheck
    in
    button
        [ onClick <|
            ClipboardMsg <|
                Clipboard.CopyAction <|
                    String.join "\n"
                        << List.map .ua
                        << Components.Table.getFiltered config
        , css <|
            [ Tw.flex
            , Tw.justify_center
            , Tw.items_center
            , Tw.w_10
            , Tw.h_10
            , Tw.cursor_pointer
            , Tw.bg_color Tw.white
            , Css.hover
                [ Tw.bg_color Tw.gray_100
                ]
            ]
                ++ TwUtil.border
        ]
        [ icon
            |> Icon.styled [ SvgA.width "20", SvgA.height "20" ]
            |> Icon.view
            |> Svg.Styled.fromUnstyled
        ]