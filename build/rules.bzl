"""Public definitions for PPX rules.

All public PPX rules imported and re-exported in this file.

Definitions outside this file are private unless otherwise noted, and
may change without notice.
"""

load("//build/_rules:ppx_executable.bzl" ,
     _ppx_executable            = "ppx_executable")
load("//build/_rules:ppx_module.bzl" ,
     _ppx_module                = "ppx_module")
load("//build/_rules:ppx_transform.bzl" ,
     _ppx_transform             = "ppx_transform")
load("//build/_rules:ppx_inline_test.bzl" ,
     _ppx_inline_test           = "ppx_inline_test",
     _ppx_inline_test_module    = "ppx_inline_test_module",
     _ppx_inline_test_signature = "ppx_inline_test_signature",
     _ppx_inline_test_ppx       = "ppx_inline_test_ppx",
     _ppx_inline_test_suite     = "ppx_inline_test_suite")

# load("//build/_rules:ppx_test.bzl",
#      _ppx_expect_test = "ppx_expect_test",
#      _ppx_test = "ppx_test")

ppx_executable          = _ppx_executable
ppx_module              = _ppx_module
ppx_transform           = _ppx_transform
ppx_inline_test         = _ppx_inline_test
ppx_inline_test_module  = _ppx_inline_test_module
ppx_inline_test_signature = _ppx_inline_test_signature
ppx_inline_test_ppx     = _ppx_inline_test_ppx
ppx_inline_test_suite   = _ppx_inline_test_suite

# ppx_expect_test  = _ppx_expect_test
# ppx_test         = _ppx_test
