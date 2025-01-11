port module Components.UaTable exposing (..)

import Components.Clipboard as Clipboard
import Components.Table as Table
import Components.Table.Column as Column
import Components.Table.Config as Config
import Components.UaDropdown as UaDropdown
import Css
import FontAwesome.Solid as Icon
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, Value)
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw
import Task
import TwUtil
import Util exposing (..)



-- INIT


uaDataFile : String
uaDataFile =
    "data/data-big.txt"


type alias UaPipe model msg =
    (model -> model) -> msg


mkPipe : (model -> msg) -> model -> UaPipe model msg
mkPipe fmsg model transform =
    fmsg <| transform model


init : Model
init =
    { table = Table.init config |> Table.withStatus "Load / Generate Data"
    , toolbarState =
        { copyAllState = Clipboard.Idle
        , generateConfigState =
            { ddPreset = UaDropdown.init [ "Spray & Pray", "Browsers", "Mobile", "Devices", "Tools", "Payloads", "Uncommon", "Custom" ] "Spray & Pray"
            , ddBrowser = UaDropdown.init [ "Any", "Chrome", "Firefox", "Other" ] "Any"
            , ddOsDevice = UaDropdown.init [ "Any", "Linux", "Windows", "macOS", "iOS", "Android", "Other" ] "Any"
            , generateLastAction = False
            }
        }
    }


type alias GeneratorTotalEclipseState =
    { ddPreset : UaDropdown.State String
    , ddBrowser : UaDropdown.State String
    , ddOsDevice : UaDropdown.State String
    , generateLastAction : Bool -- Whether or not the previous action was a generate or modifying settings.
    }


type alias ToolbarState =
    { copyAllState : Clipboard.ViewState
    , generateConfigState : GeneratorTotalEclipseState
    }


config : Table.Config UserAgent () ToolbarState Msg
config =
    Table.static
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
        |> Config.withRowLimits [ "10", "20", "50", "All" ] "All"
        |> Config.withToolbar
            [ fetchUaButton
            , copyAllButton
            ]
        |> Config.withToolbarContainer
            [ generateUaContainer
            ]



-- PORTS


port jsAnalyse : String -> Cmd msg


port jsAnalyseUserAgentBatch : List String -> Cmd msg


port jsGenerateUserAgents : { preset : String, browser : String, osDevice : String, count : Int } -> Cmd msg


port recvUserAgentBatch : (String -> msg) -> Sub msg


port recvCopyAllStatus : (Bool -> msg) -> Sub msg


port recvCopyRowStatus : (Bool -> msg) -> Sub msg


type alias TableModel =
    Table.Model UserAgent


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
    | OnRowClick UserAgent
    | RecvUserAgentBatch String
    | OnFetchUserAgentsClicked
    | OnFetchUserAgentsCompleted (Result Error String)
    | UpdateToolbarState ToolbarState
    | OnGenerateClicked
    | ClipboardMsg (Clipboard.Msg TableModel)
    | ClipboardRowMsg (Clipboard.Msg UserAgent)



-- run : msg -> Cmd msg
-- run m =
--     Task.perform (always m) (Task.succeed ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ toolbarState } as model) =
    case msg of
        OnTable m ->
            -- Set model to whatever is passed in parameter.
            ( { model | table = m }, Cmd.none )

        OnRowClick rec ->
            let
                ( _, cmd ) =
                    Clipboard.update "recvCopyRowStatus" (Clipboard.CopyAction .ua) rec Clipboard.Idle
            in
            ( model, Cmd.map ClipboardRowMsg cmd )

        RecvUserAgentBatch val ->
            let
                decoded =
                    Decode.decodeString (Decode.list uaDecoder) val
            in
            ( setRowsToModel decoded model, Cmd.none )

        OnFetchUserAgentsClicked ->
            ( model
            , Http.get
                { url = uaDataFile
                , expect = Http.expectString OnFetchUserAgentsCompleted
                }
            )

        OnFetchUserAgentsCompleted (Ok res) ->
            let
                lines =
                    String.split "\n" res
            in
            ( model, jsAnalyseUserAgentBatch lines )

        OnFetchUserAgentsCompleted (Err e) ->
            ( { model | table = Table.failed model.table <| errorToString e }, Cmd.none )

        UpdateToolbarState tbs ->
            ( { model | toolbarState = tbs }, Cmd.none )

        OnGenerateClicked ->
            let
                st =
                    model.toolbarState.generateConfigState

                count =
                    model.table |> Table.getItemsPerPage

                payload =
                    { preset =
                        st.ddPreset.selected
                    , browser =
                        st.ddBrowser.selected
                    , osDevice =
                        st.ddOsDevice.selected
                    , count = count |> if0then (model.table |> Table.get |> List.length) |> if0then 10
                    }
            in
            ( model
                |> withToolbarState
                    { toolbarState | generateConfigState = { st | generateLastAction = True } }
            , jsGenerateUserAgents payload
            )

        ClipboardMsg m ->
            let
                _ =
                    Debug.log "called" "ClipboardMsg"

                ( state, cmd ) =
                    Clipboard.update "recvCopyAllStatus" m model.table model.toolbarState.copyAllState
            in
            ( model |> withToolbarState { toolbarState | copyAllState = state }
            , Cmd.map ClipboardMsg cmd
            )

        ClipboardRowMsg _ ->
            let
                _ =
                    Debug.log "called" "ClipboardRowMsg"
            in
            ( model, Cmd.none )


