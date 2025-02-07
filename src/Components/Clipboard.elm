port module Components.Clipboard exposing (ViewState(..), update, Msg(..))

import Process
import Task


port copyToClipboard : (String, String) -> Cmd msg


port recvCopyStatus : (Bool -> msg) -> Sub msg


update : String -> Msg a -> a -> ViewState -> ( ViewState, Cmd (Msg a) )
update port_ m model vs =
    case m of
        CopyAction func ->
            let
                str =
                    func model
            in
            ( vs, copyToClipboard (port_, str) )

        CopyStatus ok ->
            if ok then
                ( Copied, Task.attempt (\_ -> CopiedTimeout) <| Process.sleep 5000 )

            else
                ( vs, Cmd.none )

        CopiedTimeout ->
            ( Idle, Cmd.none )


type Msg a
    = CopyAction (a -> String)
    | CopyStatus Bool
    | CopiedTimeout


type ViewState
    = Idle
    | Copied


-- subscriptions : () -> Sub (Msg a)
-- subscriptions _ =
--     recvCopyStatus CopyStatus
