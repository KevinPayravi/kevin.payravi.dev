# kevin.payravi.dev

Personal website for Kevin Payravi, with a simple templating system run through Bash.

## Structure

```
src/            Source HTML files
templates/      Reusable components (head, nav, footer)
build.sh        Build script
```

## Building

```bash
./build.sh
cd build && python3 -m http.server 8000
```

## Templates

Use `data-template` attributes in your HTML:

```html
<div data-template="head"></div>
<nav data-template="nav"></nav>
<footer data-template="footer"></footer>
```

Template files support variables like `{{BASE_PATH}}`, `{{CSS_PATH}}`, and `{{HOME_ACTIVE}}` for navigation states.

## Deployment

Push to `main` and GitHub Actions deploys to the `deploy` branch automatically.

## License

MIT
