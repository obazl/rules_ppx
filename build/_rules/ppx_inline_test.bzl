load("@rules_ocaml//build:rules.bzl",
     "ocaml_module", "ocaml_signature", "ocaml_test")
load("@rules_ppx//build/_rules:ppx_executable.bzl", "ppx_executable")
load("@rules_ppx//build/_rules:ppx_transform.bzl", "ppx_transform")

load("@rules_ocaml//ocaml/_rules:impl_binary.bzl", "impl_binary")
load("@rules_ocaml//ocaml/_rules:options.bzl",
     "options", "options_binary")
load("@rules_ocaml//ocaml/_debug:colors.bzl", "CCYEL", "CCRESET")
load("@bazel_skylib//rules:common_settings.bzl", "string_flag")
load("@bazel_skylib//lib:collections.bzl", "collections")

## contents:
##   ppx_inline_test
##   ppx_inline_test_ppx
##   ppx_inline_test_module
##   ppx_inline_test_signature
##   ppx_inline_test_suite
##   ppx_inline_test_all

def _ppx_inline_test_impl(name,
                          # srcs,
                          testsuites,
                          prologue = None,
                          epilogue = None,
                          visibility = [":__pkg__"],
                          **kwargs):
    # tsuites = []
    # for p in prologue:
    #     (pfx, sep, stem) = p.name.partition("_")
    #     tsuites.append(pfx)
    # tsuites = collections.uniq(tsuites)
    # print(tsuites)

    string_flag(name = name + "_t",
                values = testsuites,
                build_setting_default = testsuites[0])
    for ts in testsuites:
        native.config_setting(name = name + "_" + ts,
                          flag_values = {name + "_t": ts})
    # native.config_setting(name = name + "_bye",
    #                       flag_values = {name + "_t": "bye"})

    prolog = ["@opam.ppx_inline_test//lib/runner/lib"]
    if prologue:
        # print(prologue)
        prolog = prolog + prologue
    # plog = [name + "_" + src.name for src in srcs]
    # prolog.extend(plog)
    # prolog.extend(["tmod_" + d.name for d in deps])
    # print(prolog)

    argdict = {}
    for ts in testsuites:
        argdict[name + "_" + ts] = ["inline-test-runner", ts]

    # print(argdict)

    ocaml_test(
        name = name,
        main = "@opam.ppx_inline_test//lib/runner",
        args = select(argdict),
        prologue = prolog,
        visibility = visibility,
        **kwargs
    )

########################
ppx_inline_test = macro(
    inherit_attrs = ocaml_test,
    implementation = _ppx_inline_test_impl,
    attrs = {
        # "srcs": attr.label_list(configurable = False),
        # "deps": attr.label_list(configurable = False),
        "testsuites": attr.string_list(
            mandatory    = True,
            configurable = False,
        ),
        "prologue": attr.label_list(configurable = False),
        "epilogue": attr.label_list(configurable = False),
        "args": None,
        "main": None,
    },
)

################################################################
def _ppx_inline_test_suite_impl(name,
                                structs,
                                sigs,
                                ppx,
                                ppx_print,
                                # testsuite,
                                args = None,
                                visibility = [":__pkg__"],
                                **kwargs):
    ppxargs = ["-inline-test-lib", name]
    if args:
        ppxargs = ppxargs + (args)

    signames = [sig.name for sig in sigs]
    for s in structs:
        if s.name + "i" in signames:
            siggy = name + "_" + s.name + "i"
        else:
            siggy = None
        ocaml_module(
            name = name + "_" + s.name,
            struct = name + "_ppx_" + s.name,
            sig    = siggy,
            deps = [ ],
            visibility = visibility,
        )
        ppx_transform(
            name = name + "_ppx_" + s.name,
            src = s,
            ppx = ppx.name + "_exe",
            args = ppxargs
        )

    for s in sigs:
        ocaml_signature(
            name = name + "_" + s.name,
            src = s.name,
            # ppx = ppx.name + "_exe",
            # ppx_args = ppxargs,
            # ppx_print = ppx_print,
            visibility = visibility,
        )
        # ppx_transform(
        #     name = name + "_ppx_" + s.name,
        #     src = s,
        #     ppx = ppx.name + "_exe",
        #     args = ppxargs
        # )


