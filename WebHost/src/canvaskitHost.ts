import type { CanvasKit, Surface } from "canvaskit-wasm";
import { DisplayListPlayer } from "./displayListPlayer";
import { FontManager } from "./fontManager";

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

  // Load fonts via FontManager
  const fontManager = new FontManager(CanvasKit);
  await fontManager.loadFont("/Roboto-Regular.ttf", "Roboto");
  await Promise.all([
    fontManager.loadFont("/MonaspaceNeon-Regular.otf", "Monaspace Neon"),
    fontManager.loadFont("/MonaspaceNeon-Bold.otf", "Monaspace Neon Bold"),
    fontManager.loadFont("/MonaspaceArgon-Regular.otf", "Monaspace Argon"),
    fontManager.loadFont("/MonaspaceXenon-Regular.otf", "Monaspace Xenon"),
    fontManager.loadFont("/MonaspaceRadon-Regular.otf", "Monaspace Radon"),
    fontManager.loadFont("/MonaspaceKrypton-Regular.otf", "Monaspace Krypton"),
  ]);

  const player = new DisplayListPlayer(CanvasKit, fontManager);
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

  // Scroll (wheel) handler
  let scrollPending = false;
  canvasElement.addEventListener(
    "wheel",
    async (event: WheelEvent) => {
      event.preventDefault();
      if (scrollPending) return;
      scrollPending = true;
      try {
        const res = await fetch("/api/scroll", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            x: event.clientX,
            y: event.clientY,
            deltaX: event.deltaX,
            deltaY: event.deltaY,
            viewportWidth: window.innerWidth,
            viewportHeight: window.innerHeight,
          }),
        });
        if (res.ok) {
          currentBuffer = await res.arrayBuffer();
        }
      } catch {}
      scrollPending = false;
    },
    { passive: false }
  );

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
