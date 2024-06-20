const fs = require('fs-extra');
const path = require('path');

async function mergeDirectories(src, dest) {
    const entries = await fs.readdir(src, { withFileTypes: true });

    for (let entry of entries) {
        const srcPath = path.join(src, entry.name);
        const destPath = path.join(dest, entry.name);

        if (entry.isDirectory()) {
            await fs.ensureDir(destPath);
            await mergeDirectories(srcPath, destPath);
        } else {
            await fs.move(srcPath, destPath, { overwrite: true });
        }
    }

    await fs.remove(src);
}

module.exports = {
    mergeDirectories,
}