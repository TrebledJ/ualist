port module Components.UaTable exposing (..)

import Components.Clipboard as Clipboard
import Components.Table.Column as Column
import Components.Table.Config as Config
import Components.Table.Table as Table
import Components.UaDropdown as UaDropdown
import Components.UaDropdownMultiSelect as UaDropdownMS
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
    "/assets/uagen-data.txt"



-- Pipe Pattern(?): Create a pipe, which is used to create a function- to create a message.
-- The resultant lambda (UaPipe model msg) can then be passed a "model transform" function
-- which will modify the model and overwrite the old model in the `update` function.


type alias UaPipe model msg =
    (model -> ( model, Cmd msg )) -> msg


mkPipe : (( model, Cmd msg ) -> msg) -> model -> UaPipe model msg
mkPipe fmsg model transform =
    fmsg <| transform model


init : Int -> Model
init width =
    let
        smallScreen =
            width < 640

        conf =
            config { defaultConfig | smallScreen = smallScreen }
    in
    { table = Table.init conf |> Table.withStatus "Load / Generate Data"
    , smallScreen = smallScreen
    , toolbarState =
        { copyAllState = Clipboard.Idle
        , generateConfigState =
            { ddPreset =
                UaDropdown.init [ "Spray & Pray", "Browsers", "Mobile", "Devices", "Tools", "Uncommon", "Custom" ]
                    |> UaDropdown.withHint "Select Preset"
            , ddBrowser =
                UaDropdown.init [ "Any", "Chrome", "Firefox" ]
                    -- TODO: add "Other" option.
                    |> UaDropdown.withDefault "Any"
            , ddOsDevice =
                UaDropdown.init [ "Any", "Linux", "Windows", "macOS", "iOS", "Android" ]
                    |> UaDropdown.withDefault "Any"
            , generateLastAction = False
            , showGenerateContainer = False
            }
        , settings =
            UaDropdownMS.initByPair
                [ ( "Tooltip on Hover", optTooltipOnHoverDefault )
                , ( "Case Sensitive Search", optSearchCaseSensitiveDefault )
                , ( "Include UA in Search", optSearchIncludeUaDefault )
                ]
        }
    }


optTooltipOnHoverIndex =
    0


optSearchCaseSensitiveIndex =
    1


optSearchIncludeUaIndex =
    2


optTooltipOnHoverDefault =
    True


optSearchCaseSensitiveDefault =
    False


optSearchIncludeUaDefault =
    False


type alias Config =
    Table.Config UserAgent () ToolbarState Msg


type alias GeneratorTotalEclipseState =
    { ddPreset : UaDropdown.State String
    , ddBrowser : UaDropdown.State String
    , ddOsDevice : UaDropdown.State String
    , generateLastAction : Bool -- Whether or not the previous action was a generate or modifying settings.
    , showGenerateContainer : Bool
    }


type alias Seddings =
    UaDropdownMS.State


nth : Int -> List a -> Maybe a
nth n xs =
    xs |> List.drop n |> List.head


optTooltipOnHover : Seddings -> Bool
optTooltipOnHover s =
    s.selecteds |> nth optTooltipOnHoverIndex |> Maybe.withDefault optTooltipOnHoverDefault


optSearchCaseSensitive : Seddings -> Bool
optSearchCaseSensitive s =
    s.selecteds |> nth optSearchCaseSensitiveIndex |> Maybe.withDefault optSearchCaseSensitiveDefault


optSearchIncludeUa : Seddings -> Bool
optSearchIncludeUa s =
    s.selecteds |> nth optSearchIncludeUaIndex |> Maybe.withDefault optSearchIncludeUaDefault


type alias ToolbarState =
    { copyAllState : Clipboard.ViewState
    , generateConfigState : GeneratorTotalEclipseState
    , settings : Seddings
    }


type alias ConfigBuilder =
    { smallScreen : Bool
    , searchIncludeUa : Bool
    , searchCaseSensitive : Bool
    }


defaultConfig : ConfigBuilder
defaultConfig =
    { smallScreen = False
    , searchIncludeUa = optSearchIncludeUaDefault
    , searchCaseSensitive = optSearchCaseSensitiveDefault
    }


