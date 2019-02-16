# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
declared_trivial = github.pr_title.include? "#trivial"
has_pod_changes = !git.modified_files.grep(/^Cauli\//).empty?

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]" or  github.pr_title.include? "WIP:"

has_changelog_updates = git.modified_files.include?("CHANGELOG.md")
if has_pod_changes && !has_changelog_updates && !declared_trivial
  fail("Please include a CHANGELOG entry to credit yourself! \nYou can find it at /CHANGELOG.md.", :sticky => false)
  markdown <<-MARKDOWN
### Example CHANGELOG entry

```markdown
* **feature/improvement/bugfix** #{github.pr_title}\s\s
  [#issue_number](https://github.com/cauliframework/cauli/issues/issue_number) by @#{github.pr_author}  
```

  MARKDOWN

  markdown <<-MARKDOWN
### Trivial PR?

If you think you PR is trivial and neither a CHANGELOG entry nor a README update is necessary, you can add a `#trivial` to your PR title. The bot will pick that up and will not warn about a missing CHANGELOG or README entry.
  MARKDOWN
end

has_readme_updates = git.modified_files.include?("README.md")
if has_pod_changes && !has_readme_updates && !declared_trivial
  warn("Are there any changes that should be explained in the `README.md`?")
end

# Perform swiftlint and comment violations inline
swiftlint.config_file = '.swiftlint.yml'
swiftlint.verbose = true
swiftlint.lint_files inline_mode: true