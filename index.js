#!/usr/bin/env node

const { Command } = require('commander');
const fs = require('fs-extra');
const path = require('path');

const program = new Command();
program.version('1.0.3', '-V, --version', 'output the version number');
// Alias -v to --version
program.option('-v', 'output the version number', () => {
    console.log(program.version());
});

// CLI commands and options
program
    .command('set-root')
    .description('Setup Bazaar template by selecting necessary components and pages')
    .option('--keep-components', 'Keep components in pages-sections')
    .action((options) => {
        runSetup(options.keepComponents);
    });

program.parse(process.argv);

const homepages = {
    "fashion-1": {
        layout: "(layout-1)"
    },
    "fashion-2": {
        layout: "(layout-1)"
    },
    "fashion-3": {
        layout: "(layout-3)"
    },
    "furniture-1": {
        layout: "(layout-1)"
    },
    "furniture-2": {
        layout: "(layout-3)"
    },
    "furniture-3": {
        layout: "furniture-3"
    },
    "gift-shop": {
        layout: "(layout-3)"
    },
    "gadget-1": {
        layout: "(layout-1)"
    },
    "gadget-2": {
        layout: "(layout-3)"
    },
    "gadget-3": {
        layout: "gadget-3"
    },
    "grocery-1": {
        layout: "(layout-3)"
    },
    "grocery-2": {
        layout: "(layout-2)"
    },
    "grocery-3": {
        layout: "(layout-1)"
    },
    "grocery-4": {
        layout: "grocery-4"
    },
    "health-beauty": {
        layout: "(layout-2)"
    },
    "market-1": {
        layout: "(layout-1)"
    },
    "market-2": {
        layout: "(layout-1)"
    },
    "medical": {
        layout: "(layout-3)"
    },
}
function getFileExtension(outputDir) {
    if (fs.existsSync(path.join(outputDir, 'src/app/layout.tsx'))) {
        return 'tsx';
    } else {
        return 'jsx';
    }
}
let fileExt;

async function runSetup(keepComponents) {
    const inquirer = await import('inquirer');

    const answers = await inquirer.default.prompt([
        {
            type: 'list',
            name: 'homepages',
            message: 'Set root page:',
            choices: Object.keys(homepages),
        }
    ]);
    customizeTemplate(answers.homepages, keepComponents);
}

async function customizeTemplate(selectedHomePage, keepComponents) {
    const templateDir = path.join(process.cwd(), './');
    const outputDir = templateDir;

    fileExt = getFileExtension(templateDir);

    const allHomePageNames = [...Object.keys(homepages), 'landing'];

    console.log('--keep-components--', keepComponents)
    // Remove unused homepages
    if (!keepComponents) {
        for (const page of allHomePageNames) {
            if (selectedHomePage !== page) {
                const pagePath = path.join(outputDir, `src/pages-sections/${page}`);
                await fs.remove(pagePath);
            }
        }
    }

    // remove unused homepage layouts
    for (const [key, value] of Object.entries(homepages)) {
        if (selectedHomePage !== key) {
            // remove unused layouts
            let layoutPath;
            // if layout name is like (layout-1)
            if (/^\(.*\)$/.test(value.layout)) {
                layoutPath = path.join(outputDir, `src/app/${value.layout}/${key}`);
            } else {
                layoutPath = path.join(outputDir, `src/app/${value.layout}`);
            }
            await fs.remove(layoutPath);
        }
        else {
            // set root layout
            if (/^\(.*\)$/.test(value.layout)) {
                await fs.move(path.join(outputDir, `src/app/${value.layout}/${key}/page.${fileExt}`), path.join(outputDir, `src/app/${value.layout}/page.${fileExt}`));
                await fs.remove(path.join(outputDir, `src/app/${value.layout}/${key}`));
            } else {
                await fs.rename(path.join(outputDir, `src/app/${value.layout}`), path.join(outputDir, `src/app/(${value.layout})`))
            }
        }
    }

    // make selected homepage root page
    fs.remove(path.join(outputDir, `src/app/page.${fileExt}`))


    console.log(`${selectedHomePage} has been set as root page.`);
}


