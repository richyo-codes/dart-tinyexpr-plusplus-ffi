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
    }).then((module) => {
      module.evaluateExpression = (expression) => {
        const bytes = new TextEncoder().encode(`${expression}\0`);
        const pointer = module._malloc(bytes.length);
        module.HEAPU8.set(bytes, pointer);
        try {
          return module._tepp_eval(pointer);
        } finally {
          module._free(pointer);
        }
      };
      return module;
    });
  }
  return modulePromise;
}
