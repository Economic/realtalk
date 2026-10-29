# realtalk: Price index data for the US economy

Makes it easy to use US price index data like the CPI.

## Checking for updates

When you load realtalk with
[`library(realtalk)`](https://economic.github.io/realtalk/) in an
interactive session, it checks whether its data is two or more months
behind. If so, and r-universe has a newer version, it says so and shows
how to update. It checks at most once a day, recording the date in
`tools::R_user_dir("realtalk", "cache")`. It says nothing otherwise, and
never runs in non-interactive sessions or in renv projects, which pin
package versions on purpose. Turn it off with
`options(realtalk.update_check = FALSE)`.

## See also

Useful links:

- <https://economic.github.io/realtalk/>

- <https://github.com/economic/realtalk>

- Report bugs at <https://github.com/economic/realtalk/issues>

## Author

**Maintainer**: Ben Zipperer <bzipperer@epi.org>

Authors:

- Ben Zipperer <bzipperer@epi.org>

Other contributors:

- Economic Policy Institute \[copyright holder, funder\]
