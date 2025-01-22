load("@bazel_skylib//lib:paths.bzl", "paths")

load("@rules_ocaml//providers:ocaml.bzl",
     "OcamlExecutableMarker",
     "OcamlProvider",
     "OcamlModuleMarker",
     "OcamlNsResolverProvider")

load("@rules_ocaml//ocaml:aggregators.bzl",
     "aggregate_deps",
     "OCamlProvider",
     "DepsAggregator")

load("@rules_ocaml//ocaml/_functions:module_naming.bzl", "derive_module_name_from_file_name")

load("@rules_ocaml//ocaml/_rules:options.bzl",
     "options",
     "options_module",
     "options_ns_opts",
     "options_ppx")

# load("@rules_ocaml//ocaml/_rules:impl_common.bzl", "dsorder")
load(":impl_ppx_transform.bzl", "impl_ppx_transform")

load("@rules_ocaml//ocaml/_debug:colors.bzl",
     "CCRED", "CCDER", "CCGRN", "CCBLU", "CCBLUBG", "CCMAG", "CCCYN", "CCRESET")

## ocaml/_rules/impl_common.bzl
tmpdir = "__obazl/"
dsorder = "postorder"
# opam_lib_prefix = "external/ocaml/lib"
module_sep = "__"
resolver_suffix = module_sep + "0Resolver"

###############################
def _ppx_transform(ctx):

    # tasks: run ppx, pass-through all deps

    # print("{c}ppx_transform: {m}{r}".format(
    #     c=CCBLUBG,m=ctx.label,r=CCRESET))

    # if True:  # debug_tc:
    #     tc = ctx.toolchains["@rules_ocaml//toolchain/type:std"]
    #     print("BUILD TGT: {color}{lbl}{reset}".format(
    #         color=CCNRG, reset=CCRESET, lbl=ctx.label))
    #     print("  TC.NAME: %s" % tc.name)
    #     print("  TC.HOST: %s" % tc.host)
    #     print("  TC.TARGET: %s" % tc.target)
    #     print("  TC.COMPILER: %s" % tc.compiler.basename)

    # return impl_module(ctx) # , tc.target, tc.compiler, [])

