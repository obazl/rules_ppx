load("@rules_ocaml//build:transitions.bzl",
     "executable_in_transition_impl",
     "get_tc")

def _ppx_executable_in_transition_impl(settings, attr):
    # configs =  executable_in_transition_impl("ppx_executable_in_transition", settings, attr)

    build_host  = settings["//command_line_option:host_platform"]
    target_host = settings["//command_line_option:platforms"]

    tc = settings["@rules_ocaml//toolchain"]
    # print("ppx: %s" % attr.name)
    # print("BUILDHOST: %s" % build_host)
    # print("TARGETHOST: %s" % target_host)
    # print("TC: %s" % tc)

    if tc == "nop":
        host = build_host
        tgt  = target_host
    else:
        if Label(build_host) == target_host[0]:
            if build_host.name == "ocamlc.opt":
                # set sys>vm => vm>vm
                host = build_host
                # tgt  = ["@rules_ocaml//platform:vm>any"]
                tgt  = ["@rules_ocaml//platform:ocamlc.byte"]
            elif build_host.name == "ocamlopt.byte":
                # set vm>sys => sys>sys
                host = build_host
                # tgt  = ["@rules_ocaml//platform:sys>any"]
                tgt  = ["@rules_ocaml//platform:ocamlopt.opt"]
            else:
                host = build_host
                tgt  = target_host
        else:
            host, tgt = get_tc(settings, attr)
    # fail("HOST {}, TGT {}".format(host, tgt))

    # return configs.update({
    #     "@rules_ocaml//toolchain": "ocamlopt"
    # })
    # if host != None:
    # host = "@rules_ocaml//platform:ocamlopt.opt"
    # tgt  = "@rules_ocaml//platform:ocamlopt.opt"
    configs = {
        "@rules_ocaml//toolchain" : "nop", # "ocamlopt",
        "//command_line_option:host_platform": host,
        "//command_line_option:platforms": tgt
    }
    # print("CONFIGS: %s" % configs)
    return configs
    # else:
    #     return configs.update({
    #         "//command_line_option:host_platform": host,
    #         "//command_line_option:platforms": tgt
    #     })

ppx_executable_in_transition = transition(
    implementation = _ppx_executable_in_transition_impl,
    inputs = [
        # "@rules_ocaml//cfg/ns:prefixes",
        # "@rules_ocaml//cfg/ns:submodules",
        "@rules_ocaml//toolchain",
        "//command_line_option:host_platform",
        "//command_line_option:platforms"
    ],
    outputs = [
        # "@rules_ocaml//cfg/ns:prefixes",
        # "@rules_ocaml//cfg/ns:submodules",
        "@rules_ocaml//toolchain",
        "//command_line_option:host_platform",
        "//command_line_option:platforms"
    ]
)

