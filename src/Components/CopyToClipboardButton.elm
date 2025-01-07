port module Components.CopyToClipboardButton exposing (ButtonViewState(..), update, subscriptions, makeCopyAction, Msg)

import Css
import FontAwesome as Icon
import FontAwesome.Solid as Icon
import FontAwesome.Styles as Icon
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Process
import Svg.Attributes as Svg
import Svg.Styled
import Tailwind.Theme as Tw
import Tailwind.Utilities as Tw
import Task
import TwUtil


port copyToClipboard : String -> Cmd msg


port recvCopyStatus : (Bool -> msg) -> Sub msg


-- init : a -> WrappedModel a
-- init model =
--     { viewState = Idle, model = model }


update : Msg a -> ButtonViewState -> ( ButtonViewState, Cmd (Msg a) )
update m state =
    case m of
        -- CopyAction func model ->
        CopyAction str ->
            let
                -- str =
                --     func model

                _ =
                    Debug.log "got string" str
            in
            ( state, copyToClipboard str )

        CopyStatus ok ->
            if ok then
                ( Copied, Task.attempt (\_ -> CopiedTimeout) <| Process.sleep 5000 )

            else
                ( state, Cmd.none )

        CopiedTimeout ->
            ( Idle, Cmd.none )


type Msg a
    = CopyAction String
    | CopyStatus Bool
    | CopiedTimeout


type ButtonViewState
    = Idle
    | Copied


-- type alias ViewConfig a =
--     { onCopy : a -> String
--     , layout : Msg a -> ButtonViewState -> Html (Msg a)
--     }


-- type alias WrappedModel a =
--     { viewState : ButtonViewState
--     , model : a
--     }


subscriptions : () -> Sub (Msg a)
subscriptions _ =
    recvCopyStatus CopyStatus


makeCopyAction : (String) -> Msg a
makeCopyAction = CopyAction 

-- view : ViewConfig a -> ButtonViewState -> Html (Msg a)
-- view { onCopy, layout } state =
--     layout (CopyAction onCopy) state
    -- let
    --     icon =
    --         if state.viewState == Idle then
    --             Icon.clipboard

    --         else
    --             Icon.clipboardCheck
    -- in
    -- button
    --     [ onClick (CopyAction onCopy)
    --     , css <|
    --         [ Tw.flex
    --         , Tw.justify_center
    --         , Tw.items_center
    --         , Tw.w_10
    --         , Tw.h_10
    --         , Tw.bg_color Tw.white
    --         , Css.hover
    --             [ Tw.bg_color Tw.gray_100
    --             ]
    --         ]
    --             ++ TwUtil.border
    --     ]
    --     [ icon
    --         |> Icon.styled [ Svg.width "20", Svg.height "20" ]
    --         |> Icon.view
    --         |> Svg.Styled.fromUnstyled
    --     ]
