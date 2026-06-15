# eachSystem, the default-systems list, and eachDefaultSystem — vendored from
# numtide/flake-utils (lib.nix) so this repository needs no flake-utils
# dependency. eachSystem turns `system: { out = v; }` into `{ out.<system> = v; }`
# across `systems`.
#
# Source:
# https://github.com/numtide/flake-utils/blob/11707dc2f618dd54ca8739b309ec4fc024de578b/lib.nix
#
# MIT License
#
# Copyright (c) 2020 zimbatm
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
let
  /**
    Turn a `system: { <output> = v; }` function into `{ <output>.<system> = v; }`
    across `systems` — e.g. build per-system `packages`/`checks` outputs.
  */
  eachSystem = systems: f:
    builtins.foldl'
      (attrs: system:
        let ret = f system;
        in builtins.foldl'
          (attrs: key: attrs // {
            ${key} = (attrs.${key} or { }) // { ${system} = ret.${key}; };
          })
          attrs
          (builtins.attrNames ret))
      { }
      systems;
  defaultSystems = [
    "aarch64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
    "x86_64-linux"
  ];
in
{
  inherit eachSystem defaultSystems;
  /** `eachSystem` applied over the four default systems (`defaultSystems`). */
  eachDefaultSystem = eachSystem defaultSystems;
}
