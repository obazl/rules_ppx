load("@rules_ocaml//build:rules.bzl", "ocaml_module")
load("@rules_ppx//build/_rules:ppx_transform.bzl", "ppx_transform")

def _ppx_module_impl(name, visibility,
                     ppx,
                     struct = None,
                     sig = None,
                     print = None,
                     **kwargs):

    if struct and sig:
        ocaml_module(
            name = name,
            struct = name + "_ppx",
            sig    = name + "_ippx",
            visibility = visibility,
            **kwargs,
        )
    elif struct:
        ocaml_module(
            name = name,
            struct = name + "_ppx",
            visibility = visibility,
            **kwargs,
        )
    elif sig:
        ocaml_module(
            name = name,
            sig    = name + "_ippx",
            visibility = visibility,
            **kwargs,
        )
    else:
        fail("At least one of struct and sig args required")

    if struct:
        ppx_transform(
            name = name + "_ppx",
            src  = struct,
            ppx  = ppx,
            print = print
        )
    if sig:
        ppx_transform(
            name = name + "_ippx",
            src  = sig,
            ppx  = ppx
        )

###################
ppx_module = macro(
    inherit_attrs = ocaml_module,
    attrs = {
        "ppx": attr.label(
            mandatory = True,
            configurable = True,
        ),
        "struct": attr.label(
            mandatory = True,
            configurable = False,
        ),
        "print": attr.label(
            mandatory = False,
            configurable = True,
        ),
    },
    implementation = _ppx_module_impl
)
