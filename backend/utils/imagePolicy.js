const path = require("path");
function imageContent(buffer, filename) {
  const ext = path.extname(filename).toLowerCase();
  if ([".jpg", ".jpeg"].includes(ext))
    return (
      buffer.length > 4 &&
      buffer[0] === 255 &&
      buffer[1] === 216 &&
      buffer[2] === 255
    );
  if (ext === ".png")
    return (
      buffer.length >= 24 &&
      buffer
        .subarray(0, 8)
        .equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])) &&
      buffer.toString("ascii", 12, 16) === "IHDR"
    );
  if (ext === ".gif")
    return (
      buffer.length >= 13 &&
      ["GIF87a", "GIF89a"].includes(buffer.toString("ascii", 0, 6))
    );
  if (ext === ".webp")
    return (
      buffer.length >= 20 &&
      buffer.toString("ascii", 0, 4) === "RIFF" &&
      buffer.toString("ascii", 8, 12) === "WEBP"
    );
  if ([".heic", ".heif"].includes(ext))
    return (
      buffer.length >= 24 &&
      buffer.toString("ascii", 4, 8) === "ftyp" &&
      /heic|heix|hevc|hevx|mif1|msf1/.test(buffer.toString("ascii", 8, 24))
    );
  return false;
}
function uploadFolder(user, requested) {
  const folder = ["merchants", "promotions", "images", "profiles"].includes(
    requested,
  )
    ? requested
    : "images";
  return `u${String(user.id).replace(/[^a-zA-Z0-9]/g, "")}-${folder}`;
}
function canDelete(user, url) {
  if (user?.role === "admin") return true;
  // Generated URLs never contain these; providers derive keys from the raw string, so the parsed
  // (normalised) path checked below must be the path that gets deleted.
  if (typeof url !== "string" || /%|\.\.|\\|[?#]/.test(url)) return false;
  try {
    const parsed = new URL(url);
    if(!['http:','https:'].includes(parsed.protocol) || parsed.username || parsed.password) return false;
    const parts = parsed.pathname.split('/').filter(Boolean);
    const folders = new Set(['merchants','promotions','images','profiles'].map(folder=>`u${user.id}-${folder}`));
    // The namespace must be the immediate parent of a generated filename.
    return parts.length >= 2 && folders.has(parts[parts.length-2]) &&
      /^[a-f0-9-]+\.(jpg|jpeg|png|gif|webp|heic|heif)$/i.test(parts[parts.length-1]);
  } catch {
    return false;
  }
}
module.exports = { imageContent, uploadFolder, canDelete };
