module View exposing (main)

import Browser
import Css
import Html
import Html.Styled as HtmlS exposing (..)
import Html.Styled.Attributes as Attr
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw
import Components.UaTable as UaTable
import Components.Internal.Data exposing (..)
import Components.Internal.State exposing (..)
import Json.Decode as Decode exposing (Decoder)



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


init : String -> ( Model, Cmd Msg )
init flags =
    let
        { width } =
                    case Decode.decodeString flagDecoder flags of
                        Ok res -> res
                        Err e -> { width = 1024 }
    in    
    ( { filterBrowser = "firefox"
      , filterOsDevice = "linux"
      , filterHost = ""
      , filterLimit = 10
      , tableModel = UaTable.init width
      }
    , Cmd.batch []
    )


type alias Flags = 
    { width : Int
    }


flagDecoder : Decoder Flags
flagDecoder = Decode.map Flags (Decode.field "width" Decode.int)



-- UPDATE


type Msg
    = TableMsg UaTable.Msg

getState : Components.Internal.Data.Model a -> Components.Internal.State.State
getState (Components.Internal.Data.Model mod) = mod.state

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TableMsg m ->
            let
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
            [ Attr.css [ Tw.w_screen, Tw.h_screen, Tw.mx_auto
                --, Css.property "font-family" "Monaco, \"Bitstream Vera Sans Mono\", \"Lucida Console\", Terminal, monospace"
                --, Css.property "font-size" "14px"
            ]
            ]
            [ viewMain model
            ]


viewMain : Model -> Html Msg
viewMain model =
    UaTable.view model.tableModel |> HtmlS.map TableMsg
