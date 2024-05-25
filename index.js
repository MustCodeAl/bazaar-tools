#!/usr/bin/env node

const { Command } = require('commander');
// const inquirer = require('inquirer');
const fs = require('fs-extra');
const path = require('path');

const program = new Command();
program.version('1.0.0');

// Define CLI commands and options
program
    .command('setup')
    .description('Setup Bazaar template by selecting necessary components and pages')
    .action(() => {
        runSetup();
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
    "grocery-4": {
        layout: "grocery-4"
    },
    "grocery-2": {
        layout: "(layout-2)"
    },
    "grocery-3": {
        layout: "(layout-1)"
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

async function runSetup() {
    const inquirer = await import('inquirer');

    const answers = await inquirer.default.prompt([
        {
            type: 'list',
            name: 'homepages',
            message: 'Select the home page you need:',
            choices: Object.keys(homepages),
        },
        {
            type: 'checkbox',
            name: 'components',
            message: 'Select the components you need:',
            choices: [
                'Header',
                'Footer',
                'Product List',
                'Product Detail',
                'Shopping Cart',
            ],
        },
    ]);
    console.log(answers)

    customizeTemplate(answers.homepages, answers.components);
}
async function customizeTemplate(selectedHomePage, components) {
    const templateDir = path.join(__dirname, '../bazaar-next');
    const outputDir = path.join(__dirname, 'bazaar-starter');

    // Copy the template to a new directory
    await fs.copy(templateDir, outputDir, {
        filter: (src, dest) => {
            // Exclude node_modules directory
            if (src.includes('node_modules')) {
                return false;
            }
            return true;
        }
    });

    // // List of all possible pages and components
    // const allPages = ['Homepage', 'Product Page', 'Cart Page', 'Checkout Page', 'Profile Page'];
    // const allComponents = ['Header', 'Footer', 'Product List', 'Product Detail', 'Shopping Cart'];
    const allHomePageNames = [...Object.keys(homepages), 'landing'];

    // Remove unused homepages
    for (const page of allHomePageNames) {
        if (selectedHomePage !== page) {
            const pagePath = path.join(outputDir, `src/pages-sections/${page}`);
            await fs.remove(pagePath);
        }
    }

    // remove unused homepage layouts
    for (const [key, value] of Object.entries(homepages)) {
        if(selectedHomePage !== key) {
            // remove unused layouts
            let layoutPath;
            // if layout name is like (layout-1)
            if(/^\(.*\)$/.test(value.layout)) {
                layoutPath = path.join(outputDir, `src/app/${value.layout}/${key}`);
            } else {
                layoutPath = path.join(outputDir, `src/app/${value.layout}`);
            }
            await fs.remove(layoutPath);
        } else {
            // set root layout
            if(/^\(.*\)$/.test(value.layout)) {
                await fs.move(path.join(outputDir, `src/app/${value.layout}/${key}/page.tsx`), path.join(outputDir, `src/app/${value.layout}/page.tsx`));
                await fs.remove(path.join(outputDir, `src/app/${value.layout}/${key}`));
            } else {
                await fs.rename(path.join(outputDir, `src/app/${value.layout}`), path.join(outputDir, `src/app/(${value.layout})`))
            }
        }
    }

    // make selected homepage root page
    fs.remove(path.join(outputDir, 'src/app/page.tsx'))
    // fs.remove(path.join(outputDir, 'src/app/page.jsx'))


    console.log('Template customization complete.');
}


