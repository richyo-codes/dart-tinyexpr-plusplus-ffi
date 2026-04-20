import 'dart:io' show Platform;

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

Future<String> _detectCompilerFamily(CCompilerConfig? cc) async {
  if (cc == null) {
    return 'unknown';
  }

  final compilerPath = cc.compiler.path;
  if (compilerPath.contains('cl.exe') || compilerPath.contains('msvc')) {
    return 'msvc';
  }

  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    return 'clang';
  }

  return 'unknown';
}

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    final codeCfg = input.config.code;
    final cc = codeCfg.cCompiler;
    final compilerFamily = await _detectCompilerFamily(cc);

    final flags = <String>[];
    switch (compilerFamily) {
      case 'msvc':
        flags.addAll(['/std:c++20']);
        break;
      default:
        flags.addAll(['-std=c++20', '-fPIC']);
        break;
    }

    final defines = <String, String>{'TE_BITWISE_OPERATORS': '1'};
    if (compilerFamily == 'msvc') {
      defines.addAll({'WIN_EXPORT': '1', '_WIN32': '1'});
    }

    final libraries = <String>[];
    String? cppStdLib;
    if (input.config.code.targetOS == OS.android) {
      libraries.addAll(['c++abi', 'unwind', 'm']);
      flags.addAll(['-static-libstdc++', '-static-libgcc']);
      cppStdLib = 'c++_static';
    }

    final cbuilder = CBuilder.library(
      name: 'tinyexprpp_fii',
      assetName: 'tinyexprpp_fii.dart',
      includes: ['src/native/'],
      defines: defines,
      sources: ['src/native/tinyexprpp_wrapper.cpp', 'src/native/tinyexpr.cpp'],
      flags: flags,
      cppLinkStdLib: cppStdLib,
      libraries: libraries,
      language: Language.cpp,
    );

    await cbuilder.run(
      input: input,
      output: output,
      logger: (Logger('')
        ..level = Level.ALL
        ..onRecord.listen((record) => print(record.message))),
    );
  });
}
