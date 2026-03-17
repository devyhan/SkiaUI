// wasmLoader.ts – DocsHost
// Handles loading and initializing the SwiftWasm module with JavaScriptKit runtime.

export interface WasmLoaderOptions {
  wasmPath: string;
}

export async function loadSwiftWasm(options: WasmLoaderOptions): Promise<WebAssembly.Instance | null> {
  try {
    const response = await fetch(options.wasmPath);
    if (!response.ok) {
      console.warn(`[WasmLoader] Failed to fetch WASM: ${response.status}`);
      return null;
    }

    const wasmBytes = await response.arrayBuffer();

    // JavaScriptKit runtime provides these import objects.
    // When building with SwiftWasm, the JavaScriptKit npm package
    // exports a `SwiftRuntime` class that creates the import object.
    const importObject: WebAssembly.Imports = {};

    const { instance } = await WebAssembly.instantiate(wasmBytes, importObject);

    // Call Swift's _start or _initialize if available
    const exports = instance.exports as Record<string, unknown>;
    if (typeof exports._initialize === 'function') {
      (exports._initialize as () => void)();
    } else if (typeof exports._start === 'function') {
      (exports._start as () => void)();
    }

    return instance;
  } catch (err) {
    console.error('[WasmLoader] Failed to load SwiftWasm module:', err);
    return null;
  }
}