config : ConfigBuilder -> Config
config { smallScreen, searchIncludeUa, searchCaseSensitive } =
    Table.static
        OnTable
        .ua
        [ Column.string .ua "User Agent" ""
            |> Column.withCss [ Css.property "word-break" "break-word" ]
            |> Column.withLineClamp (Just 3)
            |> applyIfT (not searchIncludeUa) (Column.withSearchable Nothing)
        , Column.string .browserName "Browser" "" |> applyIfT smallScreen (Column.withDefault False)
        , Column.string .deviceModel "Model" "" |> applyIfT smallScreen (Column.withDefault False)
        , Column.string .deviceVendor "Vendor" "" |> applyIfT smallScreen (Column.withDefault False)
        , Column.string .osName "OS" "" |> applyIfT smallScreen (Column.withDefault False)
        ]
        |> Config.withStickyHeader calculateHeaderOffset
        |> Config.withRowClickHandler OnRowClick
        |> Config.withRowHoverHandler OnRowHover
        |> Config.withSearchCaseSensitive searchCaseSensitive
        |> Config.withRowLimits [ "10", "20", "50", "100", "All" ] "All"
        |> Config.withToolbar
            [ settingsDropdown
            , fetchUaButton
            , toggleGenerateContainerButton
            , copyAllButton smallScreen
            ]
        |> Config.withToolbarContainer
            [ generateUaContainer
            ]



-- PORTS


port jsAnalyse : String -> Cmd msg


port jsAnalyseUserAgentBatch : List String -> Cmd msg


port jsGenerateUserAgents : { preset : String, browser : String, osDevice : String, count : Int } -> Cmd msg


port jsTooltipHover : { ua : String, x : Int, y : Int } -> Cmd msg


port jsTooltipToggle : Bool -> Cmd msg


port recvUserAgentBatch : (String -> msg) -> Sub msg


port recvCopyAllStatus : (Bool -> msg) -> Sub msg


port recvCopyRowStatus : (Bool -> msg) -> Sub msg


type alias TableModel =
    Table.Model UserAgent


