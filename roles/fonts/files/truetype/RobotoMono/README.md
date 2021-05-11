This is a slightly patched version of the font, where the vendor ID has been
made consistent across all font variants. In the original font, italic variants
use `pyrs` as vendor ID whereas the other variants use `GOOG`. This appears to
have caused Emacs to not recognize the italic variants of the font.

See 
- https://github.com/googlefonts/RobotoMono/issues/23
- https://github.com/googlefonts/RobotoMono/pull/30
