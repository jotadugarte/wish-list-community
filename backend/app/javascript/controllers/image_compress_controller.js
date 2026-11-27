import { Controller } from "@hotwired/stimulus"

// Client-side best-effort compress toward ≤1600px / ≤2MB before multipart (O5A).
// Traceability: [REQ-ITEM-002]
// Server libvips remains mandatory.
export default class extends Controller {
  static targets = ["input"]

  async compress(event) {
    const input = event.target
    if (!input.files || input.files.length === 0) return

    const maxSide = 1600
    const maxBytes = 2 * 1024 * 1024
    const dt = new DataTransfer()
    const files = Array.from(input.files).slice(0, 3)

    for (const file of files) {
      try {
        const compressed = await this.#resizeFile(file, maxSide, maxBytes)
        dt.items.add(compressed)
      } catch (_err) {
        dt.items.add(file)
      }
    }

    input.files = dt.files
  }

  async #resizeFile(file, maxSide, maxBytes) {
    if (!file.type.startsWith("image/")) return file

    const bitmap = await createImageBitmap(file)
    const scale = Math.min(1, maxSide / Math.max(bitmap.width, bitmap.height))
    const width = Math.max(1, Math.round(bitmap.width * scale))
    const height = Math.max(1, Math.round(bitmap.height * scale))
    const canvas = document.createElement("canvas")
    canvas.width = width
    canvas.height = height
    const ctx = canvas.getContext("2d")
    ctx.drawImage(bitmap, 0, 0, width, height)
    bitmap.close()

    let quality = 0.85
    let blob = await this.#toBlob(canvas, quality)
    let guard = 0
    while (blob && blob.size > maxBytes && quality > 0.4 && guard < 5) {
      quality -= 0.1
      blob = await this.#toBlob(canvas, quality)
      guard += 1
    }

    if (!blob) return file
    return new File([blob], file.name.replace(/\.\w+$/, ".jpg"), { type: "image/jpeg" })
  }

  #toBlob(canvas, quality) {
    return new Promise((resolve) => canvas.toBlob(resolve, "image/jpeg", quality))
  }
}
