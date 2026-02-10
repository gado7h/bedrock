# Graphical App Development on Bedrock

Bedrock provides a hardware-accelerated Graphics Abstraction Layer (HAL) that allows userspace applications to render high-performance 2D graphics.

## Concepts

### Indexed Color System
Bedrock uses a **16-color palette** (CGA-inspired). Instead of writing RGBA values directly, you write a single byte (0-15) representing an index in the system palette to the Video RAM (VRAM).

### High-Performance Rendering
To avoid the overhead of manipulating pixels one by one in Luau, the kernel provides hardware-accelerated primitives:
1.  **Rect Fill**: Rapidly filling areas with color.
2.  **BitBlt (Block Transfer)**: Copying regions of memory (e.g., icons, window content).
3.  **Dirty Rectangles**: Only updating and flushing the parts of the screen that changed.

---

## Syscall Reference

### `GPU_INFO` -> `(width, height)`
Returns the current display resolution configured during `Kernel.Init`.

### `GPU_RECT(x, y, w, h, colorIndex)`
Fills a rectangle at `(x, y)` with dimensions `(w, h)` using the specified palette color.

### `GPU_BLIT(dx, dy, sx, sy, w, h)`
Copies a block of pixels from the source `(sx, sy)` to the destination `(dx, dy)`. Useful for:
-   Moving windows without re-rendering content.
-   Drawing sprites/icons from a "tilesheet" stored in a specific VRAM region.

### `GPU_FLUSH(x, y, w, h)`
Commit the changes in VRAM to the actual Roblox screen.
-   **Full Flush**: Calling without arguments flushes the entire screen (expensive).
-   **Partial Flush**: Passing coordinates flushes only that region (recommended).

---

## "Hello World" App Example

This example draws a simple window with a title bar to the screen.

```luau
local Syscall = require(Kernel.Core.Syscalls).Call

-- 1. Get screen info
local width, height = Syscall("GPU_INFO")

-- 2. Draw a window background (Light Gray: 7)
Syscall("GPU_RECT", 50, 50, 300, 200, 7)

-- 3. Draw a title bar (Low Blue: 1)
Syscall("GPU_RECT", 50, 50, 300, 20, 1)

-- 4. Flush the changes to the screen
Syscall("GPU_FLUSH", 50, 50, 300, 200)

print("UI Rendered!")
```

## Handling Input
To make an app interactive, use `POLL_EVENTS` to listen for mouse and keyboard interrupts.

```luau
while true do
    local events = Syscall("POLL_EVENTS")
    for _, event in ipairs(events) do
        if event.Type == "MouseButton1" then
            print("Click at:", event.X, event.Y)
        end
    end
    Syscall("SLEEP", 16) -- ~60 FPS polling
end
```

## Performance Tips
-   **Batch your Flushes**: Perform all drawing calls for a frame, calculate the bounding box of the changes, and call `GPU_FLUSH` once.
-   **Direct Memory Access**: For extremely complex rendering, use `GET_VRAM_PTR` to get the raw buffer, though this is slower than hardware primitives for fills/copies.
