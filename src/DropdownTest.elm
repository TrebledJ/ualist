module DropdownTest exposing (..)

import UaDropdown exposing (..)
import Browser

main = Browser.sandbox { init = init ["A", "B", "C"], update = update, view = view }