withToolbarState : ToolbarState -> Model -> Model
withToolbarState st m =
    { m | toolbarState = st }


appendRowsToModel : Result error (List UserAgent) -> Model -> Model
appendRowsToModel x model =
    case x of
        Ok newRows ->
            let
                rows =
                    model.table |> Table.get

                table =
                    model.table |> Table.loadedStatic (rows ++ newRows)
            in
            { model | table = table }

        Err err ->
            let
                _ =
                    Debug.log "failed to get rows" err
            in
            model


setRowsToModel : Result error (List UserAgent) -> Model -> Model
setRowsToModel x model =
    case x of
        Ok rows ->
            { model | table = model.table |> Table.loadedStatic rows }

        Err err ->
            let
                _ =
                    Debug.log "failed to get rows" err
            in
            model


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Table.subscriptions config model.table
        , recvUserAgentBatch RecvUserAgentBatch

        -- , Sub.map ClipboardMsg <| Clipboard.subscriptions ()
        , recvCopyAllStatus (ClipboardMsg << Clipboard.CopyStatus)
        , recvCopyRowStatus (ClipboardRowMsg << Clipboard.CopyStatus)
        ]


view : Model -> Html Msg
view model =
    Table.view config model.toolbarState model.table


fetchUaButton : ToolbarState -> Html Msg
fetchUaButton _ =
    button
        [ onClick <| OnFetchUserAgentsClicked
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
        [ TwUtil.icon <| Icon.cloudArrowDown
        ]


copyAllButton : ToolbarState -> Html Msg
copyAllButton { copyAllState } =
    button
        [ onClick <|
            ClipboardMsg <|
                Clipboard.CopyAction <|
                    String.join "\n"
                        << List.map .ua
                        << Table.getFiltered config
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
        [ TwUtil.icon <| iff (copyAllState == Clipboard.Idle) Icon.clipboardList Icon.clipboardCheck
        ]


generateUaContainer : List Css.Style -> ToolbarState -> Html Msg
generateUaContainer xs toolbarState =
    let
        pipe fUpdateState =
            mkPipe UpdateToolbarState toolbarState (\({ generateConfigState } as s) -> { s | generateConfigState = fUpdateState generateConfigState })

        resetLastAction generateConfigState =
            { generateConfigState | generateLastAction = False }
    in
    div
        [ css <|
            [ Tw.flex
            , Tw.justify_between
            , Tw.items_center
            , Tw.border_solid
            , Tw.border_0
            , Tw.border_t_2
            , Tw.border_t_color Tw.gray_300
            ]
                ++ xs
        ]
        [ div
            [ css <|
                [ Tw.flex
                , Tw.justify_start
                , Tw.gap_2
                ]
            ]
            ([ UaDropdown.view
                { identifier = "dd-preset"
                , render = text
                , onSelect =
                    \item ->
                        pipe <|
                            resetLastAction
                                << (\({ ddPreset } as gstate) ->
                                        { gstate
                                            | ddPreset = UaDropdown.select item ddPreset
                                        }
                                   )
                , onToggle =
                    \on ->
                        pipe <|
                            \({ ddPreset } as gstate) ->
                                { gstate
                                    | ddPreset = UaDropdown.toggle on ddPreset
                                }
                , showSelectedInTopLevel = True
                , icon = TwUtil.icon Icon.rocket
                , align = TwUtil.Left
                }
                toolbarState.generateConfigState.ddPreset
             ]
                |> appendIfT (toolbarState.generateConfigState.ddPreset.selected == "Custom")
                    [ UaDropdown.view
                        { identifier = "dd-browser"
                        , render = text
                        , onSelect =
                            \item ->
                                pipe <|
                                    resetLastAction
                                        << (\({ ddBrowser } as gstate) ->
                                                { gstate
                                                    | ddBrowser = UaDropdown.select item ddBrowser
                                                }
                                           )
                        , onToggle =
                            \on ->
                                pipe <|
                                    \({ ddBrowser } as gstate) ->
                                        { gstate
                                            | ddBrowser = UaDropdown.toggle on ddBrowser
                                        }
                        , showSelectedInTopLevel = True
                        , icon = TwUtil.icon Icon.globe
                        , align = TwUtil.Left
                        }
                        toolbarState.generateConfigState.ddBrowser
                    , UaDropdown.view
                        { identifier = "dd-osdevice"
                        , render = text
                        , onSelect =
                            \item ->
                                pipe <|
                                    resetLastAction
                                        << (\({ ddOsDevice } as gstate) ->
                                                { gstate
                                                    | ddOsDevice = UaDropdown.select item ddOsDevice
                                                }
                                           )
                        , onToggle =
                            \on ->
                                pipe <|
                                    \({ ddOsDevice } as gstate) ->
                                        { gstate
                                            | ddOsDevice = UaDropdown.toggle on ddOsDevice
                                        }
                        , showSelectedInTopLevel = True
                        , icon = TwUtil.icon Icon.mobile
                        , align = TwUtil.Left
                        }
                        toolbarState.generateConfigState.ddOsDevice
                    ]
            )
        , div
            [ css [ Tw.flex, Tw.gap_2, Tw.items_center ]
            ]
            [ button
                [ onClick <| OnGenerateClicked
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
                [ TwUtil.icon <| iff toolbarState.generateConfigState.generateLastAction Icon.arrowsRotate Icon.arrowRight
                ]
            , span [] [ text "Generate Agents" ]
            , TwUtil.icon Icon.hammer
            ]
        ]
