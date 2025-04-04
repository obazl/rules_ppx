load("@rules_ocaml//build:providers.bzl",
     "OCamlArchiveProvider",
     "OcamlExecutableMarker",
     "OCamlImportProvider",
     "OCamlLibraryProvider",
     "OCamlModuleProvider",
     "OcamlNsMarker")

load("@rules_ppx//build/_transitions:ppx_executable_in_transition.bzl",
     "ppx_executable_in_transition")

load("@rules_ocaml//build/_transitions:out_transitions.bzl",
     "ocaml_binary_deps_out_transition")

load("@rules_ocaml//build/_lib:apis.bzl", "options", "options_binary")

load("@rules_ocaml//build/_rules/ocaml_binary:impl_binary.bzl", "impl_binary")

load("@rules_ocaml//lib:colors.bzl", "CCDER", "CCGAM", "CCRESET")

CCBLURED="\033[44m\033[31m"

################################################
def _ppx_deps_out_transition_impl(settings, attr):
    # print("{c}_ppx_deps_out_transition{r}: {lbl}".format(
    #     c=CCDER, r = CCRESET, lbl = attr.name
    # ))

    host = "@rules_ocaml//platform:ocamlopt.opt"
    tgt  = "@rules_ocaml//platform:ocamlopt.opt"
    return {
        # no change
        "@rules_ocaml//cfg/ns:prefixes":   [],
        "@rules_ocaml//cfg/ns:submodules": [],
        # "@rules_ocaml//toolchain" : "ocamlopt",
        # "//command_line_option:host_platform": host,
        # "//command_line_option:platforms": tgt
    }

################
_ppx_deps_out_transition = transition(
    implementation = _ppx_deps_out_transition_impl,
    inputs = [
        "@rules_ocaml//cfg/ns:prefixes",
        "@rules_ocaml//cfg/ns:submodules",
        "@rules_ocaml//toolchain",
        "//command_line_option:host_platform",
        "//command_line_option:platforms",
    ],
    outputs = [
        "@rules_ocaml//cfg/ns:prefixes",
        "@rules_ocaml//cfg/ns:submodules",
        # "@rules_ocaml//toolchain",
        # "//command_line_option:host_platform",
        # "//command_line_option:platforms",
    ]
)

###########################
def _ppx_executable(ctx):

    # print("{c}ppx_executable: {m}{r}".format(
    #     c=CCBLURED,m=ctx.label,r=CCRESET))

    # if True: #  debug_tc:
    #     tc = ctx.toolchains["@rules_ocaml//toolchain/type:std"]
    #     print("BUILD TGT: {color}{lbl}{reset}".format(
    #         color=CCGAM, reset=CCRESET, lbl=ctx.label))
    #     print("  TC.NAME: %s" % tc.name)
    #     print("  TC.HOST: %s" % tc.host)
    #     print("  TC.TARGET: %s" % tc.target)
    #     print("  TC.COMPILER: %s" % tc.compiler.basename)

    return impl_binary(ctx) # , tc.target, tc, tc.compiler, [])

