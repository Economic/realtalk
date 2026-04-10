## R package development

### General guidance

- Use base pipe `|>` instead of `%>%`
- Use the `cli` package for messages and error text

### Workflows

To run code from the package, `Rscript -e "devtools::load_all(); code"`.

After any changes to the package:
- Run all tests: `Rscript -e "devtools::test()"`
- Re-document: `Rscript -e "devtools::document()"`
- Check pkgdown: `Rscript -e "pkgdown::check_pkgdown()"`
- Use R CMD Check: `Rscript -e "devtools::check()"`

### Documentation

- Export and document with roxygen2 all user-facing functions.
- Add new documentation topics to `_pkgdown.yml` 
- Tersely document any user-facing change in `NEWS.md`.

### Testing

- Any new functionality should have a test.
- Use descriptive test names that state what is being tested and the expected outcome.
- Group related tests together within a file.
- Validation tests should verify both the success case and the error message for invalid input.
- Tests for `R/{name}.R` go in `tests/testthat/test-{name}.R`.
