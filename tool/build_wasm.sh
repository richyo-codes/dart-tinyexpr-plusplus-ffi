#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

emcc src/native/tinyexprpp_wrapper.cpp src/native/tinyexpr.cpp \
  -std=c++20 \
  -DTE_BITWISE_OPERATORS=1 \
  -sMODULARIZE=1 \
  -sEXPORT_ES6=1 \
  -sENVIRONMENT=web \
  -sNO_DISABLE_EXCEPTION_CATCHING=1 \
  -sEXPORTED_FUNCTIONS='["_malloc","_free","_tepp_eval","_tepp_compile","_tepp_eval_compiled","_tepp_free","_tepp_set_constant","_tepp_get_constant","_tepp_get_last_error_message","_tepp_get_last_error_position"]' \
  -sEXPORTED_RUNTIME_METHODS='["UTF8ToString","HEAPU8"]' \
  -o lib/tinyexprpp.js

cp lib/tinyexprpp.js web/tinyexprpp.js
cp lib/tinyexprpp.wasm web/tinyexprpp.wasm
