# Bazaar Tools
Build your starter template from [Bazaar Next.js ecommerce template](https://bazaar.ui-lib.com/)

Run this in your terminal
`bazaar set-root`
Then select a homepage

Added a brand new homepage script to.
To get started
make sure to `chmod +x bazaar.sh`

then run `/bazaar.sh set-root --select <homepage_desired_goes_here>`


for fashionshop 3 do `/bazaar.sh set-root --select fashion-1`

these scripts will not work unless folder structure is exactly like in structure.txt.


Above command will set your selected shop page as your root page. Also this will delete other unused layouts from `app` folder and page components from `page-sections` folders.
If you want to keep section components in `page-sections` folders use this command `bazaar set-root --keep-components`
