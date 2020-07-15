# Copyright 2018 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@io_bazel_rules_rust//rust:private/rust.bzl", "crate_root_src")
load("@io_bazel_rules_rust//rust:private/rustc.bzl", "CrateInfo", "DepInfo", "add_crate_link_flags", "add_edition_flags")
load("@io_bazel_rules_rust//rust:private/utils.bzl", "find_toolchain")

def _cargo_workspace_impl(ctx):
    toolchain = find_toolchain(ctx)
    # crate_root = ctx.file.cargo_toml.dirname
    # print(crate_root)
    # print(toolchain.cargo)
    # print(toolchain.rustc)

    # output_dir = ctx.actions.declare_directory(ctx.label.name)
    args = ctx.actions.args()
    # args.add(crate.root.path)

    cargo_toml = ctx.file.cargo_toml
    fake_cargo_toml = ctx.actions.declare_file("Cargo.toml.out")
    # ctx.actions.write(
    #     output = fake_cargo_toml,
    #     content = "Hello\n",
    # )

    # print(fake_cargo_toml.path)
    ctx.actions.run_shell(
        tools = [toolchain.cargo, toolchain.rustc],
        command = "%s metadata --manifest-path=%s > %s" % (toolchain.cargo.path, cargo_toml.path, fake_cargo_toml.path),
        env = {
            "RUSTC": toolchain.rustc.path,
        },
        inputs = [ctx.file.cargo_toml] + ctx.files.srcs,
        outputs = [fake_cargo_toml],
        # arguments = [args],
        # mnemonic = "Cargo",
    )
    # return DefaultInfo(files=depset([fake_cargo_toml]))

cargo_workspace = rule(
    _cargo_workspace_impl,
    attrs = {
        "cargo_toml": attr.label(
            allow_single_file = ["Cargo.toml"],
        ),
        "srcs": attr.label_list(
            doc = """
                List of Rust `.rs` source files used to build the library.

                If `srcs` contains more than one file, then there must be a file either
                named `lib.rs`. Otherwise, `crate_root` must be set to the source file that
                is the root of the crate to be passed to rustc to build this crate.
            """,
            allow_files = [".rs"],
        ),
        "data": attr.label_list(
        doc = """
                List of files used by this rule at runtime.

                This attribute can be used to specify any data files that are embedded into
                the library, such as via the
                [`include_str!`](https://doc.rust-lang.org/std/macro.include_str!.html)
                macro.
            """,
            allow_files = True,
        ),
        "deps": attr.label_list(
            doc = """
                List of other libraries to be linked to this library target.

                These can be either other `rust_library` targets or `cc_library` targets if
                linking a native library.
            """,
        ),
    },
    outputs = {
        "target": "Cargo.toml.out"
    },
    toolchains = ["@io_bazel_rules_rust//rust:toolchain"],
)