########################
ppx_inline_test_suite = macro(
    inherit_attrs = ocaml_module,
    implementation = _ppx_inline_test_suite_impl,
    attrs = {
        "structs": attr.label_list(configurable = False),
        "sigs": attr.label_list(configurable = False),
        "ppx":  attr.label(configurable = False),
        # "testsuite": attr.string( # -inline-test-lib, inline-test-runner libname
        #     mandatory = True,
        #     configurable = False,
        # ),
        "args": attr.string_list(configurable = True),
        "struct": None
    },
)

################################################################
def _ppx_inline_test_signature_impl(name,
                                    src,
                                    ppx,
                                    args,
                                    deps,
                                    testsuite,
                                    visibility = [":__pkg__"],
                                    **kwargs):
    # FIXME: merge deps

    ocaml_signature(
        name = name,
        src  = name + "_ippx.ml",
        deps = ["@opam.ppxlib//lib/ppxlib"],
        visibility = visibility,
        **kwargs
    )
    ppxargs = ["-inline-test-lib", testsuite]
    if args: ppxargs = ppxargs + (args)
    ppx_transform(
        name = name + "_ippx.ml",
        src  = src,
        ppx  = ppx.name + "_exe",
        args = ppxargs,
        visibility = visibility,
    )

########################
ppx_inline_test_signature = macro(
    inherit_attrs = ocaml_signature,
    implementation = _ppx_inline_test_signature_impl,
    attrs = {
        "src": attr.label(configurable = False),
        "ppx": attr.label(configurable = False),
        "testsuite": attr.string(
            mandatory = True,
            configurable = False),
        "args": attr.string_list(configurable = True),
    },
)

################################################################
def _ppx_inline_test_module_impl(name,
                                 struct,
                                 sig,
                                 deps,
                                 ppx,
                                 args,
                                 testsuite,
                                 visibility = [":__pkg__"],
                                 **kwargs):

    ## FIXME: merge deps

    ocaml_module(
        name = name,
        struct = name + "_ppx.ml",
        sig    = sig,
        deps = ["@opam.ppxlib//lib/ppxlib"],
        visibility = visibility,
        **kwargs
    )
    ppxargs = ["-inline-test-lib", testsuite]
    if args: ppxargs = ppxargs + (args)
    ppx_transform(
        name = name + "_ppx.ml",
        src = struct,
        ppx = ppx.name + "_exe",
        args = ppxargs,
        visibility = visibility,
    )

########################
ppx_inline_test_module = macro(
    inherit_attrs = ocaml_module,
    implementation = _ppx_inline_test_module_impl,
    attrs = {
        "struct": attr.label(
            mandatory = True,
            configurable = False),
        "sig": attr.label(
            mandatory = False,
            configurable = False),
        "ppx": attr.label(
            mandatory = True,
            configurable = False),
        "testsuite": attr.string(
            mandatory = True,
            configurable = False),
        "args": attr.string_list(configurable = True),
    },
)

################################################################
def _ppx_inline_test_ppx_impl(name,
                              prologue = None,
                              epilogue = None,
                              visibility = [":__pkg__"],
                              **kwargs):

    prolog = ["@opam.ppx_inline_test//lib/ppx_inline_test"]
    if prologue:
        prolog.extend(prologue)

    ppx_executable(
        name = name + "_exe",
        prologue = prolog,
        main = name + "_Driver",
        visibility = visibility,
    )

    ocaml_module(
        name = name + "_Driver",
        struct = name + "_ppxlib_driver.ml",
        deps = ["@opam.ppxlib//lib/ppxlib"],
        visibility = visibility,
    )

    native.genrule(
        name = name + "_driver.ml",
        outs = [name + "_ppxlib_driver.ml"],
        cmd = "\n".join([
            "echo \"(* GENERATED FILE - DO NOT EDIT *)\" > \"$@\"",
            "echo \"let () = Ppxlib.Driver.standalone ()\" >> \"$@\"",
        ])
    )

########################
ppx_inline_test_ppx = macro(
    inherit_attrs = ppx_executable,
    implementation = _ppx_inline_test_ppx_impl,
    attrs = {
        "prologue": attr.label_list(configurable = False),
        "epilogue": attr.label_list(configurable = False),
        "main": None
    },
)

