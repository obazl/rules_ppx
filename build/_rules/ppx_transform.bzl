load("@bazel_skylib//lib:paths.bzl", "paths")

load("@rules_ocaml//build:providers.bzl", "OCamlDepsProvider")
load("@rules_ocaml//build:providers.bzl",
     "OcamlExecutableMarker",
     "OCamlModuleProvider",
     "OCamlNsResolverProvider")

load("@rules_ocaml//build/_transitions:in_transitions.bzl",
     "toolchain_in_transition")

load("@rules_ocaml//lib:merge.bzl",
     "merge_deps",
     # "MergedDepsProvider",
     "DepsAggregator")

load("@rules_ocaml//build/_lib:module_naming.bzl", "derive_module_name_from_file_name")

load("@rules_ocaml//build/_lib:options.bzl",
     "options",
     "options_module",
     "options_ns_opts",
     "options_ppx")

# load("@rules_ocaml//ocaml/_rules:impl_common.bzl", "dsorder")
load(":impl_ppx_transform.bzl", "impl_ppx_transform")

load("@rules_ocaml//lib:colors.bzl",
     "CCRED", "CCDER", "CCGRN", "CCBLU", "CCBLUBG", "CCMAG", "CCCYN", "CCRESET")

## ocaml/_rules/impl_common.bzl
tmpdir = "__obazl/"
dsorder = "postorder"
# opam_lib_prefix = "external/ocaml/lib"
module_sep = "__"
resolver_suffix = module_sep + "0Resolver"

##########################
def _handle_ns_stuff(ctx):

    debug_ns = False

    if not hasattr(ctx.attr, "ns"):
        ## this is a plain ocaml_module w/o namespacing
        return  (False, # ns_enabled
                 None,  # nsr_provider = NsResolverProvider
                 None)  # ns_resolver module

    ns_enabled = False
    nsr_provider = None  ## NsResolverProvider
    nsr_target = None  ## resolver module

    ## bottom-up namespacing
    if ctx.attr.ns:
        print("NS %s" % ctx.attr.ns)
        ns_enabled = True
        nsr_target = ctx.attr.ns
        nsr_provider = ctx.attr.ns[OCamlNsResolverProvider]
        if hasattr(nsr_provider, "modname"):
            # e.g. Foo__
            # ns_module_name = nsr_provider.modname
            ns_enabled = True

    ## top-down namespacing
    elif ctx.attr._ns_resolver:
        nsr_provider = ctx.attr._ns_resolver[OCamlNsResolverProvider]
        if debug_ns:
            print("_ns_resolver: %s" % ctx.attr._ns_resolver)
            print("nsr_provider: %s" % nsr_provider)
        if not nsr_provider.tag == "NULL":
            ns_enabled = True
            # fail("XXXXXXXXXXXXXXXX")
            nsr_target = ctx.attr._ns_resolver ## [0] # index by int?
            # ns_resolver_files = ctx.files._ns_resolver ## [0] # index by int?

    else:
        if debug_ns: print("m: no resolver for %s" % ctx.label)
        nsr_target = None
        # ns_resolver_files = []

    return  (ns_enabled,
             nsr_provider,
             nsr_target)

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

    ns_enabled = False
    (ns_enabled,
     nsr_provider, ## NsResolverProvider
     nsr_target) = _handle_ns_stuff(ctx)

# def _resolve_modname(ctx):
    debug = False
    if debug: print("deriving module name from structfile: %s" % ctx.file.src.basename)

    (mname, ext) = paths.split_extension(ctx.file.src.basename)
    (from_name,
     modname) = derive_module_name_from_file_name(
         ctx, mname, nsr_provider
     )
    if debug: print("derived module name: %s" % modname)

    # depsets = DepsAggregator(
    #     deps = MergedDepsProvider(
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
    #     codeps = MergedDepsProvider(
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

    # depsets = merge_deps(ctx, ctx.attr.ppx, depsets)

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

    # _ocamlProvider = OCamlDepsProvider(
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

    # ppxCodepsProvider = OCamlCodepsProvider(
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

    # coprovider = ctx.attr.ppx[OCamlCodepsProvider]
    # ppxCodepsProvider = OCamlCodepsProvider(
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
rule_options = options("rules_ocaml")
# rule_options.update(options_ppx)

####################
ppx_transform = rule(
    implementation = _ppx_transform,
 # Provides: [OCamlModuleProvider](providers_ocaml.md#ocamlmoduleprovider).
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
    # cfg = toolchain_in_transition,
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
