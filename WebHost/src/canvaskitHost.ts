import type { CanvasKit, Surface } from "canvaskit-wasm";
import { DisplayListPlayer } from "./displayListPlayer";

export async function start(CanvasKit: CanvasKit): Promise<void> {
  const canvasElement = document.getElementById(
    "skia-canvas"
  ) as HTMLCanvasElement | null;

  if (!canvasElement) {
    throw new Error('[SkiaUI] Canvas element with id "skia-canvas" not found.');
  }

  function resizeCanvas() {
    const dpr = window.devicePixelRatio || 1;
    const w = window.innerWidth;
    const h = window.innerHeight;
    canvasElement!.width = w * dpr;
    canvasElement!.height = h * dpr;
    canvasElement!.style.width = w + "px";
    canvasElement!.style.height = h + "px";
  }
  resizeCanvas();

  let surface: Surface | null =
    CanvasKit.MakeWebGLCanvasSurface(canvasElement);

  if (!surface) {
    throw new Error("[SkiaUI] Failed to create CanvasKit surface.");
  }

  // Load font
  const fontData = await fetch("/Roboto-Regular.ttf").then((r) =>
    r.arrayBuffer()
  );
  let typeface = null;
  try {
    typeface = CanvasKit.Typeface.MakeFreeTypeFaceFromData(fontData);
  } catch {}
  if (!typeface) {
    try {
      typeface = CanvasKit.FontMgr.RefDefault().MakeTypefaceFromData(fontData);
    } catch {}
  }

  const player = new DisplayListPlayer(CanvasKit, typeface);
  let currentBuffer: ArrayBuffer | null = null;

  // Sync viewport with Swift server and get display list
  async function syncViewport(): Promise<void> {
    try {
      const res = await fetch("/api/viewport", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          width: window.innerWidth,
          height: window.innerHeight,
        }),
      });
      if (res.ok) {
        currentBuffer = await res.arrayBuffer();
      }
    } catch {
      // Fallback to static file
      if (!currentBuffer) {
        const res = await fetch("/displaylist.bin");
        currentBuffer = await res.arrayBuffer();
      }
    }
  }

  // Initial sync
  await syncViewport();

  // Render loop
  function renderLoop(): void {
    if (!surface) return;
    surface.requestAnimationFrame((canvas) => {
      const dpr = window.devicePixelRatio || 1;
      canvas.clear(CanvasKit.WHITE);
      canvas.save();
      canvas.scale(dpr, dpr);
      if (currentBuffer) {
        player.play(currentBuffer, canvas);
      }
      canvas.restore();
      renderLoop();
    });
  }
  renderLoop();

  // Resize handler
  window.addEventListener("resize", async () => {
    resizeCanvas();
    surface?.delete();
    surface = CanvasKit.MakeWebGLCanvasSurface(canvasElement!);
    await syncViewport();
    if (surface) renderLoop();
  });

  // Click handler
  canvasElement.addEventListener("click", async (event: MouseEvent) => {
    const x = event.clientX;
    const y = event.clientY;

    try {
      const res = await fetch("/api/tap", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          x,
          y,
          viewportWidth: window.innerWidth,
          viewportHeight: window.innerHeight,
        }),
      });
      if (res.ok) {
        currentBuffer = await res.arrayBuffer();
      }
    } catch {}
  });
}
