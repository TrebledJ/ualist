port module Components.CopyToClipboardButton exposing (..)

-- import FontAwesome.Attributes as Icon
-- import FontAwesome.Brands as Icon
-- import FontAwesome.Layering as Icon
-- import Svg.Styled.Attributes as SvgA

import Components.Dropdown as Dropdown exposing (dropdown)
import Css
import FontAwesome as Icon exposing (Icon)
import FontAwesome.Solid as Icon
import FontAwesome.Styles as Icon
import FontAwesome.Svg as SvgIcon
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


-- copyToClipboardWithTimeout : Float -> String -> Cmd msg
-- copyToClipboardWithTimeout timeout msg = Process.sleep timeout |> Task.attempt (
--         \res -> case res of
--             Error _ -> Cmd.none
--             Ok _ -> copyToClipboard msg
--     )
-- faClipboardIcon =
--     Svg.Styled.svg [ SvgA.viewBox "0 0 384 512", SvgA.style "width: 20px; height: 20px;" ]
--         [ Svg.Styled.fromUnstyled <| SvgIcon.view Icon.clipboard ]
-- faClipboardCheckedIcon =
--     Svg.Styled.svg [ SvgA.viewBox "0 0 384 512", SvgA.style "width: 20px; height: 20px;" ]
--         [ Svg.Styled.fromUnstyled <| SvgIcon.view Icon.clipboardCheck ]
-- init : ()
-- init = ()

init : a -> WrappedModel a
init model = { viewState = Idle, model = model }


update : Msg a -> WrappedModel a -> ( WrappedModel a, Cmd (Msg a) )
update m state =
    case m of
        CopyAction func ->
            let
                str =
                    func state.model

                _ =
                    Debug.log "got string" str
            in
            ( state, copyToClipboard str )
        CopyStatus ok ->
            if ok then
                ( { state | viewState = Copied }, Task.attempt (\_ -> CopiedTimeout) <| Process.sleep 5000 )
            else
                (state, Cmd.none)
        CopiedTimeout ->
            ( { state | viewState = Idle }, Cmd.none )


type Msg a
    = CopyAction (a -> String)
    | CopyStatus Bool
    | CopiedTimeout

type ButtonViewState = Idle | Copied

type alias ViewConfig a =
    { onCopy : a -> String
    }

type alias WrappedModel a =
    {
        viewState : ButtonViewState,
        model : a
    }


subscriptions : WrappedModel a -> Sub (Msg a)
subscriptions _ = recvCopyStatus CopyStatus


view : ViewConfig a -> WrappedModel a -> Html (Msg a)
view { onCopy } state =
    -- div [
    --                 -- custom "click"
    --                 --     (Decode.succeed
    --                 --         { message = onToggle (not isToggled)
    --                 --         , preventDefault = True
    --                 --         , stopPropagation = True
    --                 --         }
    --                 --     )
    --     -- OnClick ->
    --     --         OnHover ->
    --     --             [ onMouseEnter (onToggle True)
    --     --             , onFocus (onToggle True)
    --     --             ]
    --     --         OnFocus ->
    --     --             [ onFocus (onToggle True) ]
    -- ] [
    -- ]
    let 
        icon = if state.viewState == Idle then Icon.clipboard else Icon.clipboardCheck
    in
    button
        [ onClick (CopyAction onCopy)
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
