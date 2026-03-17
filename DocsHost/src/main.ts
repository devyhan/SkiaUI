// main.ts – DocsHost entry point
// Loads CanvasKit and initializes the WASM-based SkiaUI documentation demo.

import CanvasKitInit from 'canvaskit-wasm';

async function main() {
  const CanvasKit = await CanvasKitInit({
    locateFile: (file: string) => `/node_modules/canvaskit-wasm/bin/${file}`,
  });

  const canvasElement = document.getElementById('skia-canvas') as HTMLCanvasElement;
  if (!canvasElement) {
    throw new Error('[DocsHost] Canvas element not found');
  }

  // Resize canvas to viewport
  function resize() {
    const dpr = window.devicePixelRatio || 1;
    const w = window.innerWidth;
    const h = window.innerHeight;
    canvasElement.width = w * dpr;
    canvasElement.height = h * dpr;
    canvasElement.style.width = `${w}px`;
    canvasElement.style.height = `${h}px`;
  }
  resize();
  window.addEventListener('resize', resize);

  const surface = CanvasKit.MakeWebGLCanvasSurface(canvasElement);
  if (!surface) {
    throw new Error('[DocsHost] Failed to create CanvasKit surface');
  }

  // Load the WASM module and connect to JavaScriptKit runtime
  await loadWasm();

  console.log('[DocsHost] SkiaUI Docs ready');
}

async function loadWasm() {
  try {
    const response = await fetch('/SkiaUIDocsSite.wasm');
    if (!response.ok) {
      console.warn('[DocsHost] WASM module not available — running in static mode');
      return;
    }
    const wasmBytes = await response.arrayBuffer();
    const { instance } = await WebAssembly.instantiate(wasmBytes, {
      // JavaScriptKit runtime imports would be configured here
      // when building with SwiftWasm + JavaScriptKit
    });
    console.log('[DocsHost] WASM module loaded', instance);
  } catch (err) {
    console.warn('[DocsHost] WASM loading failed, running in preview mode:', err);
  }
}

main().catch(console.error);
