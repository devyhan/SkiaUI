import CanvasKitInit from "canvaskit-wasm";
import { start } from "./canvaskitHost";

export async function bootstrap(): Promise<void> {
  console.log("[SkiaUI] Initializing CanvasKit...");

  const CanvasKit = await CanvasKitInit({
    locateFile: () => "/canvaskit.wasm",
  });

  console.log("[SkiaUI] CanvasKit initialized.");
  await start(CanvasKit);
}
