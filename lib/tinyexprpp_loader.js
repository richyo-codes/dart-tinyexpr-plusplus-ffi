import createTinyExprModule from './tinyexprpp.js';

let modulePromise;

export function initializeTinyExpr(options = {}) {
  if (!modulePromise) {
    modulePromise = createTinyExprModule({
      locateFile(path) {
        if (path.endsWith('.wasm') && options.wasmUrl) {
          return options.wasmUrl;
        }
        return new URL(path, import.meta.url).toString();
      },
    });
  }
  return modulePromise;
}
