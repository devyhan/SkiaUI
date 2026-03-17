export type ClickHandler = (x: number, y: number) => void;
export type LongPressHandler = (x: number, y: number) => void;
export type DragHandler = (phase: 'changed' | 'ended', startX: number, startY: number, currentX: number, currentY: number) => void;

const LONG_PRESS_DURATION = 500; // ms
const LONG_PRESS_TOLERANCE = 10; // px movement tolerance

export class EventBridge {
  private canvas: HTMLCanvasElement;
  private clickHandler: ClickHandler | null = null;
  private longPressHandler: LongPressHandler | null = null;
  private dragHandler: DragHandler | null = null;

  // Long press state
  private longPressTimer: ReturnType<typeof setTimeout> | null = null;
  private pointerStartX = 0;
  private pointerStartY = 0;
  private longPressFired = false;

  // Drag state
  private isDragging = false;
  private dragStartX = 0;
  private dragStartY = 0;

  constructor(canvasId: string) {
    this.canvas = document.getElementById(canvasId) as HTMLCanvasElement;
    this.canvas.addEventListener('click', this.handleClick.bind(this));
    this.canvas.addEventListener('pointerdown', this.handlePointerDown.bind(this));
    this.canvas.addEventListener('pointermove', this.handlePointerMove.bind(this));
    this.canvas.addEventListener('pointerup', this.handlePointerUp.bind(this));
    this.canvas.addEventListener('pointercancel', this.handlePointerCancel.bind(this));
  }

  setClickHandler(handler: ClickHandler): void {
    this.clickHandler = handler;
  }

  setLongPressHandler(handler: LongPressHandler): void {
    this.longPressHandler = handler;
  }

  setDragHandler(handler: DragHandler): void {
    this.dragHandler = handler;
  }

  private handleClick(event: MouseEvent): void {
    // Don't fire click if a long press or drag just happened
    if (this.longPressFired || this.isDragging) {
      this.longPressFired = false;
      return;
    }
    const rect = this.canvas.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;
    this.clickHandler?.(x, y);
  }

  private handlePointerDown(event: PointerEvent): void {
    const rect = this.canvas.getBoundingClientRect();
    this.pointerStartX = event.clientX - rect.left;
    this.pointerStartY = event.clientY - rect.top;
    this.longPressFired = false;
    this.isDragging = false;
    this.dragStartX = this.pointerStartX;
    this.dragStartY = this.pointerStartY;

    // Start long press timer
    this.longPressTimer = setTimeout(() => {
      this.longPressFired = true;
      this.longPressHandler?.(this.pointerStartX, this.pointerStartY);
    }, LONG_PRESS_DURATION);

    this.canvas.setPointerCapture(event.pointerId);
  }

  private handlePointerMove(event: PointerEvent): void {
    const rect = this.canvas.getBoundingClientRect();
    const currentX = event.clientX - rect.left;
    const currentY = event.clientY - rect.top;

    const dx = currentX - this.pointerStartX;
    const dy = currentY - this.pointerStartY;
    const distance = Math.sqrt(dx * dx + dy * dy);

    // Cancel long press if moved too far
    if (distance > LONG_PRESS_TOLERANCE && this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = null;
    }

    // Start drag if moved beyond tolerance
    if (distance > LONG_PRESS_TOLERANCE && !this.longPressFired) {
      this.isDragging = true;
      this.dragHandler?.('changed', this.dragStartX, this.dragStartY, currentX, currentY);
    }
  }

  private handlePointerUp(event: PointerEvent): void {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = null;
    }

    if (this.isDragging) {
      const rect = this.canvas.getBoundingClientRect();
      const currentX = event.clientX - rect.left;
      const currentY = event.clientY - rect.top;
      this.dragHandler?.('ended', this.dragStartX, this.dragStartY, currentX, currentY);
      this.isDragging = false;
    }
  }

  private handlePointerCancel(_event: PointerEvent): void {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = null;
    }
    this.isDragging = false;
    this.longPressFired = false;
  }

  dispose(): void {
    this.canvas.removeEventListener('click', this.handleClick);
    this.canvas.removeEventListener('pointerdown', this.handlePointerDown);
    this.canvas.removeEventListener('pointermove', this.handlePointerMove);
    this.canvas.removeEventListener('pointerup', this.handlePointerUp);
    this.canvas.removeEventListener('pointercancel', this.handlePointerCancel);
  }
}
