import type { CanvasKit, Surface } from "canvaskit-wasm";
import { DisplayListPlayer } from "./displayListPlayer";
import { FontManager } from "./fontManager";
import { ImageCache } from "./imageCache";

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

  const imageCache = new ImageCache(CanvasKit);
  const player = new DisplayListPlayer(CanvasKit, fontManager, imageCache);
  let currentBuffer: ArrayBuffer | null = null;

  // Sync viewport with Swift server and get display list
  async function syncViewport(): Promise<void> {
    for (let attempt = 0; attempt < 5; attempt++) {
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
          return;
        }
      } catch {
        // Server might not be ready yet
      }
      await new Promise((r) => setTimeout(r, 300 * (attempt + 1)));
    }
    // Final fallback
    if (!currentBuffer) {
      const res = await fetch("/displaylist.bin");
      currentBuffer = await res.arrayBuffer();
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

  // Long press handler
  let longPressTimer: ReturnType<typeof setTimeout> | null = null;
  let pointerStartX = 0;
  let pointerStartY = 0;
  let longPressFired = false;
  let isDragging = false;

  canvasElement.addEventListener("pointerdown", (event: PointerEvent) => {
    pointerStartX = event.clientX;
    pointerStartY = event.clientY;
    longPressFired = false;
    isDragging = false;

    longPressTimer = setTimeout(async () => {
      longPressFired = true;
      try {
        const res = await fetch("/api/longpress", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            x: pointerStartX,
            y: pointerStartY,
            viewportWidth: window.innerWidth,
            viewportHeight: window.innerHeight,
          }),
        });
        if (res.ok) {
          currentBuffer = await res.arrayBuffer();
        }
      } catch {}
    }, 500);

    canvasElement.setPointerCapture(event.pointerId);
  });

  canvasElement.addEventListener("pointermove", async (event: PointerEvent) => {
    const dx = event.clientX - pointerStartX;
    const dy = event.clientY - pointerStartY;
    const distance = Math.sqrt(dx * dx + dy * dy);

    if (distance > 10 && longPressTimer) {
      clearTimeout(longPressTimer);
      longPressTimer = null;
    }

    if (distance > 10 && !longPressFired) {
      isDragging = true;
      try {
        const res = await fetch("/api/drag", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            phase: "changed",
            startX: pointerStartX,
            startY: pointerStartY,
            currentX: event.clientX,
            currentY: event.clientY,
            viewportWidth: window.innerWidth,
            viewportHeight: window.innerHeight,
          }),
        });
        if (res.ok) {
          currentBuffer = await res.arrayBuffer();
        }
      } catch {}
    }
  });

  canvasElement.addEventListener("pointerup", async (event: PointerEvent) => {
    if (longPressTimer) {
      clearTimeout(longPressTimer);
      longPressTimer = null;
    }

    if (isDragging) {
      try {
        const res = await fetch("/api/drag", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            phase: "ended",
            startX: pointerStartX,
            startY: pointerStartY,
            currentX: event.clientX,
            currentY: event.clientY,
            viewportWidth: window.innerWidth,
            viewportHeight: window.innerHeight,
          }),
        });
        if (res.ok) {
          currentBuffer = await res.arrayBuffer();
        }
      } catch {}
      isDragging = false;
    }
  });

  canvasElement.addEventListener("pointercancel", () => {
    if (longPressTimer) {
      clearTimeout(longPressTimer);
      longPressTimer = null;
    }
    isDragging = false;
    longPressFired = false;
  });
}