########## DECL:  PPX_EXECUTABLE  ################
rule_options = options("rules_ocaml")
rule_options.update(options_binary())
ppx_executable = rule(
    implementation = _ppx_executable,
    doc = """Generates a PPX executable.  Provides: [OcamlExecutableMarker](providers_ppx.md#ppxexecutableprovider).

    """,

    ## FIXME: use apis.bzl from rules_ocaml

    attrs = dict(
        rule_options,
        _linkall = attr.label(default = "@rules_ocaml//cfg/executable:linkall"),
        # _linkall     = attr.label(default = "@ppx//executable/linkall"),
        # threading is supported by pkg @ocaml//threads; just add it
        # as a dep
        # _threads     = attr.label(default = "@ppx//executable/threads"),
        _warnings  = attr.label(default = "@rules_ocaml//cfg/executable:warnings"),
        _opts = attr.label(
            doc = "Hidden options.",
            default = "@rules_ocaml//cfg/executable:opts"
        ),
        # IMPLICIT: args = string list = runtime args, passed whenever the binary is used
        exe = attr.string(
            doc = "Name for output executable file.  Overrides 'name' attribute."
        ),

        bin = attr.label( # 'import' would be better but it's a keyword
            doc = "Precompiled ppx executable",
            allow_single_file = True,
        ),

        ## IMPORTANT! ppx_executables are always transitioned
        ## to "exec" (tool) config, so their deps must
        ## also have 'cfg = "exec"'.  Without this, ocaml_imports
        ## will use the target platform to select archives,
        ## which may fail for target vm>any, since it does
        ## not set platform:emitter, which will thus have
        ## the default value 'sys'.  So we need to tell
        ## Bazel that ocaml_imports should use the build platform
        ## when interpreting e.g.
        ## archive  =  select({
        ##  "@rules_ocaml//platform/emitter:vm" : "stdppx.cma",
        ##  "@rules_ocaml//platform/emitter:sys": "stdppx.cmxa"})
        ## The standard way to do this is to make the target
        ## platform the same as the build platform,
        ## which is what 'cfg = "exec"' does.
        ## Unfortunately that's not quite right, since e.g.
        ## sys>vm => sys>vm is invalid. We instead need
        ## sys>vm => vm>any (correct for bld, but defaults
        ## to vm>sys, which selects the wrong archive)
        ## so we need sys>vm => vm>vm
        ## so instead of using 'cfg = "exec"' we use
        ## a custom inbound transition to set the
        ## target platform.

        archive_deps = attr.bool(default = False),

        prologue = attr.label_list(
            doc = "List of OCaml dependencies.",
            providers = [[OCamlArchiveProvider],
                         [OCamlImportProvider],
                         [OCamlLibraryProvider],
                         [OCamlModuleProvider],
                         [OcamlNsMarker],
                         [CcInfo]],
            # cfg = "exec",
            # cfg = _ppx_deps_out_transition
            # cfg = ocaml_binary_deps_out_transition
        ),

        main = attr.label(
            doc = "A module to be listed after those in 'prologue' and before those in 'epilogue'. For more information see [Main Module](../ug/ppx.md#main_module).",
            mandatory = True,
            # allow_single_file = True,
            # providers = [
            #     [OCamlModuleProvider], [PpxExecutableMarker]
            #     # or @opam.ppxlib//lib/runner"
            # ],
            default = None,
            # cfg = "exec",
            # cfg = _ppx_deps_out_transition
        ),
        epilogue = attr.label_list(
            doc = "List of OCaml dependencies.",
            providers = [[OCamlArchiveProvider],
                         [OCamlImportProvider],
                         [OCamlLibraryProvider],
                         [OCamlModuleProvider],
                         [OcamlNsMarker],
                         [CcInfo]],
            # cfg = "exec",
            # cfg = _ppx_deps_out_transition
            # cfg = ocaml_binary_deps_out_transition
        ),

        # finalizer = attr.label(),

        # FIXME: no need for ppx attrib on ppx_executable?
        # (since no source files)
        # ppx  = attr.label(
        #     doc = "PPX binary (executable).",
        #     providers = [PpxExecutableMarker],
        #     mandatory = False,
        # ),
        # print = attr.label(
        #     doc = "Format of output of PPX transform, binary (default) or text",
        #     default = "@ppx//print"
        # ),

        ## NB: 'args' is built-in, cannot add as attrib
        # runtime_args = attr.string_list(
        # args = attr.string_list(
        #     doc = "List of args that will be passed to the ppx_executable at runtime. E.g. -inline-test-lib. CAVEAT: will be used wherever the exec is run, and passed before command line args.  For finer granularity use the 'ppx_args' attr of e.g. ocaml_module."
        # ),

        data  = attr.label_list(
            doc = "Runtime data dependencies. E.g. a file used by %%import from ppx_optcomp.",
            allow_files = True,
        ),

        data_prefix_map = attr.string_dict(
            doc = """Map for replacing path prefixes of data files.  May be used to strip a path prefix (set value to empty string "").
            """
        ),

        # strip_data_prefixes = attr.bool(
        #     doc = "Symlink each data file to the basename part in the runfiles root directory. E.g. test/foo.data -> foo.data.",
        #     default = False
        # ),

        # manifest = attr.label_list(
        #     doc = "Mereological deps to be directly linked into ppx executable. Modular deps should be listed in ocaml_module, ppx_module rules.",
        #     providers = [[DefaultInfo], [OCamlModuleProvider], [CcInfo]],
        #     cfg = _ppx_deps_out_transition
        # ),

        # _deps = attr.label(
        #     doc = "Dependency to be added last.",
        #     default = "@rules_ocaml//cfg/executable:deps"
        # ),

        ## ppx_executable only
        ppx_codeps = attr.label_list(
            doc = """List of non-opam adjunct dependencies (labels).""",
            mandatory = False,
            # FIXME: for jsoo, codeps must pass on js files. :(
            # otherwise the link action would have to transpile them
            cfg = "target"
            # providers = [[DefaultInfo], [PpxModuleMarker]]
        ),

        # ppx_runner = attr.label_list(
        #     doc = """Modules to be linked last when the transformed module is linked into an executable.""",
        #     mandatory = False,
        #     cfg = "target"
        #     # providers = [[DefaultInfo], [PpxModuleMarker]]
        # ),

        ################
        cc_deps = attr.label_keyed_string_dict(
            doc = "C/C++ library dependencies",
            providers = [[CcInfo]]
        ),
        _cc_deps = attr.label(
            doc = "Global C/C++ library dependencies. Apply to all instances of ocaml_binary.",
            ## FIXME: cc libs could come from LSPs that do not support CcInfo, e.g. rules_rust
            # providers = [[CcInfo]]
            default = "@rules_ocaml//cfg/executable:cc_deps"
        ),
        cc_linkall = attr.label_list(
            ## equivalent to cc_library's "alwayslink"
            doc     = "True: use `-whole-archive` (GCC toolchain) or `-force_load` (Clang toolchain). Deps in this attribute must also be listed in cc_deps.",
            # providers = [CcInfo],
        ),
        cc_linkopts = attr.string_list(
            doc = "List of C/C++ link options. E.g. `[\"-lstd++\"]`.",

        ),

        _vm_ext = attr.label(
            default = "@rules_ocaml//cfg/executable:vm_ext"
        ),
        _sys_ext = attr.label(
            default = "@rules_ocaml//cfg/executable:sys_ext"
        ),

        runtime = attr.label(
            doc = "runtime to use",
            default = "@rules_ocaml//rt:std"
        ),

        vm_linkage = attr.string(
            doc = "custom, dynamic or static. Custom means link with -custom flag; static with -output-complete-exe",
            values = ["custom", "static", "dynamic"],
            default = "custom"
        ),

        # vm_runtime = attr.label(
        #     doc = "@rules_ocaml//cfg/runtime:dynamic (default), @rules_ocaml//cfg/runtime:static, or a custom ocaml_vm_runtime target label",
        #     default = "@rules_ocaml//cfg/runtime:dynamic"
        # ),

        _rule = attr.string( default = "ppx_executable" ),
        _tags = attr.string_list( default  = ["ppx", "executable"] ),

        ## required, so we can obtain the cc tc and inspect it
        ## to determine if we need to -UDEBUG
        _cc_toolchain = attr.label(
            default = Label(
                # "@bazel_tools//tools/cpp:current_cc_toolchain"
                "@rules_cc//cc:current_cc_toolchain",
            )
        ),

        _allowlist_function_transition = attr.label(
            ## required for transition fn of attribute _mode
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist"
        ),

    ),
    cfg     = ppx_executable_in_transition,
    provides = [DefaultInfo, OcamlExecutableMarker],
    executable = True,
    ## NB: 'toolchains' actually means 'toolchain types'
    toolchains = [
        "@rules_ocaml//toolchain/type:std",
        "@rules_ocaml//toolchain/type:profile",
        "@bazel_tools//tools/cpp:toolchain_type"
    ],
)
