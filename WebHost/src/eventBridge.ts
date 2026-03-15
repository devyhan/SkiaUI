export type ClickHandler = (x: number, y: number) => void;

export class EventBridge {
  private canvas: HTMLCanvasElement;
  private clickHandler: ClickHandler | null = null;

  constructor(canvasId: string) {
    this.canvas = document.getElementById(canvasId) as HTMLCanvasElement;
    this.canvas.addEventListener('click', this.handleClick.bind(this));
    this.canvas.addEventListener('pointerdown', this.handlePointerDown.bind(this));
  }

  setClickHandler(handler: ClickHandler): void {
    this.clickHandler = handler;
  }

  private handleClick(event: MouseEvent): void {
    const rect = this.canvas.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;
    this.clickHandler?.(x, y);
  }

  private handlePointerDown(event: PointerEvent): void {
    // Future: handle drag/gesture
  }

  dispose(): void {
    this.canvas.removeEventListener('click', this.handleClick);
  }
}