# def _resolve_modname(ctx):
    debug = False
    if debug: print("deriving module name from structfile: %s" % ctx.file.src.basename)

    (mname, ext) = paths.split_extension(ctx.file.src.basename)
    (from_name, modname) = derive_module_name_from_file_name(ctx, mname)
    if debug: print("derived module name: %s" % modname)

    # depsets = DepsAggregator(
    #     deps = OCamlProvider(
    #         sigs = [],
    #         structs = [],
    #         ofiles  = [],
    #         archives = [],
    #         afiles = [],
    #         astructs = [], # archived cmx structs, for linking
    #         cmts = [],
    #         paths  = [],
    #         jsoo_runtimes = [], # runtime.js files
    #     ),
    #     codeps = OCamlProvider(
    #         sigs = [],
    #         structs = [],
    #         ofiles = [],
    #         archives = [],
    #         afiles = [],
    #         astructs = [],
    #         cmts = [],
    #         paths = [],
    #         jsoo_runtimes = [],
    #     ),
    #     ccinfos = []
    # )

    # depsets = aggregate_deps(ctx, ctx.attr.ppx, depsets)

    ################################################################
    # (src, outfile) = impl_ppx_transform(

    providers = impl_ppx_transform(
        "ppx_transform", ## ctx.attr._rule,
        ctx,
        ctx.file.src,
        modname + ext
    )

    ################################################################
    # providers = [
    #     DefaultInfo(files = depset(direct = [outfile])),
    # ]

    # _ocamlProvider = OcamlProvider(
    #     # struct = depset(direct = [outfile]),
    #     sigs    = depset(order="postorder",
    #                      # direct=sigs_primary,
    #                      transitive = depsets.deps.sigs),
    #     structs = depset(order="postorder",
    #                      # direct=structs_primary,
    #                      transitive = depsets.deps.structs),
    #     ofiles   = depset(order="postorder",
    #                       # direct=ofiles_primary,
    #                       transitive = depsets.deps.ofiles),
    #     archives = depset(order="postorder",
    #                       # direct=archives_primary,
    #                       transitive = depsets.deps.archives),
    #     afiles   = depset(order="postorder",
    #                       # direct=afiles_primary,
    #                       transitive = depsets.deps.afiles),
    #     astructs = depset(order="postorder",
    #                       # direct=astructs_primary,
    #                       transitive = depsets.deps.astructs),
    #     cmts     = depset(order="postorder",
    #                       # direct=cmts_primary,
    #                       transitive = depsets.deps.cmts),
    #     paths    = depset(order="postorder",
    #                       # direct=paths_primary,
    #                       transitive = depsets.deps.paths),
    #     jsoo_runtimes = depset(order="postorder",
    #                            # direct=jsoo_runtimes_primary,
    #                            transitive = depsets.deps.jsoo_runtimes),
    # )
    # providers.append(_ocamlProvider)

    # ppxCodepsProvider = OcamlCodepsProvider(
    #     sigs       = depset(order=dsorder,
    #                         transitive = depsets.codeps.sigs),
    #     structs    = depset(order=dsorder,
    #                         transitive = depsets.codeps.structs),
    #     ofiles     = depset(order=dsorder,
    #                         transitive = depsets.codeps.ofiles),
    #     archives   = depset(order=dsorder,
    #                         transitive = depsets.codeps.archives),
    #     afiles     = depset(order=dsorder,
    #                         transitive = depsets.codeps.afiles),
    #     astructs   = depset(order=dsorder,
    #                             transitive = depsets.codeps.astructs),
    #     paths      = depset(order=dsorder,
    #                       transitive = depsets.codeps.paths),
    #     jsoo_runtimes = depset(order="postorder",
    #                            transitive = depsets.codeps.jsoo_runtimes),
    # )
    # providers.append(ppxCodepsProvider)

    # coprovider = ctx.attr.ppx[OcamlCodepsProvider]
    # ppxCodepsProvider = OcamlCodepsProvider(
    #     sigs       = coprovider.sigs,
    #     structs       = coprovider.structs,
    #     ofiles       = coprovider.ofiles,
    #     archives       = coprovider.archives,
    #     afiles       = coprovider.afiles,
    #     astructs       = coprovider.astructs,
    #     paths       = coprovider.paths,
    #     # # cc_deps = depset(order=dsorder,
    #     # #                 direct = codep_cc_deps_primary,
    #     # #                 transitive = codep_cc_deps_secondary),
    # )

    # outputGroupInfo = OutputGroupInfo(
    #     sigs       = coprovider.sigs,
    #     structs       = coprovider.structs,
    #     ofiles       = coprovider.ofiles,
    #     archives       = coprovider.archives,
    #     afiles       = coprovider.afiles,
    #     astructs       = coprovider.astructs,
    #     # paths       = coprovider.paths,
    #     # all = depset(transitive=[
    #     #     ppx_codeps_depset,
    #     # ])
    # )
    return providers

################################
rule_options = options("ocaml")
# rule_options.update(options_ppx)

####################
ppx_transform = rule(
    implementation = _ppx_transform,
 # Provides: [OcamlModuleMarker](providers_ocaml.md#ocamlmoduleprovider).
    doc = """
    Runs a ppx executable to transform a source file. Also propagates ppx_codeps from the provider of the ppx dependency.
    """,
    attrs = dict(
        rule_options,

        src = attr.label(
            doc = "A single source file (struct or sig) label.",
            mandatory = True,
            allow_single_file = True # no constraints on extension?
        ),

        ppx  = attr.label(
            doc = """
        Label of `ppx_executable` target to be used to transform source before compilation.
        """,
            executable = True,
            cfg = "exec",
            # cfg = _ppx_transition,
            allow_single_file = True,
            providers = [OcamlExecutableMarker]
        ),

        ## args (not opts; opts for for building, args for running)
        args = attr.string_list(
            doc = "List of args to pass to ppx executable at runtime."
        ),

        data = attr.label_list(
            allow_files = True,
            doc = "Runtime data dependencies: list of labels of data files needed by ppx executable at runtime."
        ),

        print = attr.label(
            # using a label gives user global control
            # with a bool it would not be possible to set
            # on cmd line
            doc = "Format of output of PPX transform. Value must be one of `@rules_ppx//print:text`, `@rules_ppx//print:text!`.  See link:../ug/ppx.md#ppx_print[PPX Support] for more information",
            default = "@rules_ppx//print:text" # False
        ),

        # _allowlist_function_transition = attr.label(
        #     default = "@bazel_tools//tools/allowlists/function_transition_allowlist"
        # ),

        _rule = attr.string( default = "ppx_transform" ),
    ),

    fragments = ["platform"],
    host_fragments = ["platform"],
    incompatible_use_toolchain_transition = True,
    # cfg     = module_in_transition,
    # provides = [PpxModuleMarker],
    toolchains = ["@rules_ocaml//toolchain/type:std",
                  "@rules_ocaml//toolchain/type:profile"
                  # "@bazel_tools//tools/cpp:toolchain_type"
                  ],
)