type alias Model =
    { table : TableModel
    , smallScreen : Bool
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
    | OnRowHover UserAgent { x : Int, y : Int }
    | RecvUserAgentBatch String
    | OnFetchUserAgentsClicked
    | OnFetchUserAgentsCompleted (Result Error String)
    | UpdateToolbarState ( ToolbarState, Cmd Msg )
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

        OnRowHover rec { x, y } ->
            ( model
            , if toolbarState.settings |> optTooltipOnHover then
                jsTooltipHover { ua = rec.ua, x = x, y = y }

              else
                Cmd.none
            )

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

        UpdateToolbarState ( tbs, cmd ) ->
            ( { model | toolbarState = tbs }, cmd )

        OnGenerateClicked ->
            let
                st =
                    model.toolbarState.generateConfigState

                payload =
                    { preset =
                        st.ddPreset.selected |> Maybe.withDefault ""
                    , browser =
                        st.ddBrowser.selected |> Maybe.withDefault ""
                    , osDevice =
                        st.ddOsDevice.selected |> Maybe.withDefault ""
                    , count = model.table |> Table.getItemsPerPage |> if0then 10
                    }
            in
            ( model
                |> withToolbarState
                    { toolbarState | generateConfigState = { st | generateLastAction = True } }
            , jsGenerateUserAgents payload
            )

        ClipboardMsg m ->
            let
                ( state, cmd ) =
                    Clipboard.update "recvCopyAllStatus" m model.table model.toolbarState.copyAllState
            in
            ( model |> withToolbarState { toolbarState | copyAllState = state }
            , Cmd.map ClipboardMsg cmd
            )

        ClipboardRowMsg _ ->
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

        Err _ ->
            { model | table = Table.failed model.table "Failed somehow. Good luck figuring out why." }


setRowsToModel : Result error (List UserAgent) -> Model -> Model
setRowsToModel x model =
    case x of
        Ok rows ->
            { model | table = model.table |> Table.loadedStatic rows }

        Err _ ->
            { model | table = Table.failed model.table "Failed somehow. Good luck figuring out why." }


subscriptions : Model -> Sub Msg
subscriptions { smallScreen, table } =
    Sub.batch
        [ Table.subscriptions (config { defaultConfig | smallScreen = smallScreen }) table
        , recvUserAgentBatch RecvUserAgentBatch

        -- , Sub.map ClipboardMsg <| Clipboard.subscriptions ()
        , recvCopyAllStatus (ClipboardMsg << Clipboard.CopyStatus)
        , recvCopyRowStatus (ClipboardRowMsg << Clipboard.CopyStatus)
        ]


view : Model -> Html Msg
view model =
    let
        conf =
            config
                { smallScreen = model.smallScreen
                , searchCaseSensitive = model.toolbarState.settings |> optSearchCaseSensitive
                , searchIncludeUa = model.toolbarState.settings |> optSearchIncludeUa
                }
    in
    Table.view conf model.toolbarState model.table


settingsDropdown : ToolbarState -> Html Msg
settingsDropdown toolbarState =
    let
        pipe fUpdateState =
            mkPipe UpdateToolbarState
                toolbarState
                (\({ settings } as s) ->
                    let
                        newSettings =
                            fUpdateState settings

                        prevTt =
                            settings |> optTooltipOnHover

                        currTt =
                            newSettings |> optTooltipOnHover
                    in
                    ( { s | settings = newSettings }
                    , if prevTt /= currTt then
                        jsTooltipToggle currTt

                      else
                        Cmd.none
                    )
                )
    in
    UaDropdownMS.view
        { identifier = "dd-settings"
        , onSelect = pipe << UaDropdownMS.select
        , onToggle = pipe << UaDropdownMS.toggle
        , icon = TwUtil.icon Icon.gear
        , align = TwUtil.Left
        }
        toolbarState.settings


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


copyAllButton : Bool -> ToolbarState -> Html Msg
copyAllButton smallScreen { copyAllState, settings } =
    let
        conf =
            config
                { smallScreen = smallScreen
                , searchCaseSensitive = settings |> optSearchCaseSensitive
                , searchIncludeUa = settings |> optSearchIncludeUa
                }
    in
    button
        [ onClick <|
            ClipboardMsg <|
                Clipboard.CopyAction <|
                    String.join "\n"
                        << List.map .ua
                        << Table.getFiltered conf
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


toggleGenerateContainerButton : ToolbarState -> Html Msg
toggleGenerateContainerButton toolbarState =
    let
        pipe fUpdateState =
            mkPipe UpdateToolbarState
                toolbarState
                (\({ generateConfigState } as s) ->
                    ( { s | generateConfigState = fUpdateState generateConfigState }
                    , Cmd.none
                    )
                )
    in
    button
        [ onClick <| pipe <| \({ showGenerateContainer } as s) -> { s | showGenerateContainer = not showGenerateContainer }
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
        [ TwUtil.icon <| Icon.diceThree
        ]


calculateHeaderOffset : ToolbarState -> Css.Style
calculateHeaderOffset toolbarState =
    let
        isActive =
            toolbarState.generateConfigState.showGenerateContainer
    in
    Css.property "top"
        (if isActive then
            "9rem"

         else
            "4.5rem"
        )


generateUaContainer : List Css.Style -> ToolbarState -> Html Msg
generateUaContainer xs toolbarState =
    let
        pipe fUpdateState =
            mkPipe UpdateToolbarState
                toolbarState
                (\({ generateConfigState } as s) ->
                    ( { s | generateConfigState = fUpdateState generateConfigState }
                    , Cmd.none
                    )
                )

        resetLastAction generateConfigState =
            { generateConfigState | generateLastAction = False }
    in
    if not toolbarState.generateConfigState.showGenerateContainer then
        div [] []

    else
        div
            [ css <|
                [ Tw.flex
                , Tw.flex_wrap
                , Tw.gap_2
                , Tw.justify_between
                , Tw.items_center
                , Tw.border_solid
                , Tw.border_0
                , Tw.border_t
                , Tw.border_t_color Tw.gray_300
                ]
                    ++ xs
            ]
            [ div
                [ css <|
                    [ Tw.flex
                    , Tw.flex_wrap
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
                    |> appendIfT (toolbarState.generateConfigState.ddPreset.selected == Just "Custom")
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
                [--css [ Tw.flex, Tw.gap_2, Tw.items_center ]
                ]
                [ button
                    [ onClick <| OnGenerateClicked
                    , css <|
                        [ Tw.flex
                        , Tw.justify_center
                        , Tw.items_center
                        , Css.property "width" "fit-content"
                        , Tw.p_2
                        , Tw.h_10
                        , Tw.cursor_pointer
                        , Tw.bg_color Tw.white
                        , Css.hover
                            [ Tw.bg_color Tw.gray_100
                            ]
                        ]
                            ++ TwUtil.border
                    , disabled <| toolbarState.generateConfigState.ddPreset.selected == Nothing
                    ]
                    [ TwUtil.icon <| iff toolbarState.generateConfigState.generateLastAction Icon.arrowsRotate Icon.arrowRight
                    , span [ css [ Tw.ml_2, Tw.text_lg ] ] [ text "Generate Agents" ]
                    ]
                ]
            ]
