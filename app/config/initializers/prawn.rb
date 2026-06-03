# Our invoice PDFs use plain ASCII with Prawn's built-in fonts; silence the
# internationalization warning we don't need.
require "prawn"
Prawn::Fonts::AFM.hide_m17n_warning = true
